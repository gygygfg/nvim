-- lua/config/editor.lua
-- 编辑器增强配置

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("nvim-autopairs").setup({
      -- nvim-autopairs - 自动括号配对
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
      },
    })

    local ok, Comment = pcall(require, "Comment")
    if not ok then
      return
    end

    Comment.setup({
      mappings = {
        basic = false,
        extra = false,
      },
    })

    -- 切换当前行注释（行注释）
    vim.keymap.set("n", "<leader>l", function()
      return vim.v.count == 0 and "<Plug>(comment_toggle_linewise_current)" or "<Plug>(comment_toggle_linewise_count)"
    end, { expr = true, desc = "切换当前行注释（行）" })

    -- 可视模式切换注释（行注释）
    vim.keymap.set(
      "v",
      "<leader>l",
      "<Plug>(comment_toggle_linewise_visual)",
      { desc = "切换选中行注释（行）" }
    )

    -- 切换当前行注释（块注释）- 正常模式
    vim.keymap.set("n", "<leader>k", function()
      return vim.v.count == 0 and "<Plug>(comment_toggle_blockwise_current)" or "<Plug>(comment_toggle_blockwise_count)"
    end, { expr = true, desc = "切换当前行注释（块）" })

    -- 可视模式切换注释（块注释）
    vim.keymap.set(
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
  end,
})
