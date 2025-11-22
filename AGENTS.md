# AGENTS.md - Coding Guidelines for Dotfiles Repository

## Build/Lint/Test Commands
This is a dotfiles repository with no traditional build process. For validation:
- Test shell functions manually: `vets-website-server`, `vets-api-server`, etc.
- Check trailing whitespace: `git diff --check`
- Verify cross-platform compatibility before committing

## Code Style Guidelines

### Shell Scripts (Bash/Zsh)
- Use `#!/usr/bin/env bash` or `#!/usr/bin/env zsh` for portability
- Environment variables with defaults: `${VAR:-default}`
- Error handling: `|| return 1`, validate directories exist
- Color output for user-facing scripts (GREEN/YELLOW/RED/BOLD/NC variables)
- NO trailing whitespace on empty lines
- Use `local` for function variables
- `set -e` for scripts that should fail fast

### Lua (Neovim Configuration)
- Use `local` for variables
- Descriptive comments for configuration sections
- Follow existing plugin configuration patterns
- Clean, minimal style with proper indentation

### Git Commits
- Imperative mood: "Add feature" not "Added feature"
- First line: brief summary (50 chars or less)
- Blank line, then detailed explanation if needed

### Documentation
- README files: comprehensive but scannable
- Clear section headers and code examples
- Document both "what" and "why"
- Cross-platform instructions where applicable

### Cross-Platform Considerations
- Use "source if exists" pattern for plugins
- Check multiple paths: Homebrew, nix-darwin, standard Linux
- Platform detection: `[[ "$OSTYPE" == "darwin"* ]]`
- Environment variables for customizable paths

### Error Handling
- Validate required directories/files before operations
- Return early on failure with helpful error messages
- Confirm destructive operations before proceeding
- Show progress and completion summaries

### Security
- Never commit API keys, tokens, or secrets
- Use .gitconfig.local for signing keys
- Whitelist specific config files rather than blacklisting cache patterns

### OpenCode Configuration
- OpenCode AI assistant configured to use Open WebUI server at ai.thompson.codes
- Provider template lives in `dot-config/opencode/opencode.template.json`; `setup-platform-configs.sh` seeds `opencode.json` from that template only when the host-local file is missing
- `dot-config/opencode/opencode.json` mirrors `~/.config/opencode/opencode.json`, is gitignored, and should contain the per-host `"options.apiKey"` (Keychain helper: `security find-generic-password -a "$LOGNAME" -s ai.thompson.codes-openwebui -w`)
- Default instructions reference `README.md` and `AGENTS.md`; add repo-specific overrides via `.opencode/project.json` if needed