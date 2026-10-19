require("nvchad.configs.lspconfig").defaults()

-- vLLM is large enough to exceed Node's default ~2 GB heap during indexing.
-- Keep basedpyright's upstream open-files diagnostic mode, but allow its
-- language server enough memory to finish building navigation data.
vim.lsp.config("basedpyright", {
  cmd_env = { NODE_OPTIONS = "--max-old-space-size=4096" },
  settings = {
    basedpyright = {
      analysis = {
        -- "recommended" (basedpyright's default) floods untyped code with
        -- reportUnknown* warnings; "standard" matches plain Pyright.
        typeCheckingMode = "standard",
      },
    },
  },
})

-- Mason already puts basedpyright-langserver on Neovim's PATH.  Enable one
-- Python language server only: running Pyright and basedpyright together
-- creates duplicate clients, diagnostics, and competing navigation results.
local servers = { "html", "cssls", "basedpyright" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
