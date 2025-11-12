# Tokyo Night Tmux

![example workflow](https://github.com/janoamaral/tokyo-night-tmux/actions/workflows/pre-commit.yml/badge.svg?branch=master)

A clean, dark Tmux theme that celebrates the lights of Downtown [Tokyo at night.](https://www.google.com/search?q=tokyo+night&newwindow=1&sxsrf=ACYBGNRiOGCstG_Xohb8CgG5UGwBRpMIQg:1571032079139&source=lnms&tbm=isch&sa=X&ved=0ahUKEwiayIfIhpvlAhUGmuAKHbfRDaIQ_AUIEigB&biw=1280&bih=666&dpr=2)
The perfect companion for [tokyonight-vim](https://github.com/ghifarit53/tokyonight-vim)
Adapted from the original, [Visual Studio Code theme](https://github.com/enkia/tokyo-night-vscode-theme).
The old version (deprecated) is still available in the `legacy` branch.

<a href="https://www.buymeacoffee.com/jano" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

## About this theme

This is a very opinionated project, as I am a Tech Lead, this theme is very developer-focused.

## Requirements

This theme has the following hard requirements:

- Any patched [Nerd Fonts] (v3 or higher)
- Bash 4.2 or newer

The following are recommended for full support of all widgets and features:

- [Noto Sans] Symbols 2 (for segmented digit numbers)
- [bc] (for netspeed and git widgets)
- [jq], [gh], [glab] (for git widgets)
- [playerctl] (Linux) or [nowplaying-cli] (macOS) for music statusbar

### macOS

macOS still ships with bash 3.2 so you must provide a newer version.
You can easily install all dependencies via [Homebrew]:

```bash
brew tap homebrew/cask-fonts
brew install --cask font-monaspace-nerd-font font-noto-sans-symbols-2
brew install bash bc coreutils gawk gh glab gsed jq nowplaying-cli
```

### Linux

#### Alpine Linux

```bash
apk add bash bc coreutils gawk git jq playerctl sed
```

#### Arch Linux

```bash
pacman -Sy bash bc coreutils git jq playerctl
```

#### Ubuntu

```bash
apt-get install bash bc coreutils gawk git jq playerctl
```

Check documentation for installing on other operating systems.

## Installation using TPM

In your `tmux.conf`:

```bash
set -g @plugin "janoamaral/tokyo-night-tmux"
```

## Configuration

### Widget Ordering

Customize the order of widgets in the status bar. You can also omit widgets to hide them.

```bash
# Default order (organized by logical context)
# System → Development → Network → Environment → Time
set -g @tokyo-night-tmux_widgets_order "cpu,gpu,memory,disk,battery,git,wbg,path,ssh,clients,sync,weather,music,netspeed,datetime"

# Developer-focused setup
set -g @tokyo-night-tmux_widgets_order "cpu,memory,git,wbg,path,datetime"

# System monitoring setup
set -g @tokyo-night-tmux_widgets_order "cpu,gpu,memory,disk,battery,netspeed,datetime"

# Minimal setup
set -g @tokyo-night-tmux_widgets_order "git,datetime"
```

**Available widgets (organized by context):**

**System Resources:**
- `cpu` - CPU usage percentage with load average
- `gpu` - GPU usage (Apple Silicon, NVIDIA, AMD)
- `memory` - Memory usage percentage with pressure indicator
- `ram` - RAM usage in GB/TB format (alternative to memory%)
- `disk` - Disk usage percentage
- `battery` - Battery status and percentage

**Development & Git:**
- `git` - Local git status (changes, branch, sync)
- `wbg` - Web-based git (GitHub/GitLab PRs, issues)
- `path` - Current working directory path

**Network & Connectivity:**
- `netspeed` - Network speed (up/down) with IP and VPN
- `ssh` - SSH session indicator with user@host

**Environment & Context:**
- `weather` - Weather information with temperature coloring
- `music` - Now playing with progress bar
- `datetime` - Date and time with timezone

**Session & Meta:**
- `clients` - Number of attached tmux clients
- `sync` - Pane synchronization indicator

**Note:** Only widgets included in the order will be displayed. This allows you to completely customize your status bar layout.

### Minimal Mode

Create a lightweight tmux session without widgets. Perfect for SSH sessions or resource-constrained environments.

```bash
set -g @tokyo-night-tmux_minimal_session "minimal"
```

When you create a session with this name (e.g., `tmux new-session -s minimal`), all widgets will be disabled automatically.

### Number styles

Run these commands in your terminal:

```bash
tmux set @tokyo-night-tmux_window_id_style digital
tmux set @tokyo-night-tmux_pane_id_style hsquare
tmux set @tokyo-night-tmux_zoom_id_style dsquare
```

Alternatively, add these lines to your  `.tmux.conf`:

```bash
set -g @tokyo-night-tmux_window_id_style digital
set -g @tokyo-night-tmux_pane_id_style hsquare
set -g @tokyo-night-tmux_zoom_id_style dsquare
```


### Widgets

For widgets add following lines in you `.tmux.conf`

#### Date and Time widget

This widget is enabled by default. To disable it:

```bash
set -g @tokyo-night-tmux_show_datetime 0
set -g @tokyo-night-tmux_date_format YMD
set -g @tokyo-night-tmux_time_format 24H
```

##### Available Options

**Date formats:**
- `YMD`: (Year Month Day), 2024-01-31
- `MDY`: (Month Day Year), 01-31-2024
- `DMY`: (Day Month Year), 31-01-2024
- `hide`: Hide date completely

**Time formats:**
- `24H`: 18:30 (default)
- `12H`: 6:30 PM
- `hide`: Hide time completely

##### Timezone Support

Display additional timezones alongside your local time:

```bash
set -g @tokyo-night-tmux_show_timezone 1
set -g @tokyo-night-tmux_timezone "America/Los_Angeles,America/New_York,Europe/London"
```

**Features:**
- **Multiple timezones:** Comma-separated list
- **Auto abbreviation:** Shows PST, EST, GMT, etc.
- **Visual indicator:** 󰥔 icon for each timezone
- **Color coded:** Blue for timezone display

**Example output:**
```
2024-11-12 ❬ 18:30 󰥔 PST 15:30 󰥔 EST 18:30 󰥔 GMT 23:30
```

**Common timezones:**
- Americas: `America/New_York`, `America/Chicago`, `America/Los_Angeles`, `America/Sao_Paulo`
- Europe: `Europe/London`, `Europe/Paris`, `Europe/Berlin`, `Europe/Moscow`
- Asia: `Asia/Tokyo`, `Asia/Shanghai`, `Asia/Dubai`, `Asia/Kolkata`
- Pacific: `Australia/Sydney`, `Pacific/Auckland`

See [TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for complete list.

#### Now Playing widget

```bash
set -g @tokyo-night-tmux_show_music 1
```

**Supported music players:**
- **Linux:** [playerctl](https://github.com/altdesktop/playerctl) - Universal media player controller
- **macOS:** [media-control](https://github.com/ungive/media-control) - Modern alternative to nowplaying-cli

**Installation:**
```bash
# macOS
brew tap ungive/media-control
brew install media-control

# Linux
apt-get install playerctl  # Ubuntu/Debian
pacman -S playerctl        # Arch
```

**Features:**
- Shows artist and song title
- Progress bar with time display
- Pause/play state indicator
- No jq dependency (uses pure shell parsing)

#### Netspeed widget
![Snap netspeed](snaps/netspeed.png)

```bash
set -g @tokyo-night-tmux_show_netspeed 1
set -g @tokyo-night-tmux_netspeed_iface "wlan0"     # Detected via default route
set -g @tokyo-night-tmux_netspeed_showip 1          # Display IPv4 address (default: 0)
set -g @tokyo-night-tmux_netspeed_showping 1        # Display ping latency (default: 0)
set -g @tokyo-night-tmux_netspeed_refresh 1         # Update interval in seconds (default: 1)
set -g @tokyo-night-tmux_netspeed_show_vpn 1        # Show VPN indicator (default: 1)
set -g @tokyo-night-tmux_netspeed_vpn_verbose 0     # Show VPN interface name (default: 0)
```

**Features:**
- **Network speed:** Upload/download with icons
- **Interface type:** Auto-detects WiFi vs Ethernet
- **VPN detection:** Detects active VPN connections (utun, tun, tap, WireGuard, Tailscale, NordLynx)
- **IP display:** Shows current IPv4 address
- **Ping monitor:** Shows latency to 8.8.8.8 with color coding
  - 🟢 Cyan (<50ms): Excellent
  - 🔵 Blue (50-99ms): Good
  - 🟡 Yellow (100-199ms): Fair
  - 🔴 Red (≥200ms): Poor
- **Smart caching:** Ping cached for 10s to avoid network spam

#### Path Widget

```bash
set -g @tokyo-night-tmux_show_path 1
set -g @tokyo-night-tmux_path_format relative # 'relative' or 'full'
```

#### CPU Widget

The CPU widget shows real-time CPU usage percentage with dynamic icons and colors based on load.

```bash
set -g @tokyo-night-tmux_show_cpu 1
```

**Features:**
- **Cross-platform:** Works on macOS and Linux without compiled binaries
- **macOS:** Uses `top` command (matches Activity Monitor)
- **Linux:** Reads from `/proc/stat` for accurate CPU usage
- **Smart coloring:**
  - 🔥 Red (≥80%): High CPU usage
  - ⚠️  Yellow (≥50%): Medium CPU usage
  - ❄️  Cyan (<50%): Low CPU usage

**Optional: Load Average**

You can also display the system load average alongside CPU usage:

```bash
set -g @tokyo-night-tmux_show_load_average 1
```

This shows the 1-minute load average next to the CPU percentage.

Set variable value `0` to disable the widget. Remember to restart `tmux` after changing values.

#### Memory Widget

The memory widget shows real-time memory usage percentage with dynamic icons and colors based on load.

```bash
set -g @tokyo-night-tmux_show_memory 1
```

**Features:**
- **Cross-platform:** Works on macOS and Linux without compiled binaries
- **macOS:** Uses `vm_stat` and `sysctl` (matches Activity Monitor)
- **Linux:** Uses `free` command for accurate memory usage
- **Smart coloring:**
  - 🔥 Red (≥80%): Critical memory usage
  - ⚠️  Yellow (≥60%): High memory usage
  - ❄️  Cyan (<60%): Normal memory usage

**Note:** On macOS, the calculation matches iStats Menu's memory calculation (wired + compressed pages only), which represents non-swappable memory actively in use. This excludes active pages that can be freed, providing a more accurate representation of actual memory pressure.

**Optional: Memory Pressure Indicator**

You can also display a memory pressure indicator to show system memory stress:

```bash
set -g @tokyo-night-tmux_show_memory_pressure 1
```

This shows a colored dot (●) after the percentage:
- **macOS:** Based on swapouts from `vm_stat`
  - 🟢 Green: No pressure (< 1M swapouts)
  - 🟡 Yellow: Medium pressure (1M - 5M swapouts)
  - 🔴 Red: Critical pressure (> 5M swapouts)
- **Linux:** Based on PSI (Pressure Stall Information) or swap usage
  - 🟢 Green: No pressure (< 10%)
  - 🟡 Yellow: Medium pressure (10% - 50%)
  - 🔴 Red: Critical pressure (> 50%)

Set variable value `0` to disable the widget. Remember to restart `tmux` after changing values.

#### Disk Widget

The disk widget shows disk usage percentage with 4 levels of warning indicators.

```bash
set -g @tokyo-night-tmux_show_disk 1
set -g @tokyo-night-tmux_disk_path "/"  # Path to monitor (default: /)
```

**Features:**
- **4-level warnings** (more granular than other widgets):
  - 🟢 Cyan (<50%): Normal
  - 🔵 Blue (50-74%): Moderate
  - 🟡 Yellow (75-89%): High
  - 🔴 Red (≥90%): Critical
- **Configurable path:** Monitor /, /home, or any mount point
- **Cross-platform:** Works on macOS and Linux

Set variable value `0` to disable the widget.

#### GPU Widget

The GPU widget shows GPU usage percentage with support for multiple GPU types.

```bash
set -g @tokyo-night-tmux_show_gpu 1
```

**Supported GPUs:**
- **Apple Silicon** (M1/M2/M3): Estimates from WindowServer activity
- **NVIDIA:** Via `nvidia-smi` command
- **AMD:** Via `rocm-smi` command
- **Intel:** Detection support (limited data availability)

**Auto-detection:** The widget automatically detects your GPU type and shows usage accordingly.

**Note:** For NVIDIA/AMD, ensure drivers and monitoring tools are installed. Apple Silicon works out of the box.

Set variable value `0` to disable the widget.

#### RAM Widget

Alternative to memory widget that shows RAM in GB/TB format instead of percentage.

```bash
set -g @tokyo-night-tmux_show_ram 1
```

**Difference from Memory Widget:**
- **Memory Widget:** Shows percentage (e.g., `25%`)
- **RAM Widget:** Shows absolute values (e.g., `8G/32G`)

Choose one based on preference. Both use the same underlying calculation.

**Features:**
- Cross-platform (macOS + Linux)
- Dynamic coloring based on usage
- Automatic unit conversion (GB/TB)

Set variable value `0` to disable the widget.

#### Weather Widget

The weather widget shows current weather with temperature-based coloring and caching.

```bash
set -g @tokyo-night-tmux_show_weather 1
set -g @tokyo-night-tmux_weather_location ""        # Leave empty for auto-location
set -g @tokyo-night-tmux_weather_format "%t"        # %t=temp, %c=condition, %C=detailed
set -g @tokyo-night-tmux_weather_units "m"          # m=metric, u=US, M=SI
set -g @tokyo-night-tmux_weather_show_icon 1
```

**Features:**
- **Smart caching:** Updates every 15 minutes to reduce API calls
- **Temperature coloring:**
  - 🔴 Red (≥30°C): Very hot
  - 🟡 Yellow (20-29°C): Warm
  - 🔵 Cyan (10-19°C): Cool
  - 🔵 Blue (0-9°C): Cold
  - 🟣 Magenta (<0°C): Freezing
- **Powered by wttr.in:** No API key required
- **Requires:** curl or wget

Set variable value `0` to disable the widget.

#### SSH Session Widget

Shows SSH session information with user@hostname and optional port.

```bash
set -g @tokyo-night-tmux_show_ssh 1
set -g @tokyo-night-tmux_ssh_only_when_connected 1  # Only show when SSH active
set -g @tokyo-night-tmux_ssh_show_port 0            # Show port if non-standard
```

**Features:**
- Auto-detects SSH sessions
- Shows user@hostname format
- Optional port display (for non-22 ports)
- Color changes when SSH active (cyan → green)
- Can show always or only during SSH

Set variable value `0` to disable the widget.

#### Attached Clients Widget

Shows number of clients attached to the tmux session.

```bash
set -g @tokyo-night-tmux_show_clients 1
set -g @tokyo-night-tmux_clients_minimum 2  # Only show if >= this many clients
```

**Use case:** Useful when pair programming or when multiple terminals connect to the same session.

Set variable value `0` to disable the widget.

#### Pane Synchronization Widget

Shows indicator when pane synchronization is active (Prefix + S).

```bash
set -g @tokyo-night-tmux_show_sync 1
set -g @tokyo-night-tmux_sync_label "SYNC"  # Customize label
```

**Features:**
- Only appears when panes are synchronized
- Visual warning to prevent accidental commands to all panes
- Customizable label text

Set variable value `0` to disable the widget.

#### Battery Widget

```bash
set -g @tokyo-night-tmux_show_battery_widget 1
set -g @tokyo-night-tmux_battery_name "BAT1"  # some linux distro have 'BAT0'
set -g @tokyo-night-tmux_battery_low_threshold 21 # default
```

Set variable value `0` to disable the widget. Remember to restart `tmux` after
changing values.

#### Git Status Widget

The git status widget shows local git repository information including branch name, changed files, insertions, deletions, and sync status with remote.

```bash
set -g @tokyo-night-tmux_show_git 1
set -g @tokyo-night-tmux_git_check_untracked 1  # Check untracked files (default: 1)
```

**Options:**
- **git_check_untracked:** Enable/disable checking for untracked files
  - Set to `0` to disable in large repositories for better performance
  - When disabled, the  icon (untracked files) won't appear
  - Recommended to disable in monorepos or repos with many build artifacts

##### Performance Options for Large Repositories

To prevent performance issues in large repositories, you can configure auto-fetch behavior:

```bash
# Disable automatic git fetch (recommended for very large repos)
set -g @tokyo-night-tmux_git_disable_auto_fetch 1

# Set fetch timeout in seconds (default: 5)
set -g @tokyo-night-tmux_git_fetch_timeout 10
```

**Note:** The auto-fetch runs in background with timeout to prevent blocking. If you work with very large repositories and experience slowdowns, disable auto-fetch and manually fetch when needed.

Set variable value `0` to disable the widget. Remember to restart `tmux` after changing values.

#### Web-based Git Widget

This widget shows GitHub/GitLab statistics including PR counts and issues assigned to you. It requires `gh` (GitHub CLI) or `glab` (GitLab CLI) to be installed and authenticated.

```bash
set -g @tokyo-night-tmux_show_wbg 1
```

The widget works with both SSH and HTTPS git remote URLs:
- SSH: `git@github.com:user/repo.git`
- HTTPS: `https://github.com/user/repo.git`

Set variable value `0` to disable the widget. Remember to restart `tmux` after changing values.

## Styles

- `none`: no style, default font
- `digital`: 7 segment number (🯰...🯹) (needs [Unicode support](https://github.com/janoamaral/tokyo-night-tmux/issues/36#issuecomment-1907072080))
- `roman`: roman numbers (󱂈...󱂐) (needs nerdfont)
- `fsquare`: filled square (󰎡...󰎼) (needs nerdfont)
- `hsquare`: hollow square (󰎣...󰎾) (needs nerdfont)
- `dsquare`: hollow double square (󰎡...󰎼) (needs nerdfont)
- `super`: superscript symbol (⁰...⁹)
- `sub`: subscript symbols (₀...₉)

### New tokyonight Highlights ⚡

Everything works out the box now. No need to modify anything and colors are hardcoded,
so it's independent of terminal theme.

- Local git stats.
- Web based git server (GitHub/GitLab) stats.
  - Open PR count
  - Open PR reviews count
  - Issue count
- Remote branch sync indicator (you will never forget to push or pull again 🤪).
- Great terminal icons.
- Prefix highlight incorporated.
- Now Playing status bar, supporting [playerctl]/[nowplaying-cli]
- Windows has custom pane number indicator.
- Pane zoom mode indicator.
- Date and time.

#### TODO

- Add configurations
  - remote fetch time
  - ~number styles~
  - indicators order
  - disable indicators

### Demo

https://github.com/janoamaral/tokyo-night-tmux/assets/10008708/59ecd814-bc2b-47f2-82b1-ffdbfbc54fbf

### Snapshots

- Terminal: Kitty with [Tokyo Night Kitty Theme](https://github.com/davidmathers/tokyo-night-kitty-theme)
- Font: [SFMono Nerd Font Ligaturized](https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized)

![Snap 5](snaps/logico.png)

Legacy tokyo-night

![Snap 4](snaps/l01.png)

## Contributing

> [!IMPORTANT]  
> Please read the [contribution guide first](CONTRIBUTING.md).

Feel free to open an issue or pull request with any suggestions or improvements.

Ensure your editor follows the style guide provided by `.editorconfig`.
[pre-commit] hooks are also provided to ensure code consistency, and will be
run against any raised PRs.

[pre-commit]: https://pre-commit.com/
[Noto Sans]: https://fonts.google.com/noto/specimen/Noto+Sans
[Nerd Fonts]: https://www.nerdfonts.com/
[coreutils]: https://www.gnu.org/software/coreutils/
[bc]: https://www.gnu.org/software/bc/
[jq]: https://jqlang.github.io/jq/
[playerctl]: https://github.com/altdesktop/playerctl
[nowplaying-cli]: https://github.com/kirtan-shah/nowplaying-cli
[Homebrew]: https://brew.sh/
