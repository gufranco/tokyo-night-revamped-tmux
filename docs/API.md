# API Documentation

This document describes all public functions available in Tokyo Night Revamped Tmux that can be used to create custom widgets or extend functionality.

## 📋 Table of Contents

- [Platform Detection](#platform-detection)
- [System Metrics](#system-metrics)
- [Git Operations](#git-operations)
- [Network Operations](#network-operations)
- [UI Components](#ui-components)
- [Caching](#caching)
- [Utilities](#utilities)
- [Widget Framework](#widget-framework)

---

## Platform Detection

### `get_os()`

**Description**: Returns the operating system name.

**Returns**: `Darwin` (macOS) or `Linux`

**Example**:
```bash
source src/lib/utils/platform-cache.sh

os=$(get_os)
if [[ "$os" == "Darwin" ]]; then
  echo "Running on macOS"
fi
```

---

### `get_arch()`

**Description**: Returns the CPU architecture.

**Returns**: `arm64`, `x86_64`, `aarch64`, etc.

**Example**:
```bash
arch=$(get_arch)
echo "Architecture: $arch"
```

---

### `is_apple_silicon()`

**Description**: Checks if running on Apple Silicon.

**Returns**: `0` if true, `1` if false

**Example**:
```bash
if is_apple_silicon; then
  echo "Apple Silicon detected"
fi
```

---

## System Metrics

### `get_cpu_usage_percentage()`

**Description**: Gets current CPU usage as a percentage.

**Returns**: Integer `0-100`

**Example**:
```bash
source src/lib/cpu/cpu.sh

cpu_usage=$(get_cpu_usage_percentage)
echo "CPU: ${cpu_usage}%"
```

---

### `get_cpu_count()`

**Description**: Gets the number of CPU cores.

**Returns**: Integer (number of cores)

**Example**:
```bash
cores=$(get_cpu_count)
echo "CPU Cores: $cores"
```

---

### `get_cpu_temperature()`

**Description**: Gets CPU temperature in Celsius.

**Returns**: Integer (temperature) or `0` if not available

**Platform**: macOS (requires `istats`/`osx-cpu-temp`), Linux (requires `sensors`)

**Example**:
```bash
temp=$(get_cpu_temperature)
if [[ $temp -gt 0 ]]; then
  echo "CPU Temp: ${temp}°C"
fi
```

---

### `get_total_memory_kb()`

**Description**: Gets total system memory in kilobytes.

**Returns**: Integer (KB)

**Example**:
```bash
source src/lib/ram/ram.sh

total_mem=$(get_total_memory_kb)
total_gb=$((total_mem / 1024 / 1024))
echo "Total Memory: ${total_gb}GB"
```

---

### `get_active_memory_kb()`

**Description**: Gets active/used memory in kilobytes.

**Returns**: Integer (KB)

**Example**:
```bash
active_mem=$(get_active_memory_kb)
total_mem=$(get_total_memory_kb)
usage=$((active_mem * 100 / total_mem))
echo "Memory Usage: ${usage}%"
```

---

### `get_gpu_usage_percentage()`

**Description**: Gets GPU usage as a percentage.

**Returns**: Integer `0-100`

**Platform**: macOS (Apple Silicon), Linux (NVIDIA, AMD, Intel)

**Example**:
```bash
source src/lib/gpu/gpu.sh

gpu_usage=$(get_gpu_usage_percentage)
echo "GPU: ${gpu_usage}%"
```

---

### `get_disk_usage(path)`

**Description**: Gets disk usage percentage for a given path.

**Parameters**:
- `path` - Path to check (default: `/`)

**Returns**: Integer `0-100`

**Example**:
```bash
source src/lib/disk/disk.sh

disk_usage=$(get_disk_usage "/")
echo "Disk: ${disk_usage}%"
```

---

## Git Operations

### `is_git_repository(path)`

**Description**: Checks if a path is a git repository.

**Parameters**:
- `path` - Path to check

**Returns**: `0` if true, `1` if false

**Example**:
```bash
source src/lib/git/git.sh

if is_git_repository "$(pwd)"; then
  echo "This is a git repository"
fi
```

---

### `get_git_branch(path)`

**Description**: Gets the current git branch name.

**Parameters**:
- `path` - Repository path

**Returns**: Branch name or empty string

**Example**:
```bash
branch=$(get_git_branch "$(pwd)")
echo "Current branch: $branch"
```

---

### `get_git_status_counts(path)`

**Description**: Gets counts of git changes.

**Parameters**:
- `path` - Repository path

**Returns**: Space-separated counts: `modified staged untracked`

**Example**:
```bash
read modified staged untracked <<< "$(get_git_status_counts "$(pwd)")"
echo "Modified: $modified, Staged: $staged, Untracked: $untracked"
```

---

### `is_remote_ahead(path)`

**Description**: Checks if remote is ahead of local.

**Parameters**:
- `path` - Repository path

**Returns**: `0` if true, `1` if false

**Example**:
```bash
if is_remote_ahead "$(pwd)"; then
  echo "Remote has new commits"
fi
```

---

## Network Operations

### `get_default_network_interface()`

**Description**: Gets the default network interface name.

**Returns**: Interface name (e.g., `en0`, `eth0`)

**Example**:
```bash
source src/lib/network/network.sh

iface=$(get_default_network_interface)
echo "Default interface: $iface"
```

---

### `get_interface_ipv4(interface)`

**Description**: Gets IPv4 address for an interface.

**Parameters**:
- `interface` - Interface name

**Returns**: IP address or empty string

**Example**:
```bash
ip=$(get_interface_ipv4 "en0")
echo "IP Address: $ip"
```

---

### `detect_vpn()`

**Description**: Detects if VPN is active and returns interface name.

**Returns**: VPN interface name or empty string

**Example**:
```bash
source src/lib/network/network-utils.sh

vpn=$(detect_vpn)
if [[ -n "$vpn" ]]; then
  echo "VPN active on: $vpn"
fi
```

---

## UI Components

### `get_percentage_color(value, max_normal, max_moderate, max_high)`

**Description**: Gets color based on percentage thresholds.

**Parameters**:
- `value` - Current value
- `max_normal` - Threshold for normal (cyan)
- `max_moderate` - Threshold for moderate (blue)
- `max_high` - Threshold for high (yellow)
- Above `max_high` returns red

**Returns**: Tmux color format string

**Example**:
```bash
source src/lib/ui/color-scale.sh

color=$(get_percentage_color "75" "49" "74" "89")
echo "${color}75%#[default]"
```

---

### `get_system_color(percentage)`

**Description**: Gets color for system metrics (CPU, Memory, etc.).

**Parameters**:
- `percentage` - Usage percentage `0-100`

**Returns**: Tmux color format string

**Example**:
```bash
cpu=85
color=$(get_system_color "$cpu")
echo "${color}CPU: ${cpu}%#[default]"
```

---

### `format_segment(content, fg_color, bg_color)`

**Description**: Formats a status bar segment.

**Parameters**:
- `content` - Segment content
- `fg_color` - Foreground color (hex)
- `bg_color` - Background color (hex or `default`)

**Returns**: Formatted segment string

**Example**:
```bash
source src/lib/ui/ui.sh

segment=$(format_segment " CPU 75% " "#7dcfff" "default")
echo "$segment"
```

---

### `format_icon(icon, color)`

**Description**: Formats an icon with color.

**Parameters**:
- `icon` - Icon character/string
- `color` - Color (hex)

**Returns**: Formatted icon string

**Example**:
```bash
icon=$(format_icon "󰾆" "#7dcfff")
echo "$icon"
```

---

### `pad_percentage(value)`

**Description**: Pads a percentage value for consistent width.

**Parameters**:
- `value` - Percentage value

**Returns**: Padded string (e.g., " 75%" or "100%")

**Example**:
```bash
source src/lib/ui/format.sh

padded=$(pad_percentage "75")
echo "$padded"  # Outputs: " 75%"
```

---

## Caching

### `get_cached_value(key)`

**Description**: Gets a cached value.

**Parameters**:
- `key` - Cache key

**Returns**: Cached value or empty string

**Example**:
```bash
source src/lib/utils/cache.sh

value=$(get_cached_value "cpu_usage")
if [[ -n "$value" ]]; then
  echo "Cached: $value"
fi
```

---

### `set_cached_value(key, value)`

**Description**: Sets a cache value.

**Parameters**:
- `key` - Cache key
- `value` - Value to cache

**Example**:
```bash
cpu=$(get_cpu_usage_percentage)
set_cached_value "cpu_usage" "$cpu"
```

---

### `is_cache_valid(key, ttl)`

**Description**: Checks if cache is still valid.

**Parameters**:
- `key` - Cache key
- `ttl` - Time to live in seconds (optional, uses default refresh rate)

**Returns**: `0` if valid, `1` if expired

**Example**:
```bash
if is_cache_valid "cpu_usage" 5; then
  value=$(get_cached_value "cpu_usage")
else
  value=$(get_cpu_usage_percentage)
  set_cached_value "cpu_usage" "$value"
fi
```

---

### `invalidate_cache(key)`

**Description**: Invalidates a cache entry.

**Parameters**:
- `key` - Cache key

**Example**:
```bash
invalidate_cache "cpu_usage"
```

---

## Utilities

### `safe_divide(numerator, denominator, default)`

**Description**: Safely divides two numbers.

**Parameters**:
- `numerator` - Number to divide
- `denominator` - Divide by
- `default` - Default value if division fails (optional, default: `0`)

**Returns**: Result or default

**Example**:
```bash
source src/lib/utils/system.sh

result=$(safe_divide "100" "0" "999")
echo "$result"  # Outputs: 999
```

---

### `clamp_value(value, min, max)`

**Description**: Clamps a value between min and max.

**Parameters**:
- `value` - Value to clamp
- `min` - Minimum value
- `max` - Maximum value

**Returns**: Clamped value

**Example**:
```bash
clamped=$(clamp_value "150" "0" "100")
echo "$clamped"  # Outputs: 100
```

---

### `validate_percentage(value)`

**Description**: Validates and clamps a percentage value.

**Parameters**:
- `value` - Value to validate

**Returns**: Integer `0-100`

**Example**:
```bash
percentage=$(validate_percentage "150")
echo "$percentage"  # Outputs: 100
```

---

### `retry_with_backoff(cmd, max_attempts, initial_delay, max_delay, multiplier)`

**Description**: Retries a command with exponential backoff.

**Parameters**:
- `cmd` - Command to execute
- `max_attempts` - Maximum retry attempts (default: `3`)
- `initial_delay` - Initial delay in seconds (default: `1`)
- `max_delay` - Maximum delay in seconds (default: `30`)
- `multiplier` - Backoff multiplier (default: `2`)

**Returns**: `0` on success, `1` on failure

**Example**:
```bash
source src/lib/utils/retry.sh

if retry_with_backoff "curl -s https://api.github.com" 3 1 5 2; then
  echo "API call succeeded"
else
  echo "API call failed after retries"
fi
```

---

## Widget Framework

### `is_widget_enabled(option)`

**Description**: Checks if a widget is enabled.

**Parameters**:
- `option` - Tmux option name

**Returns**: `0` if enabled, `1` if disabled

**Example**:
```bash
source src/lib/widget/widget-base.sh

if is_widget_enabled "@tokyo-night-tmux_show_git"; then
  echo "Git widget enabled"
fi
```

---

### `is_minimal_session()`

**Description**: Checks if current session is a minimal session.

**Returns**: `0` if minimal, `1` if normal

**Example**:
```bash
if is_minimal_session; then
  exit 0  # Skip widget
fi
```

---

### `get_tmux_option(option, default)`

**Description**: Gets a tmux option value.

**Parameters**:
- `option` - Option name
- `default` - Default value if not set

**Returns**: Option value or default

**Example**:
```bash
source src/lib/tmux/tmux-config.sh

refresh=$(get_tmux_option "@tokyo-night-tmux_refresh_rate" "5")
echo "Refresh rate: ${refresh}s"
```

---

## Creating Custom Widgets

### Example: Simple CPU Widget

```bash
#!/usr/bin/env bash

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/widget/widget-loader.sh"

# Early exit checks
is_minimal_session && exit 0
is_widget_enabled "@tokyo-night-tmux_show_cpu" || exit 0

# Check cache
cache_key="custom_cpu"
if is_cache_valid "$cache_key"; then
  get_cached_value "$cache_key"
  exit 0
fi

# Get metric
cpu_usage=$(get_cpu_usage_percentage)

# Format output
color=$(get_system_color "$cpu_usage")
icon=$(format_icon "󰾆" "#7dcfff")
output="${icon} ${color}$(pad_percentage "$cpu_usage")#[default]"

# Cache and display
set_cached_value "$cache_key" "$output"
echo "$output"
```

---

## Best Practices

1. **Always check cache first** - Reduces system calls
2. **Use early exits** - Skip unnecessary work
3. **Validate inputs** - Use `validate_percentage`, `safe_divide`, etc.
4. **Handle errors gracefully** - Return sensible defaults
5. **Export functions** - Use `export -f function_name` for sourced scripts
6. **Use retry logic** - For external API calls
7. **Sanitize inputs** - Remove special characters
8. **Check platform** - Use `get_os()`, `is_apple_silicon()`

---

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [CUSTOM_WIDGETS.md](CUSTOM_WIDGETS.md) - Widget development guide
- [README.md](../README.md) - Main documentation

---

## Need Help?

- [Report an Issue](https://github.com/gufranco/tokyo-night-revamped-tmux/issues)
- [Ask a Question](https://github.com/gufranco/tokyo-night-revamped-tmux/discussions)

