local M = {}

function M.callback_option(cb, ...)
  if type(cb) == "function" then
    return cb(...)
  end
end

return M
