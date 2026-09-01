# Source .bashrc for interactive shells
[ -f ~/.bashrc ] && . ~/.bashrc

# Wayland environment (compositor-agnostic)
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1

# Auto-start compositor on TTY1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  export XDG_CURRENT_DESKTOP=Hyprland
  export XDG_SESSION_DESKTOP=Hyprland
  exec dbus-run-session Hyprland 2> ~/hyprland.log
  # Fallback: comment the line above and uncomment below to use sway again
  # export XDG_CURRENT_DESKTOP=sway
  # exec dbus-run-session sway 2> ~/sway.log
fi

# Added by LM Studio CLI tool (lms)
export PATH="/home/anuragh/.lmstudio/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/home/anuragh/.local/bin:$PATH"
