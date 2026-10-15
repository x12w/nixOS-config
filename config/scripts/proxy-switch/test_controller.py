"""Run with python3 -m unittest discover -s config/scripts/proxy-switch."""

import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("controller", Path(__file__).with_name("controller.py"))
controller = importlib.util.module_from_spec(spec)
spec.loader.exec_module(controller)


def fixture():
    return {
        "routing": {"rules": [{"ruleTag": "default", "outboundTag": "chosen"}]},
        "outbounds": [
            {"tag": "dns", "protocol": "dns"},
            {"tag": "chosen", "protocol": "vless",
             "settings": {"vnext": [{"address": "node.example", "port": 443,
                                      "users": [{"id": "00000000-0000-0000-0000-000000000001",
                                                 "flow": "xtls-rprx-vision"}]}]},
             "streamSettings": {"network": "tcp", "security": "reality",
                                "realitySettings": {"serverName": "www.example.com",
                                                    "publicKey": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                                                    "shortId": "01234567", "fingerprint": "chrome"}}},
        ],
    }


class ProxyTests(unittest.TestCase):
    def setUp(self):
        self.resolver = patch.object(controller.socket, "getaddrinfo", return_value=[
            (2, 1, 6, "", ("203.0.113.10", 443))])
        self.resolver.start()
        self.addCleanup(self.resolver.stop)
        sockets = patch.object(controller.socket, "socket")
        sockets.start()
        self.addCleanup(sockets.stop)

    def test_selected_node_not_first_outbound(self):
        node = controller.node_from_xray(fixture())
        self.assertEqual(node["server"], "203.0.113.10")
        self.assertEqual(node["xray"]["settings"]["vnext"][0]["users"][0]["flow"], "xtls-rprx-vision")
        self.assertEqual(node["xray"]["streamSettings"]["sockopt"]["mark"], controller.MARK)
        config = controller.config_for(node)
        self.assertEqual(config["route"]["final"], "proxy")
        self.assertEqual(config["dns"]["servers"][0]["detour"], "proxy")
        self.assertEqual(len(config["inbounds"][0]["address"]), 2)
        self.assertIn("203.0.113.10/32", config["inbounds"][0]["route_exclude_address"])

    def test_reject_unsupported_and_ambiguous_nodes(self):
        for mutate in [
            lambda s: s["outbounds"][1].update(protocol="shadowsocks"),
            lambda s: s["outbounds"][1].update(proxySettings={"tag": "another"}),
            lambda s: s["routing"]["rules"].append({"ruleTag": "default", "outboundTag": "dns"}),
            lambda s: s["outbounds"][1]["streamSettings"].update(network="ws"),
        ]:
            source = fixture()
            mutate(source)
            with self.assertRaises(ValueError):
                controller.node_from_xray(source)

    def test_guard_covers_ipv6_dns_and_existing_sessions(self):
        rules = controller.firewall_for(controller.node_from_xray(fixture()))
        self.assertIn("table inet", rules)
        self.assertIn("th dport 53 redirect", rules)
        self.assertIn("meta mark 20563 ip daddr 203.0.113.10 tcp dport 443 accept", rules)
        self.assertNotIn("ct state", rules)
        self.assertTrue(rules.index("oifname \"proxy-global\"") < rules.index("counter reject"))

    def test_invalid_config_does_not_change_network(self):
        calls = []

        def run(*args, **kwargs):
            calls.append(args)
            if args[0] == "sing-box":
                raise RuntimeError("invalid config")
            return subprocess.CompletedProcess(args, 1 if args[0] == "ip" else 0, "loaded\n", "")

        with tempfile.TemporaryDirectory() as tmp, \
                patch.object(controller, "STATE", Path(tmp) / "state"), \
                patch.object(controller, "protected", return_value=False), \
                patch.object(controller, "active", return_value=True), \
                patch.object(controller, "run", side_effect=run):
            with self.assertRaisesRegex(RuntimeError, "invalid config"):
                controller.start("192.168.8.31", fixture())
            self.assertFalse(controller.STATE.exists())
        self.assertFalse(any(c[:2] == ("systemctl", "stop") for c in calls))
        self.assertFalse(any(c[0] == "nft" for c in calls))

    def test_failed_daed_restore_keeps_guard_and_state(self):
        calls = []

        def run(*args, **kwargs):
            calls.append(args)
            if args == ("systemctl", "start", "daed.service"):
                raise RuntimeError("restore failed")
            return subprocess.CompletedProcess(args, 0, "", "")

        with tempfile.TemporaryDirectory() as tmp, \
                patch.object(controller, "STATE", Path(tmp)), \
                patch.object(controller, "active", return_value=False), \
                patch.object(controller, "protected", return_value=True), \
                patch.object(controller, "run", side_effect=run):
            (controller.STATE / "state.json").write_text(json.dumps({"daed_active": True}))
            with self.assertRaises(RuntimeError):
                controller.stop()
            self.assertTrue((controller.STATE / "state.json").exists())
        self.assertFalse(any(c[:2] == ("nft", "delete") for c in calls))

    def test_failed_start_restores_original_state(self):
        network = {"guard": False, "daed": True}
        calls = []

        def run(*args, **kwargs):
            calls.append(args)
            if args[:2] == ("nft", "-f"):
                network["guard"] = True
            elif args[:2] == ("nft", "delete"):
                network["guard"] = False
            elif args == ("systemctl", "stop", "daed.service"):
                network["daed"] = False
            elif args == ("systemctl", "start", "daed.service"):
                network["daed"] = True
            elif args == ("systemctl", "start", controller.NODE_UNIT, controller.UNIT):
                raise RuntimeError("service failed")
            return subprocess.CompletedProcess(args, 1 if args[0] == "ip" else 0, "loaded\n", "")

        with tempfile.TemporaryDirectory() as tmp, \
                patch.object(controller, "STATE", Path(tmp) / "state"), \
                patch.object(controller, "protected", side_effect=lambda: network["guard"]), \
                patch.object(controller, "active", side_effect=lambda unit: unit == "daed.service" and network["daed"]), \
                patch.object(controller, "run", side_effect=run):
            with self.assertRaisesRegex(RuntimeError, "service failed"):
                controller.start("192.168.8.31", fixture())
            self.assertFalse(controller.STATE.exists())
        self.assertEqual(network, {"guard": False, "daed": True})
        self.assertIn(("systemctl", "stop", controller.UNIT, controller.NODE_UNIT), calls)

    def test_stop_restores_daed_only_if_previously_active(self):
        for was_active in [False, True]:
            calls = []
            with tempfile.TemporaryDirectory() as tmp, \
                    patch.object(controller, "STATE", Path(tmp) / "state"), \
                    patch.object(controller, "active", return_value=False), \
                    patch.object(controller, "protected", return_value=True), \
                    patch.object(controller, "run", side_effect=lambda *a, **kw: calls.append(a)):
                controller.STATE.mkdir()
                (controller.STATE / "state.json").write_text(json.dumps({"daed_active": was_active}))
                controller.stop()
                self.assertFalse(controller.STATE.exists())
            self.assertEqual(("systemctl", "start", "daed.service") in calls, was_active)
            self.assertIn(("nft", "delete", "table", "inet", controller.TABLE), calls)


if __name__ == "__main__":
    unittest.main()
