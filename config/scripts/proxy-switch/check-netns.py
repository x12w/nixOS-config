"""Integration check: run inside `unshare --user --map-root-user --net`.

Requires ip, nft and sing-box in PATH. No internet or real credentials needed.
"""

import errno
import importlib.util
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import threading
import time


host_namespace = os.environ.get("PROXY_SWITCH_HOST_NETNS")
assert host_namespace and os.readlink("/proc/self/ns/net") != host_namespace, "Refusing to modify the host network"
spec = importlib.util.spec_from_file_location("tests", Path(__file__).with_name("test_controller.py"))
tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tests)
controller = tests.controller
source = tests.fixture()
source["outbounds"][1]["settings"]["vnext"][0]["address"] = "203.0.113.10"
node = controller.node_from_xray(source)


def run(*args):
    return subprocess.run(args, text=True, capture_output=True, check=True).stdout


run("ip", "link", "set", "lo", "up")
run("ip", "link", "add", "uplink", "type", "dummy")
run("ip", "link", "set", "uplink", "up")
run("ip", "addr", "add", "192.0.2.2/24", "dev", "uplink")
run("ip", "route", "add", "default", "via", "192.0.2.1", "dev", "uplink")
run("ip", "-6", "addr", "add", "2001:db8::2/64", "dev", "uplink", "nodad")
run("ip", "-6", "route", "add", "default", "via", "2001:db8::1", "dev", "uplink")

with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp)
    (path / "config.json").write_text(json.dumps(controller.config_for(node)))
    (path / "guard.nft").write_text(controller.firewall_for(node))
    run("nft", "--check", "-f", str(path / "guard.nft"))
    run("nft", "-f", str(path / "guard.nft"))
    with open(path / "log", "w+") as log:
        proxy = subprocess.Popen(["sing-box", "run", "-c", str(path / "config.json")], stdout=log, stderr=log)
        try:
            for _ in range(40):
                if subprocess.run(["ip", "link", "show", controller.TUN], capture_output=True).returncode == 0:
                    break
                time.sleep(0.1)
            assert proxy.poll() is None
            for family, destination in [("-4", "1.1.1.1"), ("-6", "2606:4700:4700::1111")]:
                assert json.loads(run("ip", family, "-j", "route", "get", destination))[0]["dev"] == controller.TUN
            assert json.loads(run("ip", "-j", "route", "get", node["server"]))[0]["dev"] == "uplink"
            print("PASS: IPv4/IPv6 enter TUN; only the node uses the physical route")
        finally:
            proxy.terminate()
            proxy.wait(timeout=5)

    run("nft", "list", "table", "inet", controller.TABLE)
    def rejected_packets():
        ruleset = json.loads(run("nft", "-j", "list", "table", "inet", controller.TABLE))
        return sum(expression["counter"]["packets"] for item in ruleset["nftables"]
                   for expression in item.get("rule", {}).get("expr", []) if "counter" in expression)

    for family, destination in [(socket.AF_INET, "1.1.1.1"), (socket.AF_INET6, "2606:4700:4700::1111")]:
        before = rejected_packets()
        with socket.socket(family, socket.SOCK_STREAM) as client:
            client.settimeout(1)
            result = client.connect_ex((destination, 443))
            assert result in (errno.EACCES, errno.EPERM, errno.EHOSTUNREACH, errno.ENETUNREACH, errno.EAGAIN)
        assert rejected_packets() > before, "The independent guard must reject each IP family"
    print("PASS: both IP families fail closed after proxy exit")

    # The former LAN resolver and a public IPv6 resolver must both reach our
    # local stub, even with no TUN running. They must never hit the uplink.
    for family, local, destination in [(socket.AF_INET, "127.0.0.1", "192.168.8.31"),
                                       (socket.AF_INET6, "::1", "2001:4860:4860::8888")]:
        with socket.socket(family, socket.SOCK_DGRAM) as stub, socket.socket(family, socket.SOCK_DGRAM) as client:
            stub.settimeout(2)
            client.settimeout(2)
            stub.bind((local, 1053))
            received = []

            def answer():
                data, peer = stub.recvfrom(1024)
                received.append(data)
                stub.sendto(data, peer)

            worker = threading.Thread(target=answer)
            worker.start()
            client.sendto(b"dns-redirection-check", (destination, 53))
            data, _ = client.recvfrom(1024)
            worker.join(timeout=3)
            assert data == b"dns-redirection-check" and received == [data]
    print("PASS: IPv4 LAN DNS and IPv6 public DNS are redirected to localhost")
