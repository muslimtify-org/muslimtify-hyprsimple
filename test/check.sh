#!/bin/bash
set -euo pipefail
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO"
node test/model-test.js
bash test/lifecycle-test.sh
for script in scripts/*.sh test/*.sh; do bash -n "$script"; done
if command -v shellcheck >/dev/null; then shellcheck scripts/*.sh test/*.sh; fi
node - <<'JS'
const assert = require('node:assert/strict')
const fs = require('node:fs')
const manifest = JSON.parse(fs.readFileSync('manifest.json', 'utf8'))
assert.equal(manifest.id, 'muslimtify')
assert.equal(manifest.apiVersion, 1)
assert.equal(manifest.schemaVersion, 1)
assert.deepEqual(manifest.dependencies.aur, ['muslimtify'])
assert.equal(manifest.placement, 'left')
assert.equal(manifest.bindings[0].key, 'SUPER + P')
assert.deepEqual(manifest.panelAliases, ['prayer'])
for (const path of [...Object.values(manifest.entryPoints), ...Object.values(manifest.lifecycle)]) assert.ok(fs.statSync(path).isFile())
console.log('ok - manifest contract')
JS
if [[ -n ${HYPRSIMPLE_SOURCE:-} ]]; then
  bash test/integration-test.sh
else
  echo 'Integration omitted: set HYPRSIMPLE_SOURCE to an API 1 core checkout with Quickshell installed.'
fi
