-- lua/config/telescope.lua
-- Telescope 搜索和导航配置

local M = {}

function M.setup()
  require("telescope").setup({
    defaults = {
      mappings = {
        i = {
          ["<C-j>"] = require("telescope.actions").move_selection_next,
          ["<C-k>"] = require("telescope.actions").move_selection_previous,
          ["<esc>"] = require("telescope.actions").close,
        },
      },
    },
    pickers = {
      find_files = {
        theme = "dropdown",
      },
      live_grep = {
        theme = "dropdown",
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
  })

  -- 加载 fzf 扩展（如果已安装）
  local fzf_ok, _ = pcall(require("telescope").load_extension, "fzf")
  if fzf_ok then
    require("telescope").load_extension("fzf")
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- 设置快捷键
    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<leader>ff", function()
      M.setup()
      builtin.find_files()
    end, { desc = "查找文件" })

    vim.keymap.set("n", "<leader>fg", function()
      M.setup()
      builtin.live_grep()
    end, { desc = "实时搜索" })

    vim.keymap.set("n", "<leader>fb", function()
      M.setup()
      builtin.buffers()
    end, { desc = "缓冲区" })

    vim.keymap.set("n", "<leader>fh", function()
      M.setup()
      builtin.help_tags()
    end, { desc = "帮助标签" })
  end
})

return M
