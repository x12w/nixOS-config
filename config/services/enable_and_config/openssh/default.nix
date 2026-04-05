{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true; # 启用密码登录
      PermitRootLogin = "no"; # 禁止 root 直接登录
    };
  };
}
