local M = {}

M.complete = function(ctx, callback)
  local prefix = ctx.prefix
  local suffix = ctx.suffix

  if prefix == "" and suffix == "" then
    callback("")
    return
  end

  local timeout = ctx.timeout
  -- local num_predict = ctx.num_predict or 512
  local temperature = ctx.temperature or 0.1
  local model = ctx.model
  local url = ctx.url

  local filetype = ctx.filetype
  local hint = ""
  if filetype and filetype ~= "" then
    hint = "# language: " .. filetype .. "\n"
  end
  local prompt = "<|fim_prefix|>" .. hint .. prefix .. "<|fim_suffix|>" .. suffix .. "<|fim_middle|>"

  local body = vim.json.encode({
    model = model,
    prompt = prompt,
    stream = false,
    raw = true,
    options = {
      -- num_predict = num_predict,
      temperature = temperature,
      stop = { "<|endoftext|>", "<|fim_suffix|>" },
    },
  })

  local curl_args = {
    url,
    "-d", body,
    "--max-time", timeout,
    "-s",
  }

  return vim.system({ "curl", "-X", "POST", unpack(curl_args) }, nil, function(obj)
    if obj.code ~= 0 then
      callback(nil, "curl exited with code " .. obj.code)
      return
    end

    local ok, res = pcall(vim.json.decode, obj.stdout)

    if not ok or type(res) ~= "table" then
      callback(nil, "failed to parse response")
      return
    end

    if res.error then
      callback(nil, res.error)
      return
    end

    callback(res.response or "")
  end)
end

return M
