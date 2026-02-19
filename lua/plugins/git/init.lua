-- Git 相关插件管理配置
-- 这个文件管理所有与 Git 相关的插件
return {
  {
    -- vim-fugitive: Git 集成插件
    "tpope/vim-fugitive",
    lazy = false,  -- 启动时立即加载
    config = function()
      -- 自定义 fugitive 行为
      vim.g.fugitive_summary_format = "%s"  -- 提交信息只显示标题
      vim.g.fugitive_git_executable = "git" -- 指定 git 路径

      -- 自动关闭 fugitive 缓冲区
      vim.api.nvim_create_autocmd("BufWinLeave", {
        pattern = "fugitive://*",
        callback = function()
          if vim.fn.bufname() == "" then
            vim.cmd("silent! checktime")
          end
        end
      })

      -- 自定义 Gstatus 窗口外观
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fugitive",
        callback = function()
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = "no"
        end
      })
    end,
    init =  require("keymaps").fugitive(),
  },

  {
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
            attach_mappings = function(_, map)
              -- 将回车键设置为硬重置整个项目
              actions.select_default:replace(actions.git_reset_hard)
              -- 保留原有的重置快捷键
              map({ "i", "n" }, "<c-r>m", actions.git_reset_mixed)
              map({ "i", "n" }, "<c-r>s", actions.git_reset_soft)
              map({ "i", "n" }, "<c-r>h", actions.git_reset_hard)
              -- 添加一个额外的 checkout 快捷键
              map({ "i", "n" }, "<c-c>", actions.git_checkout)
              return true
            end,
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

      -- 设置 Git 相关快捷键
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>fc', builtin.git_commits, { desc = 'Git 提交历史' })
      vim.keymap.set('n', '<leader>fs', builtin.git_status, { desc = 'Git 状态' })
      vim.keymap.set('n', '<leader>fb', builtin.git_branches, { desc = 'Git 分支' })

      -- 设置其他 Telescope 快捷键（非 Git 相关）
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '查找文件' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '实时搜索' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '帮助标签' })
    end,
    -- 延迟加载：当使用 Git 相关命令时加载
    event = { "CmdlineEnter *git*", "BufRead */.git/*" },
    init = require("keymaps").telescope(),
  },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
    event = { "BufReadPre", "BufNewFile" },
  },

  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("diffview").setup()
    end,
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
  },
  init = require("plugins.git.commit"),
}
