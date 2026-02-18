local M = {
    'akinsho/toggleterm.nvim',
    opts = {
        direction = "float",
    },
    config = function()
        require("toggleterm").setup {}
    end,
    event = 'VeryLazy',
    init = require('keymaps').terminal(),
}
return M
