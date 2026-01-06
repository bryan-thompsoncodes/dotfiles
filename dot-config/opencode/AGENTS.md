# Agent Behavioral Instructions

## LSP Setup Protocol

When I encounter a missing or unavailable LSP (Language Server Protocol):

1. **Pause** before proceeding with workarounds
2. **Check** the project's `.envrc` to identify which nix flake is being used
3. **Ask** the user: "I notice the LSP for [language] is not available. Would you like me to add it to your nix flake at [path]?"
4. **Upon confirmation**, add the appropriate language server package to the flake's `buildInputs`
5. **Suggest** running `direnv reload` to activate the changes

This ensures proper LSP tooling is available for the repository rather than working around the gap.
