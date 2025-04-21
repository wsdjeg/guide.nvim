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
util.group2dict = function(name)
  local id = vim.fn.hlID(name)
  if id == 0 then
    return {
      name = '',
      ctermbg = '',
      ctermfg = '',
      bold = '',
      italic = '',
      reverse = '',
      underline = '',
      guibg = '',
      guifg = '',
    }
  end
  local rst = {
    name = vim.fn.synIDattr(id, 'name'),
    ctermbg = vim.fn.synIDattr(id, 'bg', 'cterm'),
    ctermfg = vim.fn.synIDattr(id, 'fg', 'cterm'),
    bold = vim.fn.synIDattr(id, 'bold'),
    italic = vim.fn.synIDattr(id, 'italic'),
    reverse = vim.fn.synIDattr(id, 'reverse'),
    underline = vim.fn.synIDattr(id, 'underline'),
    guibg = vim.fn.tolower(vim.fn.synIDattr(id, 'bg#', 'gui')),
    guifg = vim.fn.tolower(vim.fn.synIDattr(id, 'fg#', 'gui')),
  }
  return rst
end

util.hide_in_normal = function(name)
  local group = util.group2dict(name)
  if vim.fn.empty(group) == 1 then
    return
  end
  local normal = util.group2dict('Normal')
  local guibg = normal.guibg or ''
  local ctermbg = normal.ctermbg or ''
  group.guifg = guibg
  group.guibg = guibg
  group.ctermfg = ctermbg
  group.ctermbg = ctermbg
  group.blend = 100
  util.hi(group)
end

util.hi = function(info)
  if vim.fn.empty(info) == 1 or vim.fn.get(info, 'name', '') == '' then
    return
  end
  vim.cmd('silent! hi clear ' .. info.name)
  local cmd = 'silent hi! ' .. info.name
  if vim.fn.empty(info.ctermbg) == 0 then
    cmd = cmd .. ' ctermbg=' .. info.ctermbg
  end
  if vim.fn.empty(info.ctermfg) == 0 then
    cmd = cmd .. ' ctermfg=' .. info.ctermfg
  end
  if vim.fn.empty(info.guibg) == 0 then
    cmd = cmd .. ' guibg=' .. info.guibg
  end
  if vim.fn.empty(info.guifg) == 0 then
    cmd = cmd .. ' guifg=' .. info.guifg
  end
  local style = {}

  for _, sty in ipairs({ 'bold', 'italic', 'underline', 'reverse' }) do
    if info[sty] == 1 then
      table.insert(style, sty)
    end
  end

  if vim.fn.empty(style) == 0 then
    cmd = cmd .. ' gui=' .. vim.fn.join(style, ',') .. ' cterm=' .. vim.fn.join(style, ',')
  end
  if info.blend then
    cmd = cmd .. ' blend=' .. info.blend
  end
  pcall(vim.cmd, cmd)
end

function util.hi_separator(a, b)
  local hi_a = util.group2dict(a)
  local hi_b = util.group2dict(b)
  local hi_a_b = {
    name = a .. '_' .. b,
    guibg = hi_b.guibg,
    guifg = hi_a.guibg,
    ctermbg = hi_b.ctermbg,
    ctermfg = hi_a.ctermbg,
  }
  local hi_b_a = {
    name = b .. '_' .. a,
    guibg = hi_a.guibg,
    guifg = hi_b.guibg,
    ctermbg = hi_a.ctermbg,
    ctermfg = hi_b.ctermbg,
  }
  util.hi(hi_a_b)
  util.hi(hi_b_a)
end

local function get_color(name)
  local c = vim.api.nvim_get_hl(0, { name = name })

  if c.link then
    return get_color(c.link)
  else
    return c
  end
end


function util.syntax_at(...)
  local lnum = select(1, ...) or vim.fn.line('.')
  local col = select(2, ...) or vim.fn.col('.')
  local inspect = vim.inspect_pos(0, lnum - 1, col - 1)
  local name, hl
  if #inspect.semantic_tokens > 0 then
    local token, priority = {}, 0
    for _, semantic_token in ipairs(inspect.semantic_tokens) do
      if semantic_token.opts.priority > priority then
        priority = semantic_token.opts.priority
        token = semantic_token
      end
    end
    if token then
      name = token.opts.hl_group_link
      hl = vim.api.nvim_get_hl(0, { name = token.opts.hl_group_link })
    end
  elseif #inspect.treesitter > 0 then
    for i = #inspect.treesitter, 1, -1 do
      name = inspect.treesitter[i].hl_group_link
      hl = vim.api.nvim_get_hl(0, { name = name })
      if hl.fg then
        break
      end
    end
  else
    name = vim.fn.synIDattr(vim.fn.synID(vim.fn.line('.'), vim.fn.col('.'), 1), 'name', 'gui')
    hl = get_color(name)
  end
  return name, hl
end
function util.support_float()
  return vim.fn.exists('*nvim_open_win') == 1
end

function util.opened()
  return vim.fn.win_id2tabwin(util.__winid)[1] == vim.fn.tabpagenr()
end

function util.show()
  if vim.api.nvim_win_is_valid(util.__winid) and vim.fn.has('nvim-0.10.0') == 1 then
    vim.api.nvim_win_set_config(util.__winid, { hide = false })
  end
