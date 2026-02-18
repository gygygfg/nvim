return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
  },
  config = function()
    local telescope = require('telescope')
    local actions = require('telescope.actions')
    
    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
            ['<C-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
            ['<Esc>'] = actions.close,
          },
          n = {
            ['q'] = actions.close,
          },
        },
        layout_strategy = 'horizontal',
        layout_config = {
          horizontal = {
            preview_width = 0.6,
          },
        },
      },
      pickers = {
        find_files = {
          theme = 'dropdown',
          hidden = true,
        },
        live_grep = {
          theme = 'dropdown',
        },
        buffers = {
          theme = 'dropdown',
          previewer = false,
        },
        git_commits = {
          theme = 'dropdown',
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = 'smart_case',
        },
      },
    })
    
    -- 加载扩展
    telescope.load_extension('fzf')
    
    -- 设置快捷键
    local builtin = require('telescope.builtin')
    
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '查找文件' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '实时搜索' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '缓冲区' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '帮助标签' })
    vim.keymap.set('n', '<leader>fc', builtin.git_commits, { desc = 'Git 提交历史' })
    vim.keymap.set('n', '<leader>fs', builtin.git_status, { desc = 'Git 状态' })
    vim.keymap.set('n', '<leader>fb', builtin.git_branches, { desc = 'Git 分支' })
  end,
}