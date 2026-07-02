local M = {}

local ns = vim.api.nvim_create_namespace("geass-diff")

function M.compute_edits(ctx, completion)
  local suffix = ctx.suffix
  local cursor_row = ctx.cursor_row
  local cursor_col = ctx.cursor_col

  if not completion or completion == "" then
    return {}
  end

  local a = suffix
  local b = completion

  local edits = {}

  local function map_to_buffer(b_idx)
    if b_idx == 0 then
      return cursor_row, cursor_col
    end
    return cursor_row + b_idx, 1
  end

  local diff_text = vim.text.diff(a, b)
  if not diff_text then
    return edits
  end

  local b_pos = 0
  for line in diff_text:gmatch("[^\n]+") do
    local prefix = line:sub(1, 1)
    if prefix == "+" or prefix == " " then
      local text = line:sub(2)

      if prefix == "+" then
        local buf_line, buf_col = map_to_buffer(b_pos)
        table.insert(edits, {
          line = buf_line,
          col = buf_col,
          text = text,
        })
        b_pos = b_pos + 1
      elseif prefix == " " then
        b_pos = b_pos + 1
      end
    end
  end

  return edits
end

function M.preview(ctx, completion)
  local edits = M.compute_edits(ctx, completion)

  vim.schedule(function()
    if #edits == 0 then
      vim.notify("[geass] no changes suggested", vim.log.levels.INFO)
      return
    end

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    local lines = {}

    local virt_lines = {}
    for i, e in ipairs(edits) do
      if i == 1 then
        vim.api.nvim_buf_set_extmark(0, ns, ctx.cursor_row - 1, ctx.cursor_col - 1, {
          virt_text = { { e.text, "Comment" } },
          virt_text_pos = "overlay",
          hl_mode = "combine",
        })
      else
        table.insert(virt_lines, { { e.text, "Comment" } })
      end
    end
    if #virt_lines > 0 then
      vim.api.nvim_buf_set_extmark(0, ns, ctx.cursor_row - 1, 0, {
        virt_lines = virt_lines,
        virt_lines_above = false,
      })
    end

    vim.print(table.concat(lines, "\n"))
  end)

  return edits
end

function M.apply(edits)
  local buf = vim.api.nvim_get_current_buf()
  local text = table.concat(vim.tbl_map(function(e) return e.text end, edits), "\n")
  local row = vim.fn.line(".") - 1
  local col = vim.fn.col(".") - 1
  vim.api.nvim_buf_set_text(buf, row, col, row, col, vim.split(text, "\n", { plain = true }))
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

return M
