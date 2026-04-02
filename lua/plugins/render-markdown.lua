-- render-markdown.nvim 配置
-- 文件：~/.config/nvim/lua/plugins/render-markdown.lua

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "codecompanion" },
  build = function()
    -- 仅安装必要的 tree-sitter 解析器
    local ts_parsers = { "html", "latex", "yaml" }
    local installed_parsers = {}

    for _, parser in ipairs(ts_parsers) do
      local ok, _ = pcall(function()
        vim.cmd("TSInstall " .. parser)
      end)
      if ok then
        table.insert(installed_parsers, parser)
      end
    end

    if #installed_parsers > 0 then
      vim.notify("[render-markdown] 已安装 tree-sitter 解析器: " .. table.concat(installed_parsers, ", "))
    end
  end,
  config = function()
    -- 检查 tree-sitter 解析器是否可用
    local function has_treesitter_parser(lang)
      local ok, parsers = pcall(vim.treesitter.language.get_parser, 0, lang)
      return ok and parsers ~= nil
    end

    -- 检查外部命令是否存在
    local function has_command(cmd)
      local handle = io.popen("command -v " .. cmd .. " 2>/dev/null")
      if handle then
        local result = handle:read("*a")
        handle:close()
        return result ~= ""
      end
      return false
    end

    -- 基础配置
    local config = {
      -- HTML 支持
      html = { enabled = has_treesitter_parser("html") },

      -- LaTeX 支持
      latex = {
        enabled = has_treesitter_parser("latex") and
            (has_command("utftex") or has_command("latex2text")),
        -- 如果 LaTeX 工具不可用，使用降级方案
        fallback_to_plain_text = true
      },

      -- YAML 支持
      yaml = { enabled = has_treesitter_parser("yaml") },

      -- Markdown 支持（始终启用）
      markdown = { enabled = true },

      -- 图标支持
      icons = { enabled = true },

      -- 代码块高亮
      code_blocks = {
        enabled = true,
        highlight = {
          enabled = true,
          use_treesitter = true,
          theme = "github-dark",
        },
      },

      -- 渲染设置
      render = {
        delay = 50,
        max_lines = 10000,
      },

      -- 用户界面设置
      ui = {
        -- 启用浮动窗口预览
        floating_preview = true,
        -- 预览窗口大小
        preview_width = 80,
        preview_height = 25,
      },
    }

    -- 输出配置状态（仅在调试时启用）
    if vim.g.render_markdown_debug then
      vim.notify("[render-markdown] 配置状态:")
      vim.notify("  • HTML 支持: " .. (config.html.enabled and "✅ 已启用" or "❌ 已禁用"))
      vim.notify("  • LaTeX 支持: " .. (config.latex.enabled and "✅ 已启用" or "❌ 已禁用"))
      vim.notify("  • YAML 支持: " .. (config.yaml.enabled and "✅ 已启用" or "❌ 已禁用"))
    end

    -- 应用配置
    require("render-markdown").setup(config)
  end,
}
