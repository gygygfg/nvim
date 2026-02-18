return {
  'anurag3301/nvim-platformio.lua',
  cond = function()
    -- 条件加载：当检测到platformio.ini文件时启用插件
    local platformioRootDir = (vim.fn.filereadable('platformio.ini') == 1) and vim.fn.getcwd() or nil
    if platformioRootDir then
      vim.g.platformioRootDir = platformioRootDir
      return true
    end
    return false
  end,
  config = function()
    vim.g.pioConfig = {
      lsp = 'clangd',          -- 或 'ccls'
      clangd_source = 'ccls',  -- 或 'compiledb'
      menu_key = '<leader>\\', -- 菜单触发键
      debug = false
    }

    local pok, platformio = pcall(require, 'platformio')
    if pok then
      platformio.setup(vim.g.pioConfig)
    end
  end,
  cmd = { 'Pioinit', 'Piorun', 'Piocmdh', 'Piocmdf', 'Piolib', 'Piomon', 'Piodebug', 'Piodb' },
  dependencies = {
    'akinsho/toggleterm.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    'folke/which-key.nvim',
  },
}
