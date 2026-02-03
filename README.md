# rekitten

Persistent-ish sessions for [Kitty terminal](https://sw.kovidgoyal.net/kitty/).

rekitten saves tabs and splits (best-effort) and restores them on startup.

## How it works

rekitten uses Kitty's watcher system to automatically save session state whenever:
- Tabs are created, closed, moved, or renamed
- Windows are closed
- Focus changes between windows

Uses Kitty's own [sessions](https://sw.kovidgoyal.net/kitty/sessions/) to load on startup.

## Limitations

- Supports only the splits layout. Others may work but I do not use them and will not test them.
- Does not restore running programs (only cwd).

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/shkm/rekitten/main/install-remote.sh | bash
```

Or manually:

```bash
git clone https://github.com/shkm/rekitten.git
cd rekitten
./install.sh
```

Then restart Kitty.

## Uninstallation

```bash
cd ~/repos/rekitten
./uninstall.sh
```

## Configuration

rekitten is plug and play, but there are a couple of variables you can set if you like.

### Debug logging

```bash
export REKITTEN_DEBUG=1
```

Logs are written to `$XDG_STATE_HOME/rekitten/rekitten.log` (defaults to `~/.local/state/rekitten/rekitten.log`)

### Debounce interval

Prevents excessive saves during rapid tab operations.

```bash
export REKITTEN_DEBOUNCE=5  # seconds, default is 2
```

### State dir

Where to store stuff. Respects `XDG_STATE_HOME` by default, falling back to `~/.local/state/rekitten`.

```bash
export REKITTEN_STATE_DIR=$HOME/.local/state/rekitten
```

### Kitty config directory

rekitten respects Kitty's `KITTY_CONFIG_DIRECTORY` environment variable. If set, rekitten will install to that location instead of `~/.config/kitty`.

```bash
export KITTY_CONFIG_DIRECTORY=$HOME/.config/kitty
```

## Files

- `$XDG_STATE_HOME/rekitten/session` - Kitty session file (loaded on startup)
- `$XDG_STATE_HOME/rekitten/state.json` - Raw state for debugging
- `$XDG_STATE_HOME/rekitten/rekitten.log` - Log file

Defaults to `~/.local/state/rekitten/` if `XDG_STATE_HOME` is not set.

Override with `REKITTEN_STATE_DIR` environment variable.

## Requirements

- Kitty terminal **with remote control enabled**
- Python 3.8+

## Troubleshooting

1. Check that [remote control](https://sw.kovidgoyal.net/kitty/remote-control/) is enabled in `kitty.conf`
2. Enable debug logging (`export REKITTEN_DEBUG=1`) and check the log file
3. Verify the session file exists: `cat ~/.local/state/rekitten/session`

## License

MIT
