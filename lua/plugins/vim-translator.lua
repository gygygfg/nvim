local M = {
    'bujnlc8/vim-translator',
    config = function()
        -- require("vim-translator").setup()
    end,
    opt = {
        translator_channel = 'youdao' -- 查询通道 youdao ro baidu
    },
    event = 'VeryLazy',
    init = require('keymaps').translate(),
}
return M
