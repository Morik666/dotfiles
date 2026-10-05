# Zellij project workspace

Add the package with your usual NixOS rebuild, then run Stow yourself to install
these dotfiles. Neither operation is performed by `zl`.

From a project directory, in a Ghostty shell outside Herdr/Zellij:

```sh
zl
```

Before Stow, the repository launcher works as `~/.dotfiles/.local/bin/zl`.
The launcher explicitly selects this configuration directory and adds its own
location to PATH so its shortcuts can find it.

Sessions use the initial directory's folder name, so Ghostty displays a readable
project name alongside the active pane. The name stays fixed when panes change
directories. A mapping in `$XDG_STATE_HOME/zl/sessions.json` (default
`~/.local/state/zl/sessions.json`) associates full paths with names; folders with
the same name receive numeric suffixes. Long names are shortened for socket paths.
Existing hash-named sessions are renamed on the next `zl` launch in that directory,
preserving their running tools. Opening `zl` again in the same directory attaches
to its session. Each pane initially starts in
that directory; subsequent directory changes are independent. This launcher
starts `hx` and `codex`, plus a normal shell.

## Layouts

- **Portrait:** Helix occupies the bottom half. Codex, terminal and additional
  tools share the upper stack; one upper tool is expanded at a time.
- **Laptop:** all tools, including Helix, share one full-height stack.

`Alt+Shift+Space` toggles these layouts without restarting the tools. Monitor
switching is manual for now. The laptop presentation is a stack, not three tabs.
Use `zl new` for extra panes so they join the tool stack rather than splitting
Helix. Keep the editor command as `hx` and the primary pane names as `helix`,
`codex`, `terminal`: the swap layout identifies the editor by its launch command,
and the navigation helper identifies tools by their pane names.

## Shortcuts

| Key | Action |
| --- | --- |
| Alt+1 | Helix |
| Alt+2 | Codex |
| Alt+3 | Terminal |
| Alt+4…9 | Additional tools in creation order (remaining extras renumber after closing one) |
| Alt+Q / Alt+E | Previous / next upper tool; excludes Helix |
| Alt+Shift+T | New shell in the tool stack |
| Alt+Shift+Space | Toggle portrait / laptop |
| Alt+Enter | Toggle focused pane fullscreen |
| Alt+H/J/K/L | Focus left / down / up / right |
| Alt+Shift+R | Resize mode; Escape returns |
| Alt+Shift+P | Pane mode; Escape returns |
| Alt+Shift+E | Open scrollback in Helix |
| Alt+Shift+W | Close focused pane and its running program |
| Alt+Shift+D | Detach and leave processes running |
| Ctrl+G | Toggle locked mode, forwarding other shortcuts to the application |

Ghostty's Ctrl+Shift+number and Ctrl+Shift+Q/E shortcuts still select Ghostty tabs.
Alt+Q/E here cycle tools within the project, not Zellij tabs.
Alt+1…9 and Alt+Q/E preserve fullscreen when switching tools. Alt+Enter returns
to the split layout. The same applies to `zl focus` and `zl cycle`.

## Commands inside the session

```sh
zl focus helix
zl focus 4
zl cycle next
zl new server       # opens a named shell; run the web server in it
zl layout laptop
zl layout portrait
zl layout          # toggle
```

Helpers query live pane IDs, so they do not assume IDs match shortcut numbers.
Navigation is scoped to the current tab. This setup is intended for one active
interactive client per project session; Zellij CLI focus actions follow the
most recently active client.

Run-based shortcuts briefly create a floating helper pane. The helper exits
before applying the action so it does not enter the tool layout. If a shortcut
fails, inspect `~/.local/state/zl/shortcuts.log` (or `$XDG_STATE_HOME/zl/shortcuts.log`).
Running the equivalent `zl` command in a shell prints the error directly.

Detaching preserves live processes. Rebooting/server shutdown does not preserve
process memory or unsaved editor buffers; session resurrection is Zellij's
normal saved-layout/command recovery.

From outside Zellij, `zl start --session-name` prints this directory's session
name. Use `zellij list-sessions` to inspect sessions. Keep one upper tool open
if you want `zl new` to have an existing tool stack to target.
