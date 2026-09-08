-- lua/config/cmp.lua
-- 必须优先设置：释放 Tab 键，防止 Vim 内置 wildmenu 在 C 层面拦截
-- 否则 cmp 的 cmdline mapping 收不到 Tab 事件
vim.opt.wildchar = 26   -- <C-z> 的 ASCII 码
vim.opt.wildcharm = 26
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
      ["<CR>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          local entry = cmp.get_selected_entry()
          if entry then
            cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace })
          else
            cmp.close()
            fallback()
          end
        else
          fallback()
        end
      end, { "i", "s" }),
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

        -- 正常补全流程（cmp 可见时优先导航菜单）
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          -- cmp 不可见时，优先尝试拼写自动纠正
          local tab_spell_ok, tab_spell = pcall(require, "core.spell")
          if tab_spell_ok and tab_spell.config and tab_spell.config.auto_correct_on_tab and has_words_before() then
            if tab_spell.auto_correct_current_word() then
              return
            end
          end

          if has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end
      end, { "i", "s" }),
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

  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
    },
  })

  -- 加载 cmp-cmdline 插件（因为它是 opt 包）
  vim.cmd.packadd("cmp-cmdline")

  -- 获取预设的 cmdline mappings
  local cmdline_mappings = cmp.mapping.preset.cmdline()

  -- 直接用底层 vim.keymap.set 接管命令行 Tab，不依赖 cmp.mapping 系统
  -- 注意：cmp 使用 vim.on_key() 拦截按键，但 wildchar 释放后 Tab 由这里处理
  vim.keymap.set("c", "<Tab>", function()
    if cmp.visible() then
      -- cmp 可见时：Tab 用于导航菜单项
      cmp.select_next_item()
      return
    end

    -- cmp 不可见时：尝试拼写自动纠正
    local cmd_spell_ok, cmd_spell = pcall(require, "core.spell")
    if cmd_spell_ok and cmd_spell.config and cmd_spell.config.auto_correct_on_tab then
      if cmd_spell.auto_correct_current_word() then
        return
      end
    end

    -- 回退：发送 <C-z> 触发 Vim 内置 wildmenu
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<C-z>", true, false, true),
      "n", true
    )
  end, { noremap = true, silent = true })

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
