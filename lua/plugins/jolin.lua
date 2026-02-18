local M = {
    "tylerTaerak/joplin.nvim",
    config = function()
        require("joplin").setup {
            joplin_token = "5b47bb287dabefef48f1194edcad742f58fd6bd4484620a037dd53747cc131d391b3019fb5c21476d664fcf3374e2e04a89c1c48a58408612be55b2aaf78e2b4"
        }
    end,
    -- dependencies = { 'nvim-tree/nvim-web-devicons', opt = true },
    -- event = "VeryLazy",
}
return M
