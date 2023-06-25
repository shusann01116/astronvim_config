return {
  handlers = {
    ["textDocument/definition"] = require("omnisharp_extended").handler,
  },
  enable_roslyn_analyzers = true,
  organize_imports_on_format = true,
  enable_import_completion = true,
  enable_decompilation_support = true,
}
