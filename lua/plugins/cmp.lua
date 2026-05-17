-- lua/config/cmp.lua
vim.pack.add({
  -- 补全相关
  gh("hrsh7th/nvim-cmp"),
  gh("hrsh7th/cmp-path"),
  gh("L3MON4D3/LuaSnip"),
  gh("hrsh7th/cmp-buffer"),
  gh("hrsh7th/cmp-cmdline"),
  gh("hrsh7th/cmp-nvim-lsp"),
  gh("saadparwaiz1/cmp_luasnip"),
})

local function _cmp_setup()
  -- nvim-cmp 自动补全配置
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  -- 加载自动拼写纠正模块
  local spell_ok, spell = pcall(require, "core.spell")
  if spell_ok then
    spell.setup({
      enabled = true,
      auto_correct_on_tab = true,
    })
  end

  cmp.setup({
    preselect = cmp.PreselectMode.None,
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<CR>"] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace }),
      ["<C-.>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
      ["<C-,>"] = cmp.mapping({
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        local has_words_before = function()
          local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
          if buftype == "prompt" or buftype == "nofile" then
            return false
          end
          local cursor = vim.api.nvim_win_get_cursor(0)
          local line, col = cursor[1], cursor[2]
          return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
        end

        -- 优先尝试拼写自动纠正（在 cmp 可见之前，因为 typo 时补全内容也是错的）
        local spell_ok, spell = pcall(require, "core.spell")
        if spell_ok and spell.config and spell.config.auto_correct_on_tab and has_words_before() then
          if spell.auto_correct_current_word() then
            return
          end
        end

        -- 正常补全流程
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s", "c" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    sources = cmp.config.sources({
      { name = "luasnip" },
      { name = "nvim_lsp" },
      { name = "path" },
      { name = "buffer" },
    }),
    sorting = {
      comparators = {
        cmp.config.compare.offset,
        cmp.config.compare.exact,
        cmp.config.compare.score,
        cmp.config.compare.recently_used,
        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
      },
    },
  })

  -- 命令行补全
  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
    },
  })

  -- 加载 cmp-cmdline 插件（因为它是 opt 包）
  vim.cmd.packadd("cmp-cmdline")

  local cmdline_mappings = cmp.mapping.preset.cmdline()
  -- 在命令模式 Tab 中集成拼写纠正（始终优先，与 insert 模式保持一致）
  local orig_tab = cmdline_mappings["<Tab>"]["c"]

  -- 辅助函数：从命令行提取光标所在的单词
  local function get_cmdline_word()
    local cmdline = vim.fn.getcmdline()
    if cmdline == "" then return nil end
    local cmdpos = vim.fn.getcmdpos()
    local pos = math.min(cmdpos, #cmdline)
    if pos < 1 then pos = 1 end

    local word_start = pos
    for i = pos, 1, -1 do
      local ch = cmdline:sub(i, i)
      if ch:match("%w") then word_start = i else break end
    end
    local word_end = pos
    for i = pos, #cmdline do
      local ch = cmdline:sub(i, i)
      if ch:match("%w") then word_end = i else break end
    end
    local word = cmdline:sub(word_start, word_end)
    if word == "" then return nil end
    return word, word_start, word_end, cmdline
  end

  cmdline_mappings["<Tab>"] = cmp.mapping(function(fallback)
    local spell_ok, spell = pcall(require, "core.spell")

    -- 使用 pcall 包裹自定义逻辑，捕获任何错误
    local ok, result = pcall(function()
      local cursor_word, ws, we, cmdline = get_cmdline_word()
      if not cursor_word then return false end

      -- 第1步：用 getcompletion 获取所有 cmdline 候选，Levenshtein 匹配
      -- （包含内置命令，弥补 nvim_get_commands 只返回用户命令的不足）
      local candidates = vim.fn.getcompletion(cursor_word, "cmdline")
      -- 扩展候选列表：以前缀匹配的方式扩展更多候选
      -- 取光标词的前3个字符作为扩展前缀
      if #cursor_word >= 3 then
        local ext = vim.fn.getcompletion(cursor_word:sub(1, 3), "cmdline")
        for _, e in ipairs(ext) do
          candidates[#candidates + 1] = e
        end
      end

      if #candidates > 0 and spell_ok and spell._levenshtein then
        local best_match = nil
        local best_dist = math.huge
        for _, candidate in ipairs(candidates) do
          if type(candidate) == "string" then
            local dist = spell._levenshtein(cursor_word:lower(), candidate:lower())
            if dist < best_dist and dist <= 2 then
              best_dist = dist
              best_match = candidate
            end
          end
        end
        if best_match then
          local new_cmdline = cmdline:sub(1, ws - 1) .. best_match .. cmdline:sub(we + 1)
          vim.fn.setcmdline(new_cmdline)
          vim.fn.setcmdpos(ws - 1 + #best_match + 1)
          return true
        end
      end

      -- 第2步：回退到 spellsuggest 拼写纠正
      if spell_ok and spell.config and spell.config.auto_correct_on_tab then
        if spell.auto_correct_current_word() then
          if cmp.visible() then
            cmp.close()
          end
          return true
        end
      end
      return false
    end)

    if ok and result then
      return
    end

    -- 第3步：执行原 Tab 行为（cmp 菜单导航）
    orig_tab(fallback)
  end, { "c" })
  end, { "c" })




  cmp.setup.cmdline(":", {
    mapping = cmdline_mappings,
    sources = cmp.config.sources({
      { name = "path" },
    }, {
      {
        name = "cmdline",
        option = {
          ignore_cmds = { "Man", "!" },
        },
      },
    }),
  })
end

vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineChanged" }, {
  once = true,
  callback = function()
    _cmp_setup()
  end,
})