end

function util.open_float(sl, ...)
  local hide = select(1, ...)
  if hide == true or hide == false then
  else
    hide = false
  end
  if util.__bufnr == nil or vim.fn.bufexists(util.__bufnr) == 0 then
    util.__bufnr = vim.api.nvim_create_buf(false, true)
  end
  if util.__winid == nil or not util.opened() then
    local opt = {
      relative = 'editor',
      width = vim.o.columns,
      height = 1,
      -- highlight = 'SpaceVim_statusline_a_bold',
      row = vim.o.lines - 2,
      col = 0,
    }
    if vim.fn.has('nvim-0.10.0') == 1 then
      opt.hide = hide
    end
    util.__winid = vim.api.nvim_open_win(util.__bufnr, false, opt)
  end
  vim.fn.setwinvar(util.__winid, '&winhighlight', 'Normal:SpaceVim_statusline_a_bold')
  vim.fn.setbufvar(util.__bufnr, '&relativenumber', 0)
  vim.fn.setbufvar(util.__bufnr, '&number', 0)
  vim.fn.setbufvar(util.__bufnr, '&bufhidden', 'wipe')
  vim.fn.setbufvar(util.__bufnr, '&cursorline', 0)
  vim.fn.setbufvar(util.__bufnr, '&modifiable', 1)
  vim.fn.setwinvar(vim.fn.win_id2win(util.__winid), '&cursorline', 0)
  vim.api.nvim_buf_set_virtual_text(util.__bufnr, -1, 0, sl, {})
  vim.fn.setbufvar(util.__bufnr, '&modifiable', 0)
  return util.__winid
end

function util.close_float()
  if util.__winid ~= nil then
    vim.api.nvim_win_close(util.__winid, true)
  end
end

function util.check_width(len, sec, winwidth)
  return len + util.len(sec) < winwidth
  
end

function util.len(sec)
  if not sec then return 0 end
  local str = vim.fn.matchstr(sec, '%{.*}')
  if vim.fn.empty(str) == 0 then
    local pos = vim.fn.match(str, '}')
    return vim.fn.len(sec) - vim.fn.len(str) + vim.fn.len(vim.fn.eval(string.sub(str, 3, pos))) + 4
  else
    return vim.fn.len(sec) + 4
  end
end

function util.eval(sec)
  return vim.fn.substitute(sec, '%{.*}', '', 'g')
end

function util.build(left_sections, right_sections, lsep, rsep, fname, tag, hi_a, hi_b, hi_c, hi_z, winwidth)
  local l = '%#' .. hi_a .. '#' .. left_sections[1]
  l = l .. '%#' .. hi_a .. '_' .. hi_b .. '#' .. lsep
  local flag = true
  local len = 0
  for _, sec in ipairs(vim.tbl_filter(function(v)
    return vim.fn.empty(v) == 0
  end, vim.list_slice(left_sections, 2))) do
    if util.check_width(len, sec, winwidth) then
      if flag then
        l = l .. '%#' .. hi_b .. '#' .. sec
        l = l .. '%#' .. hi_b .. '_' .. hi_c .. '#' .. lsep
      else
        l = l .. '%#' .. hi_c .. '#' .. sec
        l = l .. '%#' .. hi_c .. '_' .. hi_b .. '#' .. lsep
      end
      flag = not flag
    end
  end
  l = string.sub(l, 1, #l - #lsep)
  if #right_sections == 0 then
    if flag then
      return l .. '%#' .. hi_c .. '#'
    else
      return l .. '%#' .. hi_b .. '#'
    end
  end
  if util.check_width(len, fname, winwidth) then
    len = len +  util.len(fname)
    if flag then
      l = l .. '%#' .. hi_c .. '_' .. hi_z .. '#' .. lsep .. '%#' .. hi_z .. '#' .. fname .. '%='
    else
      l = l .. '%#' .. hi_b .. '_' .. hi_z .. '#' .. lsep .. '%#' .. hi_z .. '#' .. fname .. '%='
    end
  else
    if flag then
      l = l .. '%#' .. hi_c .. '_' .. hi_z .. '#' .. lsep .. '%='
    else
      l = l .. '%#' .. hi_b .. '_' .. hi_z .. '#' .. lsep .. '%='
    end
  end
  if util.check_width(len, tag, winwidth) and vim.g.spacevim_enable_statusline_tag == 1 then
    l = l .. '%#' .. hi_z .. '#' .. tag
  end
  l = l .. '%#' .. hi_b .. '_' .. hi_z .. '#' .. rsep
  flag = true
  for _, sec in ipairs(vim.tbl_filter(function(v)
    return vim.fn.empty(v) == 0
  end, right_sections)) do
    if util.check_width(len, sec, winwidth) then
      len = len + util.len(sec)
      if flag then
        l = l .. '%#' .. hi_b .. '#' .. sec
        l = l .. '%#' .. hi_c .. '_' .. hi_b .. '#' .. rsep
      else
        l = l .. '%#' .. hi_c .. '#' .. sec
        l = l .. '%#' .. hi_b .. '_' .. hi_c .. '#' .. rsep
      end
      flag = not flag
    end
  end
  l = string.sub(l, 1, #l - #rsep)
  return l
end

return util
