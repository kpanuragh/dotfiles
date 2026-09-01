# dotfiles

Personal configuration for a Wayland/Hyprland desktop on Gentoo Linux, managed
with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a **stow package** mirroring the layout of `$HOME`,
so `stow hypr` creates `~/.config/hypr -> dotfiles/hypr/.config/hypr`.

## Install

```sh
git clone git@github.com:kpanuragh/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./install.sh              # link everything
./install.sh hypr waybar  # or pick individual packages
./install.sh -n           # dry run — show what would change
./install.sh -D           # unlink
```

Stow is the only dependency:

| Distro | Command |
| --- | --- |
| Gentoo | `sudo emerge app-admin/stow` |
| Debian/Ubuntu | `sudo apt install stow` |
| Arch | `sudo pacman -S stow` |
| macOS | `brew install stow` |

## Packages

### Desktop (Wayland)

| Package | What it configures |
| --- | --- |
| `hypr` | Hyprland compositor, hyprlock, hypridle, hyprpaper |
| `waybar` | Status bar + scripts (music, ClickUp tracking) |
| `wofi` | Application launcher |
| `mako` | Notification daemon |
| `swaylock` | Screen locker |
| `sway` | Sway compositor (fallback session) |
| `gammastep` | Night-light colour temperature |
| `gtk` | GTK 3 and GTK 4 theming |
| `theme` | **Nebula Bloom** — the palette generator that renders every other theme file |
| `wallpapers` | The image set in `~/Pictures/Wallpapers` used by the switchers |

### Terminal & shell

| Package | What it configures |
| --- | --- |
| `bash` | `.bashrc`, `.bash_profile` |
| `kitty` | Kitty terminal |
| `foot` | Foot terminal |
| `tmux` | tmux config + theme (plugins come from TPM, not this repo) |
| `git` | `.gitconfig` |
| `bin` | Personal scripts in `~/bin` |

### TUI tools

| Package | What it configures |
| --- | --- |
| `btop`, `htop` | System monitors |
| `cava` | Audio visualiser (incl. GLSL shaders) |
| `fastfetch` | System info |
| `ranger` | File manager |
| `lazysql` | SQL client — **example only**, see below |
| `clickup` | Waybar time-tracking scripts — **example only**, see below |

### Editors

| Package | What it configures |
| --- | --- |
| `doom` | Doom Emacs `config.el` / `init.el` / `packages.el` |

Neovim lives in its own repository, because it has its own history and test suite:

```sh
git clone git@github.com:kpanuragh/nvim.git ~/.config/nvim
```

Doom Emacs itself is not vendored here. Install it separately:

```sh
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
```

## Secrets

No credentials are committed. Configs that need them ship as `*.example`;
copy each one and fill in your own values. `install.sh` lists any that are
still missing after linking.

```sh
cp ~/.config/lazysql/config.toml.example  ~/.config/lazysql/config.toml
cp ~/.config/clickup/config.json.example  ~/.config/clickup/config.json
```

The ClickUp scripts additionally read an API token from
`~/.config/clickup/token` (mode `600`), which is gitignored:

```sh
printf '%s' 'pk_YOUR_TOKEN' > ~/.config/clickup/token
chmod 600 ~/.config/clickup/token
```

## Wallpapers

`wallpapers` installs 16 images to `~/Pictures/Wallpapers`, plus a `current`
symlink marking the active one.

- `Mod+Shift+W` runs `wallpaper-switcher.sh` — pick an image in wofi, it is
  applied to every monitor and `current` is repointed.
- `wallpaper-init.sh` restores `current` at login (Hyprland autostart).

Because `current` lives in the repo, switching wallpaper leaves an uncommitted
change. Commit it to persist the choice across machines, or `git checkout
wallpapers/` to discard it.

The `wallhaven-*` images come from [wallhaven.cc](https://wallhaven.cc) and are
redistributed here without recorded licensing. Replace them if you fork this.

## Theming

`theme` is a small Python generator: it renders one palette out to Waybar, GTK,
kitty, tmux and the rest, so colours stay consistent across the desktop.
The GTK 4 config symlinks into `~/.themes/nebula-bloom/`, which is *generated*
rather than committed — run the generator once on a new machine:

```sh
python3 ~/.config/theme/apply.py
```

## Notes

- A few configs hardcode `/home/anuragh` (Waybar `exec` paths, `PATH` entries in
  `.bashrc`). Adjust them if your username differs.
- `tmux` plugins are managed by TPM: `prefix + I` after first launch.
