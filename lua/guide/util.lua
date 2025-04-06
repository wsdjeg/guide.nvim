local util = {}

util.setlocalopt = function(buf, win, opts)
end
function util.getchar(...)
  local status, ret = pcall(vim.fn.getchar, ...)
  if not status then
    ret = 3
  end
  if type(ret) == 'number' then
    return vim.fn.nr2char(ret)
  else
    return ret
  end
end

function util.t(str)
  if vim.api ~= nil and vim.api.nvim_replace_termcodes ~= nil then
    -- https://github.com/neovim/neovim/issues/17369
    local ret = vim.api.nvim_replace_termcodes(str, false, true, true):gsub('\128\254X', '\128')
    return ret
  else
    -- local ret = vim.fn.execute('echon "\\' .. str .. '"')
    -- ret = ret:gsub('<80>', '\128')
    -- return ret
    return vim.eval(string.format('"\\%s"', str))
  end
end


return util
