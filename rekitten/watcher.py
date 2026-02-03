"""Kitty watcher hooks for rekitten.

This module is loaded by Kitty as a global watcher. It hooks into tab/window
events to automatically save session state.
"""

from __future__ import annotations

import threading
import time
from typing import Any, TYPE_CHECKING

if TYPE_CHECKING:
    from kitty.boss import Boss
    from kitty.window import Window

# Import our modules - handle both direct execution and as kitty watcher
try:
    from rekitten.config import DEBOUNCE_SECONDS
    from rekitten.session import save_state
    from rekitten.logger import get_logger
except ImportError:
    # When loaded by Kitty, we may need to add our parent to path
    import sys
    from pathlib import Path
    # Add the rekitten package parent directory to path
    _pkg_dir = Path(__file__).parent.parent
    if str(_pkg_dir) not in sys.path:
        sys.path.insert(0, str(_pkg_dir))
    from rekitten.config import DEBOUNCE_SECONDS
    from rekitten.session import save_state
    from rekitten.logger import get_logger

log = get_logger(__name__)

# Debounce state
_last_save_time: float = 0
_pending_save: threading.Timer | None = None
_lock = threading.Lock()

# Startup grace period - don't save during initial session load
_startup_time: float | None = None
STARTUP_GRACE_SECONDS = 5.0  # Wait 5 seconds after startup before allowing saves


def _debounced_save() -> None:
    """Execute a debounced save operation."""
    global _last_save_time, _pending_save

    with _lock:
        _pending_save = None
        _last_save_time = time.time()

    log.debug("Executing debounced save")
    try:
        save_state()
    except Exception as e:
        log.exception(f"Error saving state: {e}")


def _schedule_save() -> None:
    """Schedule a save operation with debouncing."""
    global _pending_save

    # Skip saves during startup grace period to avoid capturing transient state
    if _startup_time is not None:
        time_since_startup = time.time() - _startup_time
        if time_since_startup < STARTUP_GRACE_SECONDS:
            log.debug(f"Skipping save during startup grace period ({time_since_startup:.1f}s < {STARTUP_GRACE_SECONDS}s)")
            return

    with _lock:
        now = time.time()
        time_since_last = now - _last_save_time

        # If enough time has passed, save immediately
        if time_since_last >= DEBOUNCE_SECONDS:
            if _pending_save is not None:
                _pending_save.cancel()
                _pending_save = None
            # Release lock before saving
            with _lock:
                pass
            _debounced_save()
            return

        # Otherwise, schedule a save for later (if not already scheduled)
        if _pending_save is None:
            delay = DEBOUNCE_SECONDS - time_since_last
            log.debug(f"Scheduling save in {delay:.2f}s")
            _pending_save = threading.Timer(delay, _debounced_save)
            _pending_save.daemon = True
            _pending_save.start()
        else:
            log.debug("Save already scheduled, skipping")


# Kitty watcher callbacks


def on_load(boss: "Boss", data: dict[str, Any]) -> None:
    """Called once when the watcher module is first loaded."""
    global _startup_time
    _startup_time = time.time()
    log.info("rekitten watcher loaded")
    log.debug(f"Debounce interval: {DEBOUNCE_SECONDS}s, startup grace: {STARTUP_GRACE_SECONDS}s")


def on_tab_bar_dirty(boss: "Boss", window: "Window", data: dict[str, Any]) -> None:
    """Called when tabs change (created, closed, moved, renamed)."""
    log.debug("on_tab_bar_dirty triggered")
    _schedule_save()


def on_close(boss: "Boss", window: "Window", data: dict[str, Any]) -> None:
    """Called when a window is closed."""
    log.debug(f"on_close triggered for window {window.id if window else 'unknown'}")
    _schedule_save()


def on_focus_change(boss: "Boss", window: "Window", data: dict[str, Any]) -> None:
    """Called when window focus changes.

    We use this to track the active tab/window for restoration.
    """
    focused = data.get("focused", False)
    if focused:
        log.debug(f"Focus changed to window {window.id if window else 'unknown'}")
        _schedule_save()
