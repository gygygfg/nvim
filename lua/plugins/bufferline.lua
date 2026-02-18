return {
    "akinsho/bufferline.nvim",
    config = function()
        vim.opt.termguicolors = true
        require("bufferline").setup {
            options = {
                -- 使用 nvim 内置lsp
                diagnostics = "nvim_lsp",
                -- 左侧让出 nvim-tree 的位置
                offsets = { {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    highlight = "Directory",
                    text_align = "left"
                } }
            }
        }
    end,
    dependencies = {
        'nvim-tree/nvim-web-devicons',
        config = function()
            require 'nvim-web-devicons'.setup {
                color_icons = true,
                default = true,
                strict = true,
            }
        end,
        opt = true,
    },
    event = 'VeryLazy',
}
