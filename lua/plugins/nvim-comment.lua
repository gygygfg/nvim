local M = {
    'terrortylor/nvim-comment',
    config = function()
        require('nvim_comment').setup({ create_mappings = false })
    end,
    cmd = 'CommentToggle',
    init = require('keymaps').comment(),
}
return M
