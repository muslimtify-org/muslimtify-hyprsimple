# Muslimtify for Hyprsimple

Prayer times, tomorrow's next prayer, a countdown, and Muslimtify settings in the Hyprsimple bar. Requires the Hyprsimple external plugin API 1 and the `muslimtify` AUR package. The manager installs missing dependencies.

```sh
hyprsimple-plugin install muslimtify-org/muslimtify-hyprsimple
```

The plugin installs at `~/.local/share/hyprsimple-plugins/muslimtify`. It appears on the left. Click the widget or press `SUPER + P` to toggle the panel. Right click switches between the prayer time and countdown. The panel alias is `prayer`. In the panel, `s` switches settings, `r` refreshes, and Escape leaves settings then closes the panel. Schedule failures show an error while retaining the last usable schedule and retrying.

Enable registers the daemon with `muslimtify daemon install`, then checks `muslimtify daemon status`. Either command failing fails activation so the manager can retry it. Disable uses `muslimtify daemon uninstall` and propagates failures. Disable and removal preserve Muslimtify's configuration and the installed package. The daemon commands must be available in the installed Muslimtify version.

Muslimtify saves settings in `${XDG_CONFIG_HOME:-$HOME/.config}/muslimtify/config.json`. The views follow that file and show rejected changes as errors. Hyprsimple plugin enablement, placement and settings live separately in `~/.config/hyprsimple/plugins.json`. This version uses Muslimtify's own settings rather than adding plugin settings.

## Checks

```sh
bash test/check.sh
HYPRSIMPLE_SOURCE=/path/to/hyprsimple bash test/check.sh
```

The first command is self-contained and requires Bash and Node.js. It tests schedule and config parsing, tomorrow transitions, timezone and prayer offsets, countdowns, lifecycle failures and retries, settings preservation and the manifest. ShellCheck runs when installed.

With `HYPRSIMPLE_SOURCE`, integration additionally requires Quickshell, jq, ripgrep and ImageMagick. It commits a scratch snapshot, uses the real manager to install from that local Git repository, and loads the installed code with real Quickshell offscreen. HOME, XDG directories, D-Bus and plugin storage are isolated. Package, daemon, timezone, link opener and desktop commands are stubbed. It verifies disable, re-enable and removal, bindings and preserved application configuration.

The smoke test compiles and instantiates the actual `Panel.qml`, `Widget.qml`, `Service.qml`, both views and their shared dependencies. Offscreen Quickshell has no PanelWindow backend. A scratch copy of the public module replaces only PopupPanel's window boundary with an Item that provides its context and open/close contract. All other public exports resolve to the core files. No layer-shell windows are created. Compositor focus, positioning and physical monitor behavior are outside this test's scope.

The integration check copies the exact core `bin/hyprsimple-dev-optimize-images` script into a scratch layout with this plugin's assets and runs its supported `--check` mode there. The optimizer always operates on its own repository root. It never runs against or changes the core checkout. The extracted logo uses WebP to meet that policy while retaining its appearance and transparency.

## Attribution

Extracted from Hyprsimple's existing Muslimtify integration on `feat/external-plugins`, with MIT attribution retained in `LICENSE`. Prayer-specific display constants are owned by this plugin. The core integration remains until Hyprsimple's later migration task.
