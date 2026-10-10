# Muslimtify for Hyprsimple

Prayer times, tomorrow's next prayer, a countdown and Muslimtify settings in the [Hyprsimple](https://github.com/rizukirr/hyprsimple) bar.

## Install

```sh
hyprsimple-plugin muslimtify-org/muslimtify-hyprsimple
```

This needs Hyprsimple with the external plugin API 1. The manager installs the `muslimtify` AUR package if it is missing, registers the Muslimtify daemon and enables the plugin. The code lands in `~/.local/share/hyprsimple-plugins/muslimtify`.

## Use

The widget sits on the left of the bar.

| Action | Result |
|---|---|
| Click the widget | Toggle the panel |
| Right click the widget | Switch between the prayer time and the countdown |
| `s` in the panel | Switch to settings |
| `r` in the panel | Refresh the schedule |
| Escape | Leave settings, then close the panel |

When the schedule cannot be read, the panel shows the error, keeps the last usable schedule and retries.

## Bind a key

The plugin binds no key. Its panel alias is `prayer`, and the key is yours to choose. Add a line to `~/.config/hypr/bindings/applications.lua`:

```lua
hl.bind("SUPER + P", hl.dsp.exec_cmd(vars.barPanel .. "prayer"), { description = "Prayer Times (panel)" })
```

The same panel opens from a terminal or a script:

```sh
qs -p ~/.local/share/hyprsimple/default/quickshell ipc call bar toggle prayer
```

## Manage

```sh
hyprsimple-plugin list
hyprsimple-plugin update muslimtify
hyprsimple-plugin disable muslimtify
hyprsimple-plugin enable muslimtify
hyprsimple-plugin remove muslimtify
```

Enable runs `muslimtify daemon install` and then checks `muslimtify daemon status`. If either fails, the plugin stays disabled and `enable` can be run again. Disable runs `muslimtify daemon uninstall`. Disabling or removing the plugin keeps your Muslimtify configuration and the installed package.

## Settings

Location, calculation method, offsets and reminders are Muslimtify's own settings, saved in `${XDG_CONFIG_HOME:-$HOME/.config}/muslimtify/config.json`. The panel's settings view edits that file and shows a rejected change as an error.

Whether the plugin is enabled and where its widget sits are Hyprsimple's, in `~/.config/hyprsimple/plugins.json`. Set `placement` there to `left`, `center` or `right` and restart the bar to move the widget.

## Develop

```sh
bash test/check.sh
HYPRSIMPLE_SOURCE=/path/to/hyprsimple bash test/check.sh
```

The first command needs only Bash and Node.js. It tests schedule and config parsing, tomorrow transitions, timezone and prayer offsets, countdowns, lifecycle failures and retries, settings preservation and the manifest. ShellCheck runs when it is installed.

With `HYPRSIMPLE_SOURCE` set to a Hyprsimple checkout, the integration test also runs. It needs Quickshell, jq, ripgrep and ImageMagick. It commits a scratch snapshot of this repository, installs it with the real `hyprsimple-plugin install --local`, and loads the installed code in real Quickshell offscreen. Then it disables, enables and removes the plugin and checks that the application configuration survives. HOME, the XDG directories, D-Bus and plugin storage are isolated. Package, daemon, timezone, link opener and desktop commands are stubbed.

Offscreen Quickshell has no PanelWindow backend, so the test replaces only PopupPanel's window with an Item that keeps its context and open and close contract. Every other import resolves to the core files. Layer-shell placement, compositor focus and physical monitor behavior need a real Hyprland session.

The integration test also runs the core's `bin/hyprsimple-dev-optimize-images --check` against this plugin's assets in a scratch copy, so images here meet the same policy as the core's. It never touches the core checkout.

## Attribution

Extracted from Hyprsimple's built-in Muslimtify integration. MIT, see `LICENSE`.
