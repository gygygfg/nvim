-- lua/config/editor.lua
-- 编辑器增强配置

require("nvim-autopairs").setup({
  -- nvim-autopairs setup
  check_ts = true,
  ts_config = {
    lua = { "string" },
    javascript = { "template_string" },
  },
})

vim.api.nvim_create_autocmd("VimEnter", {
  -- Comment.nvim setup
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, Comment = pcall(require, "Comment")
      if not ok then
        vim.notify("Comment.nvim 插件未安装", vim.log.levels.WARN)
        return
      end

      Comment.setup({
        mappings = {
          basic = false,
          extra = false,
        },
        pre_hook = function(ctx)
          -- 使用 treesitter 获取正确的 commentstring
          local ok, ts_context = pcall(require, "ts_context_commentstring.integrated")
          if ok then
            local result = ts_context.calculate_commentstring()
            if result then
              return result
            end
          end
          -- 回退到原生 commentstring
          return vim.bo.commentstring
        end,
      })

      vim.keymap.set("n", "<leader>l", function()
        -- 切换当前行注释（行注释）
        return vim.v.count == 0 and "<Plug>(comment_toggle_linewise_current)" or "<Plug>(comment_toggle_linewise_count)"
      end, { expr = true, desc = "切换当前行注释（行）" })

      vim.keymap.set(
        -- 可视模式切换注释（行注释）
        "v",
        "<leader>l",
        "<Plug>(comment_toggle_linewise_visual)",
        { desc = "切换选中行注释（行）" }
      )

      vim.keymap.set("n", "<leader>k", function()
        -- 切换当前行注释（块注释）- 正常模式
        return vim.v.count == 0 and "<Plug>(comment_toggle_blockwise_current)"
          or "<Plug>(comment_toggle_blockwise_count)"
      end, { expr = true, desc = "切换当前行注释（块）" })

      vim.keymap.set(
        -- 可视模式切换注释（块注释）
        "v",
        "<leader>k",
        "<Plug>(comment_toggle_blockwise_visual)",
        { desc = "切换选中行注释（块）" }
      )

      --[[ -- 操作符待处理模式（行注释）
        vim.keymap.set("n", "gc", "<Plug>(comment_toggle_linewise)", { desc = "行注释操作符" })
        操作符待处理模式（块注释）
        vim.keymap.set("n", "gb", "<Plug>(comment_toggle_blockwise)", { desc = "块注释操作符" })
        可视模式（行注释）
        vim.keymap.set("x", "gc", "<Plug>(comment_toggle_linewise_visual)", { desc = "可视模式行注释" })
        可视模式（块注释）
        vim.keymap.set("x", "gb", "<Plug>(comment_toggle_blockwise_visual)", { desc = "可视模式块注释" })
      ]]
      -- 额外映射
      vim.keymap.set("n", "gco", "<Plug>(comment_insert_linewise_below)", { desc = "在下方插入注释" })
      vim.keymap.set("n", "gcO", "<Plug>(comment_insert_linewise_above)", { desc = "在上方插入注释" })
      vim.keymap.set("n", "gcA", "<Plug>(comment_insert_linewise_eol)", { desc = "在行末插入注释" })
    end)
  end,
})
