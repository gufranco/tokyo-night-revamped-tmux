# Tokyo Night Revamped Tmux

![Tmux](https://img.shields.io/badge/tmux-3.0+-blue.svg)
![Bash](https://img.shields.io/badge/bash-4.2+-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)

A beautiful, feature-rich tmux theme inspired by the vibrant lights of Downtown Tokyo at night.  
Perfect companion for [tokyonight-vim](https://github.com/ghifarit53/tokyonight-vim) and adapted from the original [Tokyo Night VSCode theme](https://github.com/enkia/tokyo-night-vscode-theme).

**Quick Links:** [Features](#-features) • [Installation](#-installation) • [Configuration](#-configuration) • [Widgets](#-widgets) • [Contributing](#-contributing)

---

## ✨ Features

### 🎨 **Beautiful Design**
- Clean, minimalist interface with Tokyo Night color scheme
- Dynamic icons that change based on resource usage
- Color-coded metrics for quick visual feedback
- Professional appearance suitable for development environments

### 🚀 **High Performance**
- Pure bash implementation - no compiled binaries required
- Smart caching system reduces system calls
- Efficient resource monitoring
- Background processing for long-running operations

### 📊 **Rich Widgets**
- **System Monitoring**: CPU, GPU, Memory, Swap, Disk, Battery
- **Git Integration**: Local repository status + GitHub/GitLab web stats
- **Network Stats**: Real-time upload/download speeds, VPN detection, ping latency
- **Context Information**: Date/time, timezone support, path, SSH sessions
- **Weather**: Current temperature with dynamic icons

### 🔧 **Highly Customizable**
- Flexible widget ordering system
- Individual component toggles
- Multiple number style options
- Minimal mode for lightweight sessions
- Extensive configuration options

### 🌍 **Cross-Platform**
- Works seamlessly on macOS (Apple Silicon & Intel) and Linux
- Platform-specific optimizations
- Automatic fallbacks for missing tools
- No external dependencies required for core functionality

### 🎯 **Developer-Focused**
- Built by developers, for developers
- Accurate metrics matching Activity Monitor / iStats
- Git workflow integration
- Professional tooling support

---

## 📋 Requirements

### Hard Requirements

- **tmux** 3.0 or higher
- **Bash** 4.2 or higher
- **Nerd Fonts** v3 or higher ([Installation Guide](https://www.nerdfonts.com/))

> **Note for macOS users**: macOS ships with Bash 3.2. You must install a newer version via Homebrew.

### Optional Dependencies

These are only required for specific features:

| Tool | Purpose | Installation |
|------|---------|-------------|
| `git` | Git widget (local repository status) | Usually pre-installed |
| `gh` | GitHub integration (PRs, issues, reviews) | `brew install gh` / `apt install gh` |
| `glab` | GitLab integration (MRs, issues) | `brew install glab` / `apt install glab` |
| `jq` | JSON parsing for GitHub/GitLab features | `brew install jq` / `apt install jq` |
| `curl` / `wget` | Weather widget | Usually pre-installed |
| `ip` / `ifconfig` | Network widget (Linux) | Usually pre-installed |
| `free` | Swap monitoring (Linux) | Usually pre-installed |

---

## 🚀 Installation

### Using TPM (Tmux Plugin Manager) - Recommended

Add to your `~/.tmux.conf`:

```bash
set -g @plugin "gufranco/tokyo-night-revamped-tmux"
```

Then press `Prefix + I` to install the plugin.

### Manual Installation

```bash
git clone https://github.com/gufranco/tokyo-night-revamped-tmux.git ~/.tmux/plugins/tokyo-night-revamped-tmux
```

Add to `~/.tmux.conf`:

```bash
run-shell ~/.tmux/plugins/tokyo-night-revamped-tmux/tokyo-night.tmux
```

### Reload Configuration

After installation, reload your tmux configuration:

```bash
tmux source-file ~/.tmux.conf
```

Or press `Prefix + :` and type `source-file ~/.tmux.conf`

---

## ⚙️ Configuration

### Widget Ordering

Customize which widgets appear and in what order:

```bash
# Default order
set -g @tokyo-night-tmux_widgets_order "system,git,netspeed,context"

# Developer-focused setup
set -g @tokyo-night-tmux_widgets_order "system,git,context"

# System monitoring setup
set -g @tokyo-night-tmux_widgets_order "system,netspeed,context"

# Minimal setup
set -g @tokyo-night-tmux_widgets_order "git,context"
```

**Available widgets:**
- `system` - Unified system metrics (CPU, GPU, Memory, Disk, Battery)
- `git` - Git repository status with web integration
- `netspeed` - Network speed and connectivity
- `context` - Date, time, path, SSH, and more

### Minimal Mode

Create lightweight tmux sessions without widgets:

```bash
set -g @tokyo-night-tmux_minimal_session "minimal"
```

When you create a session with this name (e.g., `tmux new-session -s minimal`), all widgets will be automatically disabled.

### Number Styles

Customize window and pane number display:

```bash
set -g @tokyo-night-tmux_window_id_style digital
set -g @tokyo-night-tmux_pane_id_style hsquare
set -g @tokyo-night-tmux_zoom_id_style dsquare
```

**Available styles:**
- `none` - Default numbers (0-9)
- `digital` - 7-segment display (🯰...🯹)
- `roman` - Roman numerals (󱂈...󱂐)
- `fsquare` - Filled squares (󰎡...󰎼)
- `hsquare` - Hollow squares (󰎣...󰎾)
- `dsquare` - Double squares (󰎢...󰎽)
- `super` - Superscript (⁰...⁹)
- `sub` - Subscript (₀...₉)

---

## 📊 Widgets

### System Widget (Unified)

**Recommended**: All system metrics in one clean, unified widget.

```bash
# Master toggle
set -g @tokyo-night-tmux_show_system 1

# Component toggles (all enabled by default)
set -g @tokyo-night-tmux_system_cpu 1
set -g @tokyo-night-tmux_system_gpu 1
set -g @tokyo-night-tmux_system_memory 1
set -g @tokyo-night-tmux_system_swap 1
set -g @tokyo-night-tmux_system_disk 1
set -g @tokyo-night-tmux_system_battery 1

# Optional: Load average
set -g @tokyo-night-tmux_system_load 1

# Configuration
set -g @tokyo-night-tmux_system_disk_path "/"
set -g @tokyo-night-tmux_system_battery_threshold 20
```

**Features:**
- **Dynamic Icons**: Icons change gradually based on usage percentage (11 levels)
- **Dynamic Colors**: Colors scale from cyan → yellow → red based on usage
- **Accurate Metrics**: 
  - macOS: Matches Activity Monitor / iStats calculations
  - GPU: Uses `ioreg` Device Utilization % (same as iStats) with WindowServer fallback
  - Memory: Wired + compressed (macOS) or active memory (Linux)
- **Minimalist Design**: All cyan by default, colors only when needed
- **Cross-Platform**: Works on macOS and Linux

**Components:**
- **CPU** (󰾆): User + system CPU usage
- **GPU** (󰢮): GPU usage (Apple Silicon via `ioreg` or WindowServer fallback)
- **Memory** (󰍛): Active memory usage
- **Swap** (󰾴): Swap usage (only shown if > 0)
- **Disk** (󰋊): Disk usage percentage
- **Battery** (󰚥): 11-level battery indicator with charging state
- **Load** (󰧑): System load average (optional)

**Color Scale:**
- 🟢 **Cyan** (< 50%): Normal usage
- 🟡 **Yellow** (50-79%): Moderate usage
- 🔴 **Red** (≥ 80%): High usage

**Battery Alert**: Icon and percentage blink in RED when below threshold (default: 20%)

### Git Widget

Unified Git widget with local repository status and web integration (GitHub/GitLab).

```bash
set -g @tokyo-night-tmux_show_git 1
set -g @tokyo-night-tmux_git_untracked 1
set -g @tokyo-night-tmux_git_web 1
```

**Local Features:**
- **Branch**: Current branch name (truncated at 25 characters)
- **Sync Status**: 
  - 󱓎 Local changes
  - 󰛃 Need push
  - Clean (synced)
- **Changes**: 󰄴 Modified files count (dynamic icons)
- **Insertions**: 󰐕 Lines added (dynamic icons)
- **Deletions**: 󰍵 Lines removed (dynamic icons)
- **Untracked**: 󰋗 New files (optional, dynamic icons)

**Web Features** (requires `gh` or `glab` + `jq`):
- **Auto-detection**: Automatically detects GitHub or GitLab repositories
- **PRs/MRs**: 󰊤 Open pull requests (green, dynamic icons)
- **Reviews**: 󰭎 Reviews needed (yellow, dynamic icons)
- **Issues**: 󰀨 Assigned issues (magenta, dynamic icons)
- **Bugs**: 󰃤 Bug issues (red)

**Dynamic Icons**: Icons change based on count thresholds for better visual feedback.

**Performance Options:**

```bash
# Disable auto-fetch for large repositories
set -g @tokyo-night-tmux_git_disable_auto_fetch 1

# Set fetch timeout (default: 5 seconds)
set -g @tokyo-night-tmux_git_fetch_timeout 10
```

### Network Widget

Professional network monitoring with clean, minimalist design.

```bash
set -g @tokyo-night-tmux_show_netspeed 1
set -g @tokyo-night-tmux_netspeed_ping 1      # Show ping latency
set -g @tokyo-night-tmux_netspeed_vpn 1       # Show VPN indicator
set -g @tokyo-night-tmux_netspeed_refresh 1   # Update interval (seconds)
```

**Features:**
- **Download/Upload**: Real-time speeds (KB/s, MB/s)
- **VPN Detection**: 󰌘 Icon when VPN active
  - Supports: utun, tun, tap, WireGuard, Tailscale, NordLynx
- **Ping Latency**: 󰓅 ms (optional, color-coded)
- **Auto-detect**: No manual interface configuration needed
- **Pure Bash**: No external dependencies for calculations

**Color Coding:**
- Ping < 50ms: Green
- Ping 50-100ms: Yellow
- Ping > 100ms: Red

### Context Widget

Date, time, path, SSH, and session information.

```bash
set -g @tokyo-night-tmux_show_context 1
```

**Components:**

#### Date and Time

```bash
set -g @tokyo-night-tmux_show_datetime 1
set -g @tokyo-night-tmux_date_format YMD      # YMD, MDY, DMY, hide
set -g @tokyo-night-tmux_time_format 24H       # 24H, 12H, hide
```

**Date formats:**
- `YMD`: Year-Month-Day (2024-01-31)
- `MDY`: Month-Day-Year (01-31-2024)
- `DMY`: Day-Month-Year (31-01-2024)
- `hide`: Hide date completely

**Time formats:**
- `24H`: 24-hour format (18:30)
- `12H`: 12-hour format (6:30 PM)
- `hide`: Hide time completely

**Timezone Support:**

```bash
set -g @tokyo-night-tmux_show_timezone 1
set -g @tokyo-night-tmux_timezone "America/Los_Angeles,America/New_York,Europe/London"
```

Shows abbreviated timezones (PST, EST, GMT) with 󰥔 icon. Supports multiple timezones.

#### Path

```bash
set -g @tokyo-night-tmux_show_path 1
set -g @tokyo-night-tmux_path_format relative  # relative or full
```

#### SSH Session

```bash
set -g @tokyo-night-tmux_show_ssh 1
set -g @tokyo-night-tmux_ssh_only_when_connected 1
set -g @tokyo-night-tmux_ssh_show_port 0
```

Shows `user@hostname` format, changes color when SSH active.

#### Other Context Widgets

```bash
# Attached clients count
set -g @tokyo-night-tmux_show_clients 1
set -g @tokyo-night-tmux_clients_minimum 2

# Pane synchronization indicator
set -g @tokyo-night-tmux_show_sync 1
set -g @tokyo-night-tmux_sync_label "SYNC"

# Weather (requires curl/wget)
set -g @tokyo-night-tmux_show_weather 1
set -g @tokyo-night-tmux_weather_units "m"  # m=metric, u=US, M=SI
set -g @tokyo-night-tmux_weather_show_icon 1
```

---

## 🎨 Theme Highlights

- **Independent Colors**: Hardcoded colors, independent of terminal theme
- **Prefix Highlight**: Visual indicator when prefix key is pressed
- **Window Indicators**: Custom pane numbers and zoom indicators
- **SSH Detection**: Visual feedback for SSH sessions
- **Clean Design**: Minimalist, professional appearance
- **Dynamic Elements**: Icons and colors adapt to system state

---

## 🔧 Advanced Configuration

### Refresh Rates

Control how often widgets update:

```bash
set -g @tokyo-night-tmux_refresh_rate 5  # Update every 5 seconds (default)
```

### Individual System Widgets

If you prefer separate widgets with dynamic colors instead of the unified widget:

```bash
# CPU
set -g @tokyo-night-tmux_show_cpu 1
set -g @tokyo-night-tmux_show_load_average 1

# Memory
set -g @tokyo-night-tmux_show_memory 1
set -g @tokyo-night-tmux_show_memory_pressure 1

# Disk
set -g @tokyo-night-tmux_show_disk 1
set -g @tokyo-night-tmux_disk_path "/"

# GPU
set -g @tokyo-night-tmux_show_gpu 1

# RAM (alternative to memory, shows GB/TB)
set -g @tokyo-night-tmux_show_ram 1

# Battery (standalone)
set -g @tokyo-night-tmux_show_battery_widget 1
set -g @tokyo-night-tmux_battery_name "BAT1"
set -g @tokyo-night-tmux_battery_low_threshold 21
```

---

## 🛠️ Technical Details

### Architecture

- **Pure Bash**: No compiled binaries required
- **Modular Design**: Each widget is independent
- **Efficient Caching**: Reduces system calls and API requests
- **Cross-Platform**: Unified codebase for macOS and Linux
- **Smart Fallbacks**: Graceful degradation when tools are missing

### Performance

- **No External Dependencies**: Uses only standard Unix tools for core functionality
- **Smart Caching**: Widgets cache results to reduce overhead
- **Background Processing**: Long-running operations don't block tmux
- **Optimized Parsing**: Efficient shell-based parsing

### GPU Monitoring (Apple Silicon)

The GPU widget uses the most accurate method available:

1. **Primary Method**: `ioreg` Device Utilization % (same as iStats Menu)
2. **Fallback**: WindowServer CPU estimation with progressive multipliers

This ensures accurate GPU usage reporting that matches professional monitoring tools.

### Compatibility

- **macOS**: 10.14+ (tested on Apple Silicon and Intel)
- **Linux**: All major distributions
- **Bash**: 4.2+ required (macOS needs Homebrew bash)

---

## 🐛 Troubleshooting

### Widgets not showing

1. Check that widgets are enabled in your configuration
2. Verify widgets are included in `@tokyo-night-tmux_widgets_order`
3. Ensure you're not in minimal mode
4. Check tmux logs: `tmux show-messages`

### GPU always shows 1%

- **macOS**: Ensure you're on Apple Silicon (M1/M2/M3)
- Check if `ioreg` is accessible: `ioreg -r -d 1 -w 0 -c "IOAccelerator"`
- Verify WindowServer is running: `ps aux | grep WindowServer`

### Git web features not working

1. Ensure `gh` (GitHub) or `glab` (GitLab) is installed and authenticated
2. Verify `jq` is installed for JSON parsing
3. Check repository remote: `git remote -v`
4. Test manually: `gh pr list` or `glab mr list`

### Performance issues

1. Increase refresh rate: `set -g @tokyo-night-tmux_refresh_rate 10`
2. Disable auto-fetch for large repos: `set -g @tokyo-night-tmux_git_disable_auto_fetch 1`
3. Use minimal mode for SSH sessions
4. Disable unused widgets

### Colors not displaying correctly

1. Ensure you're using a Nerd Font (v3+)
2. Verify terminal supports true color
3. Check tmux version: `tmux -V` (needs 3.0+)

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Read** the [Contributing Guide](CONTRIBUTING.md) first
2. **Follow** the [Code of Conduct](CODE_OF_CONDUCT.md)
3. **Check** existing issues and pull requests
4. **Create** a feature branch from `master`
5. **Test** your changes on both macOS and Linux
6. **Ensure** code follows `.editorconfig` style guide
7. **Submit** a pull request with a clear description

### Development Setup

1. Clone the repository: `git clone https://github.com/gufranco/tokyo-night-revamped-tmux.git`
2. Create a branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly
5. Commit: `git commit -m "Add: your feature"`
6. Push: `git push origin feature/your-feature`
7. Open a Pull Request

[pre-commit](https://pre-commit.com/) hooks are provided for code consistency and will run automatically.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

## 🙏 Acknowledgments

- **Original Theme**: [Tokyo Night VSCode Theme](https://github.com/enkia/tokyo-night-vscode-theme) by enkia
- **Vim Companion**: [tokyonight-vim](https://github.com/ghifarit53/tokyonight-vim) by ghifarit53
- **Icons**: [Nerd Fonts](https://www.nerdfonts.com/) community
- **Inspiration**: Downtown Tokyo at night

---

## 🔗 Links

- [Nerd Fonts](https://www.nerdfonts.com/) - Icon fonts
- [Noto Sans Symbols 2](https://fonts.google.com/noto/specimen/Noto+Sans) - Segmented digits
- [Homebrew](https://brew.sh/) - macOS package manager
- [GitHub CLI](https://cli.github.com/) - GitHub integration
- [GitLab CLI](https://gitlab.com/gitlab-org/cli) - GitLab integration

---

**Made with ❤️ for developers who love beautiful, functional tools.**

