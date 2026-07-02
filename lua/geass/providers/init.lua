local M = {}

local providers = {
  ollama = "geass.providers.ollama",
  opencode = "geass.providers.opencode",
}

M.resolve = function(name)
  local path = providers[name]
  if not path then
    return nil, "unknown provider: " .. tostring(name)
  end
  local ok, mod = pcall(require, path)
  if not ok then
    return nil, "failed to load provider " .. name .. ": " .. tostring(mod)
  end
  return mod
end

return M
