local M = {}
local logger

local function log(t, msg)
    if not logger then
        local ok, l = pcall(require, 'logger')
        if ok then
            logger = l.derive('guide')
            logger[t](msg)
        end
    else
        logger[t](msg)
    end
end
function M.info(msg)
    log('info', msg)
end
function M.debug(msg)
    log('debug', msg)
end

return M
