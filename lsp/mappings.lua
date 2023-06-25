return {
  n = {
    -- FIXME: Workaround for omnisharp-extended can't handle telescope's api
    -- https://github.com/Hoffs/omnisharp-extended-lsp.nvim/issues/24
    ["gd"] = {
      function() vim.lsp.buf.definition() end,
      desc = "Show the definition of current symbol",
    },
  },
}
