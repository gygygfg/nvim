return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require("lualine").setup {
      options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        }
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename', {
          require("nvim-navic").get_location,
          cond = function()
            return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
          end
        } },
        lualine_x = {
          require("action-hints").statusline,
          'encoding',
          'fileformat',
          'filetype',
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
      },
      tablabel = {},
      winbar = {
        lualine_c = { {
          require("nvim-navic").get_location,
          cond = function()
            return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
          end
        } }
      },
      inactive_winbar = {
        lualine_c = { 'filename' }
      },
    }

    -- 合并 MCPHub lualine 配置
    local mcphub_config = vim.g.mcphub_lualine
    if mcphub_config and mcphub_config.sections then
      local current_config = require("lualine").get_config()
      local merged_config = vim.tbl_deep_extend("force", current_config, mcphub_config)
      require("lualine").setup(merged_config)
    end
  end,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'SmiteshP/nvim-navic'
  },
  event = "VeryLazy",
}
