{ pkgs, ... }:

{
  extraPlugins = with pkgs.vimPlugins; [
    flatten-nvim
    nvim-surround
  ];

  extraConfigLua = ''
    -- flatten 配置
    require("flatten").setup({
      window = {
        -- "alternate" 表示在主编辑区打开，而不是在窄小的终端里
        open_strategy = "alternate",
      },
      hooks = {
        -- 这是一个高级技巧：写完 commit 自动跳回终端
        post_open = function(bufnr, winnr, ft, is_blocking)
          if is_blocking then
            vim.api.nvim_set_current_win(winnr)
          end
        end,
      }
    })

    require("nvim-surround").setup({})
  '';
}
