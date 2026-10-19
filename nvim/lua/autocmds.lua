require "nvchad.autocmds"

-- SLURM job scripts are shell scripts; teach nvim so they get bash
-- highlighting (and so gf on a path inside them behaves normally).
vim.filetype.add({ extension = { sbatch = "sh" } })

-- nvim-treesitter (main branch) no longer turns anything on by itself.
-- For any filetype with an installed parser, start treesitter highlighting
-- and fold by syntax tree. foldlevel 99 opens files fully unfolded.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if not pcall(vim.treesitter.start, args.buf) then
      return
    end
    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo[0][0].foldmethod = "expr"
    vim.wo[0][0].foldlevel = 99
  end,
})
