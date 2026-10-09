#!/bin/bash
# Real manager and QML, isolated from packages, services and the desktop.
set -euo pipefail
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CORE=$(realpath "${HYPRSIMPLE_SOURCE:?Set HYPRSIMPLE_SOURCE to the core checkout}")
TMP=$(mktemp -d)
trap 'rm -rf "${TMP:?}"' EXIT
QS=$(command -v qs)
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" XDG_RUNTIME_DIR="$TMP/runtime"
export XDG_DATA_HOME="$HOME/.local/share" XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
export HYPRSIMPLE_PATH="$CORE" HYPRSIMPLE_PLUGIN_ROOT="$HOME/.local/share/hyprsimple-plugins"
export PATH="$TMP/bin:$PATH" CALLS="$TMP/calls" SCHEDULE_FAILURE="$TMP/schedule-failure"
unset WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE
mkdir -p "$TMP/bin" "$TMP/source" "$TMP/shell" "$XDG_RUNTIME_DIR" "$HOME/.local/bin" "$XDG_CONFIG_HOME/muslimtify"
chmod 700 "$XDG_RUNTIME_DIR"
# The manager clones committed content. Commit a snapshot only in a scratch repo.
cp -a "$REPO/manifest.json" "$REPO/Service.qml" "$REPO/Widget.qml" "$REPO/Panel.qml" "$REPO/lib" "$REPO/views" "$REPO/components" "$REPO/assets" "$REPO/scripts" "$TMP/source/"
git -C "$TMP/source" init -q -b main
git -C "$TMP/source" add .
git -C "$TMP/source" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm fixture
printf '%s\n' '{"location":{"city":"Preserve me"}}' > "$XDG_CONFIG_HOME/muslimtify/config.json"
cp "$XDG_CONFIG_HOME/muslimtify/config.json" "$TMP/config"
cat > "$TMP/bin/muslimtify" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$CALLS"
case "$1" in
 daemon|version) exit 0 ;;
 show) if [[ -f $SCHEDULE_FAILURE ]]; then echo 'Error: fixture offline' >&2; exit 12; fi
       printf '%s\n' '{"date":"2026-10-09","prayers":{"fajr":{"time":"05:00"},"dhuhr":{"time":"12:00"},"asr":{"time":"15:00"},"maghrib":{"time":"18:00"},"isha":{"time":"19:00"}}}' ;;
 location) printf '%s\n' '{"gmt":"UTC+7.0"}' ;;
 method) printf '  mwl * Muslim World League\n' ;;
 *) exit 98 ;;
esac
STUB
cat > "$TMP/bin/pacman" <<'STUB'
#!/bin/bash
[[ $1 == -Q && $2 == muslimtify ]]
STUB
cat > "$TMP/bin/pgrep" <<'STUB'
#!/bin/bash
exit 1
STUB
for command in sudo systemctl hyprctl xdg-open timedatectl paru yay; do
  cat > "$TMP/bin/$command" <<'STUB'
