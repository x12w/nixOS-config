{
  plugins.neo-tree = {
    enable = true;

    settings = {
      enable_git_status = true;
      enable_diagnostics = true;
      close_if_last_window = true;
      sync_root_with_cwd = true;

      window = {
        width = 30;
        position = "left";

        mapping = {
          "v" = "openvsplit";
          "s" = "open_split";
          "t" = "open_tabnew";
        };
      };

      filesystem = {
        follow_current_file = {
          enabled = true;
        };
        filtered_items = {
          visible = true;
          hide_dotfiles = false;
        };
      };
    };
  };
}
