local default_conf = {
    theme = 'whichkey',
    hspace = 1,
}

return {
    setup = function(opt)
        return vim.tbl_deep_extend('force', default_conf, opt or {})
    end,
}
