#!/bin/bash
set -euo pipefail
# Unregister the daemon without removing application settings or packages.
if command -v muslimtify >/dev/null 2>&1; then
  muslimtify daemon uninstall
fi