#!/bin/bash
printf 'unexpected operation: %s\n' "$0 $*" >&2
exit 99
STUB
done
printf '#!/bin/bash\nexit 0\n' > "$HOME/.local/bin/hyprsimple-restart-bar.sh"
chmod +x "$TMP/bin/"* "$HOME/.local/bin/hyprsimple-restart-bar.sh"
manager() { bash "$CORE/.local/bin/hyprsimple-plugin" "$@"; }
manager install --local "$TMP/source"
manager validate muslimtify
jq -e '.plugins.muslimtify.enabled and .plugins.muslimtify.placement == "left"' "$XDG_CONFIG_HOME/hyprsimple/plugins.json" >/dev/null
jq -e '.bindings[0].pluginId == "muslimtify" and .bindings[0].key == "SUPER + P"' "$XDG_STATE_HOME/hyprsimple/plugins/bindings.json" >/dev/null
for dir in plugins theme bar components panels system launcher muslimtify notifications; do ln -s "$CORE/default/quickshell/$dir" "$TMP/shell/$dir"; done
# Offscreen Quickshell has no PanelWindow backend. Replace only the public
# window boundary in a scratch module. Actual plugin panel and views are loaded.
mkdir -p "$TMP/shell/Hyprsimple"
cp "$CORE/default/quickshell/Hyprsimple/qmldir" "$TMP/shell/Hyprsimple/qmldir"
sed -i 's|../panels/PopupPanel.qml|MockPopupPanel.qml|' "$TMP/shell/Hyprsimple/qmldir"
cat > "$TMP/shell/Hyprsimple/MockPopupPanel.qml" <<'QML'
import QtQuick
Item {
    required property var bar
    required property Item anchorItem
    required property string name
    property int panelWidth: 400
    property Item focusTarget: null
    readonly property bool open: bar.openPanel === name
    width: panelWidth
    function dismiss() { bar.openPanel = "" }
}
QML
cat > "$TMP/shell/shell.qml" <<'QML'
import QtQuick
import Quickshell
import Quickshell.Io
import qs.plugins
import qs.theme
import qs.components
import qs.bar
import qs.panels
ShellRoot {
    id: root
    property int failures: 0
    property bool checked: false
    property var owned: []
    property var savedToday: null
    property int stage: 0
    Registry { id: registry; onFailed: root.failures++ }
    Item {
        id: bar
        property var screen: ({name:"fixture"})
        property string openPanel: ""
        function toggle(name) { openPanel = openPanel === name ? "" : name }
    }
    Process {
        id: failSchedule
        command: ["touch", Quickshell.env("SCHEDULE_FAILURE")]
        onExited: code => { root.require(code === 0, "failure fixture"); root.stage = 1; registry.services.muslimtify.refresh() }
    }
    Process {
        id: restoreSchedule
        command: ["rm", Quickshell.env("SCHEDULE_FAILURE")]
        onExited: code => { root.require(code === 0, "recovery fixture"); root.stage = 3; registry.services.muslimtify.refresh() }
    }
    PluginContext { id: context; pluginId: "muslimtify"; bar: bar; screen: bar.screen; anchorItem: bar }
    function require(value, message) {
        if (!value) { console.error("SMOKE-FAIL", message); Qt.quit(); throw Error(message) }
    }
    Timer {
        interval: 100
        running: registry.ready
        repeat: true
        onTriggered: {
            if (root.checked) {
                const service = registry.services.muslimtify
                if (root.stage === 1 && service.scheduleError.indexOf("fixture offline") !== -1) {
                    require(service.today === root.savedToday, "failed refresh retains schedule")
                    root.stage = 2
                    restoreSchedule.running = true
                } else if (root.stage === 3 && service.scheduleError === "" && !service.todayFailed && service.today !== root.savedToday) {
                    console.log("SMOKE-PASS actual service, widget, Panel.qml, views, shared dependencies and failed schedule recovery")
                    Qt.quit()
                }
                return
            }
            require(root.failures === 0 && registry.plugins.length === 1, "registry acceptance")
            const service = registry.services.muslimtify
            require(service !== null, "real service creation")
            if (!service.probed || !service.today || !service.tomorrow || service.utcOffset === null) return
            root.checked = true
            require(service.available && service.utcOffset === 420, "stubbed service data")
            require(service.context.screen === null && service.context.bar === null, "service context")
            service.now = new Date("2026-10-09T16:59:00Z")
            require(service.next.isTomorrow && service.next.remaining === 301, "tomorrow transition")
            context.service = service
            const plugin = registry.plugins[0]
            const widget = registry.create(plugin.paths["Widget.qml"], bar, context, "muslimtify")
            require(widget !== null && widget.visible, "actual widget")
            widget.showRemaining = true
            require(widget.label.indexOf("-05:01") !== -1, "countdown display")
            context.togglePanel()
            require(context.panelOpen && widget.active, "widget context toggle")
            context.closePanel()
            require(!context.panelOpen, "close")
            require(registry.resolvePanel("prayer") === "plugin:muslimtify", "alias")
            // The actual plugin Panel.qml uses the fixture window boundary.
            const path = plugin.paths["Panel.qml"]
            const panel = Qt.createComponent("file://" + path, Component.PreferSynchronous)
            require(panel.status === Component.Ready, "actual Panel.qml and dependencies: " + panel.errorString())
            const panelObject = panel.createObject(bar, {context: context})
            require(panelObject !== null, "actual panel creation")
            require(panelObject.bar === bar && panelObject.anchorItem === bar && panelObject.name === context.panelId, "panel wrapper context")
            context.togglePanel()
            require(panelObject.open, "panel open")
            panelObject.setSettingsOpen(true)
            require(panelObject.settingsOpen, "settings page")
            panelObject.setSettingsOpen(false)
            context.closePanel()
            require(!panelObject.settingsOpen && !panelObject.open, "panel close")
            root.owned.push(panelObject)
            panel.destroy()
            const base = path.slice(0, path.lastIndexOf("/"))
            for (const name of ["TodayView", "SettingsView"]) {
                const component = Qt.createComponent("file://" + base + "/views/" + name + ".qml", Component.PreferSynchronous)
                require(component.status === Component.Ready, name + ": " + component.errorString())
                const view = component.createObject(bar, {service: service, width: 400})
                require(view !== null && view.implicitHeight > 0, name + " creation")
                root.owned.push(view)
                component.destroy()
            }
            root.savedToday = service.today
            failSchedule.running = true
        }
    }
}
QML
export QML_IMPORT_PATH="$TMP/shell:$CORE/default/quickshell" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software
export DBUS_SESSION_BUS_ADDRESS="unix:path=$TMP/no-bus"
if ! timeout 20 "$QS" -p "$TMP/shell" --no-color > "$TMP/log" 2>&1; then cat "$TMP/log"; exit 1; fi
cat "$TMP/log"
rg -q SMOKE-PASS "$TMP/log"
if rg -q 'SMOKE-FAIL|Unable to assign|ReferenceError|TypeError|Error loading|Failed to load' "$TMP/log"; then exit 1; fi
jq '.plugins.muslimtify.settings = {keep:"plugin setting"}' "$XDG_CONFIG_HOME/hyprsimple/plugins.json" > "$TMP/settings"
mv "$TMP/settings" "$XDG_CONFIG_HOME/hyprsimple/plugins.json"
manager disable muslimtify
jq -e '.plugins.muslimtify.enabled == false' "$XDG_CONFIG_HOME/hyprsimple/plugins.json" >/dev/null
jq -e '.bindings == []' "$XDG_STATE_HOME/hyprsimple/plugins/bindings.json" >/dev/null
manager enable muslimtify
manager remove muslimtify
[[ ! -e $HYPRSIMPLE_PLUGIN_ROOT/muslimtify ]]
jq -e '.plugins.muslimtify.enabled == false' "$XDG_CONFIG_HOME/hyprsimple/plugins.json" >/dev/null
jq -e '.plugins.muslimtify.settings.keep == "plugin setting"' "$XDG_CONFIG_HOME/hyprsimple/plugins.json" >/dev/null
cmp "$TMP/config" "$XDG_CONFIG_HOME/muslimtify/config.json"
echo 'ok - real local manager install/load/disable/re-enable/remove and config preservation'
# Run the exact core optimizer against plugin assets in its own scratch root.
mkdir -p "$TMP/images/bin" "$TMP/images/assets"
cp "$CORE/bin/hyprsimple-dev-optimize-images" "$TMP/images/bin/"
cp "$REPO/assets/"* "$TMP/images/assets/"
bash "$TMP/images/bin/hyprsimple-dev-optimize-images" --check
