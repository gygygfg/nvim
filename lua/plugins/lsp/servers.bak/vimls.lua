return {
    -- 定义一个 on_attach 函数，在 LSP 附加到缓冲区时设置快捷键
    on_attach = function(client, bufnr)
        -- 启用缓冲区级的快捷键映射
        local opts = { noremap = true, silent = true, buffer = bufnr }

        -- 跳转到定义
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        -- 显示悬停文档
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        -- 查找引用
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        -- 重命名符号
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        -- 代码操作
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        -- 查看工作区文件夹
        vim.keymap.set('n', '<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
    end,

    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT', -- 告知服务器使用 LuaJIT
            },
            diagnostics = {
                globals = {'vim'} -- 避免将 'vim' 全局变量报错
            },
            workspace = {
                library = {
                    -- 让服务器识别 Neovim 的运行时文件，提供 Neovim API 的补全
                    vim.api.nvim_get_runtime_file("", true)
                },
                -- 可选：防止服务器因其他项目的 .luarc.json 而卡顿
                checkThirdParty = false
            },
            telemetry = { enable = false } -- 禁用遥测
        }
    }
}
