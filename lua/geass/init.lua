local M = {}

local context = require("geass.context")
local job = require("geass.job")
local diff = require("geass.diff")

M.defaults = {
  provider = "ollama",
  model = "ibm/granite4:tiny-h",
  url = "http://localhost:11434/api/generate",
  debounce = 300,
  throttle = 1000,
  context_window = 16000,
  context_ratio = 0.75,
  timeout = 60,
  keymaps = {
    trigger = "<M-CR>",
    accept = "<Tab>",
    dismiss = "<Esc>",
  },
  highlights = {
    ghost_text = { link = "Comment" },
  },
}

M.current_edits = {}
M._job_handle = nil
M._job_id = 0

M._cancel_job = function()
  M._job_id = M._job_id + 1
  if M._job_handle then
    pcall(M._job_handle.kill, M._job_handle)
    M._job_handle = nil
  end
end

M.trigger_completion = function()
  if M._job_handle then
    return
  end
  local job_id = M._job_id

  local ctx = context.get_prefix_suffix({
    context_window = M.config.context_window,
    context_ratio = M.config.context_ratio,
  })
  ctx.provider = M.config.provider
  ctx.model = M.config.model
  ctx.url = M.config.url
  ctx.timeout = M.config.timeout

  M._job_handle = job.start_job(ctx, function(completion, err)
    if M._job_id ~= job_id then
      return
    end
    M._job_handle = nil
    if err then
      vim.notify("[geass] " .. err, vim.log.levels.WARN)
      vim.print(err)
      return
    end

    vim.notify("[geass] generated", vim.log.levels.INFO)
    M.current_edits = diff.preview(ctx, completion)
  end)
end

M.accept = function()
  if #M.current_edits == 0 then
    return
  end
  diff.apply(M.current_edits)
  M.current_edits = {}
  M._cancel_job()
end

M.dismiss = function()
  M._cancel_job()
  M.current_edits = {}
  vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace("geass-diff"), 0, -1)
end

M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  local group = vim.api.nvim_create_augroup("Geass", { clear = true })
  vim.api.nvim_create_autocmd("CursorHoldI", {
    group = group,
    callback = M.trigger_completion,
  })
  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = group,
    callback = function()
      M._cancel_job()
      M.current_edits = {}
      vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace("geass-diff"), 0, -1)
    end,
  })
  vim.keymap.set("i", "<Plug>(geass-trigger)", function()
      M._cancel_job()
      M.trigger_completion()
    end)
  vim.keymap.set("i", M.config.keymaps.trigger, "<Plug>(geass-trigger)")
  vim.keymap.set("i", M.config.keymaps.accept, M.accept)
  vim.keymap.set("i", M.config.keymaps.dismiss, M.dismiss)
end
return M
