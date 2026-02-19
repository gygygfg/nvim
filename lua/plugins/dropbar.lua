local M = {
    'Bekaboo/dropbar.nvim',
    config = function()
        vim.ui.select = require('dropbar.utils.menu').select
    end,
    event = 'VeryLazy',
}
return M
