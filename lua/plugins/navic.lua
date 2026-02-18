return {
    "SmiteshP/nvim-navic",
    dependencies = {
        "nvim-tree/nvim-web-devicons", -- optional, for symbol icons
    },
    opts = {
        separator = " > ",
        highlight = true,
        depth_limit = 0,
        icons = {}, -- Will use nvim-web-devicons if available
    },
    init = function()
        -- Initialize navic
        local navic = require("nvim-navic")
        navic.setup(vim.g['nvim-navic'] or {})
    end,
    event = "VeryLazy",
}