#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Installing pre-commit hooks..."

cd "$PROJECT_ROOT"

if ! command -v pre-commit >/dev/null 2>&1; then
  echo "pre-commit not found. Installing..."
  
  if command -v pip3 >/dev/null 2>&1; then
    pip3 install pre-commit
  elif command -v pip >/dev/null 2>&1; then
    pip install pre-commit
  else
    echo "Error: pip not found. Please install Python and pip first."
    echo "  macOS: brew install python"
    echo "  Ubuntu: sudo apt install python3-pip"
    exit 1
  fi
fi

pre-commit install
pre-commit install --hook-type commit-msg

echo "Pre-commit hooks installed successfully!"
echo ""
echo "To run hooks manually:"
echo "  pre-commit run --all-files"
echo ""
echo "To skip hooks (emergency only):"
echo "  git commit --no-verify"

