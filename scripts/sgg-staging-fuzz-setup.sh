#!/usr/bin/env bash
# Bootstrap / refresh the dedicated venv used by sgg-staging-fuzz.py.
# Idempotent — safe to re-run.

set -euo pipefail

VENV_DIR="${HOME}/.local/share/sgg-staging-test/.venv"

if [ ! -d "${VENV_DIR}" ]; then
    echo "Creating venv at ${VENV_DIR}"
    mkdir -p "$(dirname "${VENV_DIR}")"
    python3 -m venv "${VENV_DIR}"
else
    echo "Venv already exists at ${VENV_DIR}"
fi

echo "Installing / upgrading requests"
"${VENV_DIR}/bin/pip" install --quiet --upgrade pip requests

echo
echo "Verifying:"
"${VENV_DIR}/bin/python" -c "import sys, requests; print(f'  python:   {sys.version.split()[0]}'); print(f'  requests: {requests.__version__}'); print(f'  bin:      {sys.executable}')"

echo
echo "Done. Run: sgg-staging-fuzz  (or ${HOME}/code/dotfiles/scripts/sgg-staging-fuzz.py)"
