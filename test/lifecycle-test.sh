#!/bin/bash
set -euo pipefail
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "${TMP:?}"' EXIT
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" PATH="$TMP/bin:$PATH"
mkdir -p "$TMP/bin" "$XDG_CONFIG_HOME/muslimtify"
printf '%s\n' '{"keep":"user settings"}' > "$XDG_CONFIG_HOME/muslimtify/config.json"
cp "$XDG_CONFIG_HOME/muslimtify/config.json" "$TMP/config"
export CALLS="$TMP/calls" FAIL_INSTALL=0 FAIL_STATUS=0 FAIL_UNINSTALL=0
cat > "$TMP/bin/muslimtify" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$CALLS"
case "$*" in
 'daemon install') exit "$FAIL_INSTALL" ;;
 'daemon status') exit "$FAIL_STATUS" ;;
 'daemon uninstall') exit "$FAIL_UNINSTALL" ;;
 *) exit 99 ;;
esac
STUB
chmod +x "$TMP/bin/muslimtify"
expect_status() {
  local expected=$1 actual=0
  shift
  "$@" || actual=$?
  [[ $actual == "$expected" ]]
}
export FAIL_INSTALL=17
expect_status 17 bash "$REPO/scripts/enable.sh"
[[ $(wc -l < "$CALLS") == 1 ]]
export FAIL_INSTALL=0 FAIL_STATUS=18
expect_status 18 bash "$REPO/scripts/enable.sh"
export FAIL_STATUS=0
bash "$REPO/scripts/enable.sh"
bash "$REPO/scripts/enable.sh"
export FAIL_UNINSTALL=19
expect_status 19 bash "$REPO/scripts/disable.sh"
export FAIL_UNINSTALL=0
bash "$REPO/scripts/disable.sh"
bash "$REPO/scripts/disable.sh"
cmp "$TMP/config" "$XDG_CONFIG_HOME/muslimtify/config.json"
echo 'ok - enable/status/disable failure propagation, retry and settings preservation'
