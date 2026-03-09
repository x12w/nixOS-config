{
  xdg.desktopEntries = {
    "qq" = {
      name = "QQ";
      exec = "qq --ozone-platform-hint=auto --enable-wayland-ime --enable-features=WaylandWindowDecorations %U";
      icon = "qq"; 
      comment = "QQ-NT Client";
      categories = [ "Network" "Chat" "InstantMessaging" ];
      terminal = false;
      mimeType = [ "x-scheme-handler/mqqapi" ]; 
    };
  };
}
