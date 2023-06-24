return function(client, bufnr)
  -- Workaround for Omnisharp semantic tokens not working
  -- for more details see: https://github.com/OmniSharp/omnisharp-roslyn/issues/2483
  local function toSnakeCase(str) return string.gsub(str, "%s*[- ]%s*", "_") end

  if client.name == "omnisharp" then
    local tokenModifiers = client.server_capabilities.semanticTokensProvider.legend.tokenModifiers
    for i, v in ipairs(tokenModifiers) do
      tokenModifiers[i] = toSnakeCase(v)
    end
    local tokenTypes = client.server_capabilities.semanticTokensProvider.legend.tokenTypes
    for i, v in ipairs(tokenTypes) do
      tokenTypes[i] = toSnakeCase(v)
    end
  end
end
