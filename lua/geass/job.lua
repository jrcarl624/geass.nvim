local M = {}

local providers = require("geass.providers")
M.start_job = function(ctx, on_exit)
  local mod, err = providers.resolve(ctx.provider)
  if not mod then
    on_exit(nil, err)
    return
  end
  return mod.complete(ctx, function(text, err)
    on_exit(text, err)
  end)
end

return M
