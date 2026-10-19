require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- custom bindings
map("n", "<leader><leader>", "<cmd>Telescope find_files<CR>", { desc = "telescope find file" })
map("n", "<leader>/", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" }) -- overrides default toggle-comment binding; use gcc for that
map("n", "<leader>,", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })

map("n", "<leader>fs", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<leader>bk", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

map("n", "<leader>gg", function()
  require("nvchad.term").toggle { pos = "float", id = "lazygitTerm", cmd = "lazygit" }
end, { desc = "term toggle lazygit" }) -- requires the `lazygit` binary installed

map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP code action" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "LSP rename" })
map({ "n", "x" }, "<leader>cf", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })

map("n", "<leader>ot", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

-- Buffer-local navigation mappings are installed only after an LSP client
-- attaches, so normal buffers retain their existing key behavior.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }

    map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "LSP definition" }))
    map("n", "gr", require("telescope.builtin").lsp_references, vim.tbl_extend("force", opts, { desc = "LSP references" }))
    map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP hover" }))
    map("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "LSP implementation" }))
    map("n", "<leader>ls", require("telescope.builtin").lsp_document_symbols,
      vim.tbl_extend("force", opts, { desc = "Telescope document symbols" }))
    map("n", "<leader>lr", require("telescope.builtin").lsp_references,
      vim.tbl_extend("force", opts, { desc = "Telescope references" }))
  end,
})
