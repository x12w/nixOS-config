{
  plugins.oil = {
    enable = true;
    settings = {
      view_options.show_hidden = true;

      keymaps = {
        "C" = "actions.cd";
        "T" = "actions.tcd";
        "<CR>" = "actions.select";
      };
    };
  };
}
