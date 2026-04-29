# scripts/

Local utility scripts managed as part of dotfiles.

## sgg-staging-fuzz

Exercises the Common Grants API on staging with sampled filter / sort /
pagination combinations and captures every non-2xx response.

### First-time setup

```bash
scripts/sgg-staging-fuzz-setup.sh
```

Creates `~/.local/share/sgg-staging-test/.venv` and installs `requests`. The
script's shebang points at that venv, so Python dependencies live outside any
project repo and survive HHS project reshuffles.

### Secret

Place the staging API key at `~/.secrets/simpler-grants-staging-api-key` (raw
value on a single line, `chmod 600`). This follows the existing `~/.secrets/`
convention where each file is one secret.

### Run

```bash
sgg-staging-fuzz                   # shell function (see dot-config/zsh/functions.zsh)
scripts/sgg-staging-fuzz.py        # direct invocation
API_KEY=... scripts/sgg-staging-fuzz.py    # override the secret file
```

Output: `staging_failures.csv` in the current working directory.
