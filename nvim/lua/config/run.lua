local M = {}
local term_bufnr = nil
local term_chan_id = nil

function M.run()
  local ft = vim.bo.filetype
  local filename = vim.fn.expand("%:p")
  local filename_without_ext = vim.fn.expand("%:r")
  local class_name = vim.fn.expand("%:t:r")
  local cmd = ""

  if ft == "python" then
    cmd = "clear && python3 " .. filename
  elseif ft == "c" then
    cmd = "gcc " .. filename .. " -o " .. filename_without_ext .. " && clear &&" .. filename_without_ext
  elseif ft == "java" then
    local dir = vim.fn.fnamemodify(filename, ":h")
    local file = vim.fn.fnamemodify(filename, ":t")
    cmd = "cd " .. dir .. " && javac " .. file .. " && clear && java " .. class_name
  elseif ft == "javascript" then
    cmd = "clear && node " .. filename
  else
    print("Unsupported filetype: " .. ft)
    return
  end

  local function is_term_invalid()
    return not term_bufnr or not vim.api.nvim_buf_is_valid(term_bufnr) or vim.fn.jobwait({term_chan_id}, 0)[1] ~= -1
  end

  if is_term_invalid() then
    -- Create a new vertical split window for terminal
    vim.cmd("botright vsplit")
    vim.cmd("vertical resize 50")

    -- Create a new buffer and set it as terminal
    term_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, term_bufnr)
    term_chan_id = vim.fn.termopen(os.getenv("SHELL") or "zsh")
  else
    local win_id = vim.fn.bufwinid(term_bufnr)
    if win_id == -1 then
      vim.cmd("botright vsplit")
      vim.cmd("vertical resize 50")
      vim.api.nvim_win_set_buf(0, term_bufnr)
    else
      -- Terminal is visible: focus it
      vim.api.nvim_set_current_win(win_id)
    end
  end

  -- Send command to terminal
  if term_chan_id then
    vim.fn.chansend(term_chan_id, cmd .. "\n")
  end
end

return M
