local M = {}

M.get_prefix_suffix = function(opts)
  opts = opts or {}
  local context_window = opts.context_window
  local context_ratio = opts.context_ratio

  local cursor_row = vim.fn.line(".")
  local cursor_col = vim.fn.col(".")

  local lines_before = vim.api.nvim_buf_get_lines(0, 0, cursor_row - 1, false)
  local lines_after = vim.api.nvim_buf_get_lines(0, cursor_row, -1, false)
  local current_line = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, false)[1] or ""

  local prefix_parts = {}
  if #lines_before > 0 then
    table.insert(prefix_parts, table.concat(lines_before, "\n"))
  end
  table.insert(prefix_parts, current_line:sub(1, cursor_col - 1))
  local prefix = table.concat(prefix_parts, "\n")

  local suffix_parts = {}
  table.insert(suffix_parts, current_line:sub(cursor_col))
  if #lines_after > 0 then
    table.insert(suffix_parts, table.concat(lines_after, "\n"))
  end
  local suffix = table.concat(suffix_parts, "\n")

  local prefix_limit = math.floor(context_window * context_ratio)
  local suffix_limit = context_window - prefix_limit

  if #prefix > prefix_limit then
    prefix = prefix:sub(#prefix - prefix_limit + 1)
  end
  if #suffix > suffix_limit then
    suffix = suffix:sub(1, suffix_limit)
  end

  return {
    prefix = prefix,
    suffix = suffix,
    cursor_line = current_line,
    cursor_col = cursor_col,
    cursor_row = cursor_row,
    lines_after = lines_after,
    filetype = vim.bo.filetype,
  }
end

return M
