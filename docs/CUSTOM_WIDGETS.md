# Creating Custom Widgets

This guide shows you how to create custom widgets for Tokyo Night Revamped Tmux.

## 📋 Table of Contents

- [Widget Basics](#widget-basics)
- [Widget Template](#widget-template)
- [Step-by-Step Guide](#step-by-step-guide)
- [API Reference](#api-reference)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Debugging](#debugging)

---

## Widget Basics

### What is a Widget?

A widget is a bash script that:
1. Collects data (metrics, status, etc.)
2. Formats the data with colors and icons
3. Returns formatted output to tmux status line

### Widget Lifecycle

```
┌─────────────────────────────────────┐
│  Tmux renders status line           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Execute widget script               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Check if minimal session            │
│  Check if widget enabled             │
│  Check cache validity                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Collect metric/data                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Format output (color, icon)         │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Cache result                        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Return output to tmux               │
└─────────────────────────────────────┘
```

---

## Widget Template

Use this template to create your widget:

```bash
#!/usr/bin/env bash

# 1. Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 2. Source widget loader (loads all dependencies)
source "${PROJECT_ROOT}/src/lib/widget/widget-loader.sh"

# 3. Early exit checks
is_minimal_session && exit 0
is_widget_enabled "@tokyo-night-tmux_show_mywidget" || exit 0

# 4. Cache configuration
cache_key="mywidget"
cache_ttl=$(get_tmux_option "@tokyo-night-tmux_mywidget_refresh" "5")

# 5. Check cache
if is_cache_valid "$cache_key" "$cache_ttl"; then
  get_cached_value "$cache_key"
  exit 0
fi

# 6. Collect data
get_my_metric() {
  # Your metric collection here
  echo "42"
}

# 7. Format output
format_output() {
  local metric="$1"
  
  # Get color based on value
  local color
  color=$(get_system_color "$metric")
  
  # Format icon
  local icon
  icon=$(format_icon "󰀅" "#7dcfff")
  
  # Build output
  local output
  output="${icon} ${color}${metric}%#[default]"
  
  echo "$output"
}

# 8. Main function
main() {
  local metric
  metric=$(get_my_metric)
  
  local output
  output=$(format_output "$metric")
  
  # Cache result
  set_cached_value "$cache_key" "$output"
  
  # Return output
  echo "$output"
}

# 9. Execute
main
```

---

## Step-by-Step Guide

### Step 1: Create Widget File

```bash
# Create your widget script
touch ~/my-custom-widget.sh
chmod +x ~/my-custom-widget.sh
```

### Step 2: Add Boilerplate

Copy the template above into your file.

### Step 3: Implement Metric Collection

Replace `get_my_metric()` with your data collection:

```bash
get_my_metric() {
  # Example: Get current temperature
  local temp
  temp=$(curl -s "https://api.weather.com/..." | jq -r '.temp')
  echo "$temp"
}
```

### Step 4: Customize Formatting

Modify `format_output()` to match your needs:

```bash
format_output() {
  local temp="$1"
  
  # Custom color logic
  local color
  if [[ $temp -lt 0 ]]; then
    color="#7dcfff"  # Cyan for cold
  elif [[ $temp -lt 20 ]]; then
    color="#7aa2f7"  # Blue for cool
  elif [[ $temp -lt 30 ]]; then
    color="#e0af68"  # Yellow for warm
  else
    color="#f7768e"  # Red for hot
  fi
  
  # Format with icon
  local icon=$(format_icon "󰔏" "$color")
  echo "${icon} #[fg=${color}]${temp}°C#[default]"
}
```

### Step 5: Add Configuration Options

In `.tmux.conf`:

```bash
# Enable widget
set -g @tokyo-night-tmux_show_mywidget 1

# Custom refresh rate
set -g @tokyo-night-tmux_mywidget_refresh 10

# Custom options
set -g @tokyo-night-tmux_mywidget_location "New York"
```

### Step 6: Integrate with Status Line

```bash
# Add to status-right
set -g status-right "#(bash ~/my-custom-widget.sh)"
```

---

## API Reference

### Available Functions

See [API.md](API.md) for complete reference.

**Key functions for widgets**:

```bash
# Platform detection
get_os()           # Returns "Darwin" or "Linux"
get_arch()         # Returns architecture
is_apple_silicon() # Checks if Apple Silicon

# Caching
get_cached_value(key)          # Get cached value
set_cached_value(key, value)   # Set cache
is_cache_valid(key, ttl)       # Check if valid

# Formatting
format_icon(icon, color)       # Format icon
get_system_color(percentage)   # Get color for %
pad_percentage(value)          # Pad percentage

# Utilities
validate_percentage(value)     # Clamp 0-100
safe_divide(n, d, default)     # Safe division
clamp_value(val, min, max)     # Clamp value

# Widget framework
is_widget_enabled(option)      # Check if enabled
is_minimal_session()           # Check if minimal
get_tmux_option(opt, default)  # Get tmux option
```

---

## Examples

### Example 1: Simple CPU Widget

```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/widget/widget-loader.sh"

is_minimal_session && exit 0
is_widget_enabled "@tokyo-night-tmux_show_cpu_simple" || exit 0

cpu=$(get_cpu_usage_percentage)
color=$(get_system_color "$cpu")
icon=$(format_icon "󰾆" "#7dcfff")

echo "${icon} ${color}${cpu}%#[default]"
```

### Example 2: Custom API Widget

```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/widget/widget-loader.sh"

is_minimal_session && exit 0
is_widget_enabled "@tokyo-night-tmux_show_api" || exit 0

cache_key="api_status"
if is_cache_valid "$cache_key" 60; then
  get_cached_value "$cache_key"
  exit 0
fi

# Fetch API status with retry
if retry_command "curl -s https://status.myapi.com/health" 3; then
  status="✓ Online"
  color="#9ece6a"  # Green
else
  status="✗ Offline"
  color="#f7768e"  # Red
fi

output="#[fg=${color}]${status}#[default]"
set_cached_value "$cache_key" "$output"
echo "$output"
```

### Example 3: Multi-Metric Widget

```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/widget/widget-loader.sh"

is_minimal_session && exit 0
is_widget_enabled "@tokyo-night-tmux_show_multi" || exit 0

# Collect multiple metrics
cpu=$(get_cpu_usage_percentage)
mem_total=$(get_total_memory_kb)
mem_active=$(get_active_memory_kb)
mem_percent=$((mem_active * 100 / mem_total))

# Format output
cpu_color=$(get_system_color "$cpu")
mem_color=$(get_system_color "$mem_percent")

output="󰾆 ${cpu_color}${cpu}%#[default] "
output+="󰍛 ${mem_color}${mem_percent}%#[default]"

echo "$output"
```

---

## Best Practices

### Performance

1. **Always use caching**:
   ```bash
   if is_cache_valid "$cache_key"; then
     get_cached_value "$cache_key"
     exit 0
   fi
   ```

2. **Set appropriate TTL**:
   ```bash
   # Fast-changing data
   cache_ttl=2
   
   # Slow-changing data
   cache_ttl=60
   ```

3. **Use early exits**:
   ```bash
   is_minimal_session && exit 0
   is_widget_enabled "$option" || exit 0
   ```

### Error Handling

1. **Validate inputs**:
   ```bash
   value=$(validate_percentage "$raw_value")
   ```

2. **Handle failures gracefully**:
   ```bash
   metric=$(get_metric 2>/dev/null || echo "0")
   ```

3. **Provide fallbacks**:
   ```bash
   temp=$(get_temperature)
   [[ $temp -eq 0 ]] && temp="N/A"
   ```

### Code Quality

1. **Follow naming conventions**:
   - Functions: `get_something()`, `format_output()`
   - Variables: `snake_case`
   - Constants: `UPPER_CASE`

2. **Document your code**:
   ```bash
   # Gets current temperature from API
   # Returns: Temperature in Celsius or 0 if unavailable
   get_temperature() {
     # ...
   }
   ```

3. **Test your widget**:
   ```bash
   # Test directly
   bash my-widget.sh
   
   # Test with different values
   export MOCK_VALUE=75
   bash my-widget.sh
   ```

---

## Debugging

### Enable Debug Mode

```bash
# In your widget script
set -x  # Enable bash trace
```

### Test Without Tmux

```bash
# Run widget directly
bash my-widget.sh

# With mock environment
export TMUX_SHOW_MYWIDGET="1"
bash my-widget.sh
```

### Check Cache

```bash
# View cache
cat ~/.tmux/tokyo-night-cache/mywidget.cache

# Clear cache
rm ~/.tmux/tokyo-night-cache/mywidget.cache
```

### Common Issues

**Widget not showing**:
- Check if enabled in `.tmux.conf`
- Verify widget is in `widgets_order`
- Check file permissions (`chmod +x`)

**Wrong output**:
- Test metric collection separately
- Check color formatting
- Verify tmux format strings

**Performance issues**:
- Increase cache TTL
- Optimize metric collection
- Use early exits

---

## Sharing Your Widget

### Contributing

1. Test thoroughly on both macOS and Linux
2. Add tests in `test/widgets/`
3. Update documentation
4. Submit PR

### Packaging

Create a standalone package:

```bash
my-widget/
├── my-widget.sh
├── README.md
├── LICENSE
└── install.sh
```

---

## See Also

- [API.md](API.md) - Complete API reference
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [examples/](../examples/) - Configuration examples
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines

---

## Need Help?

- [Ask a Question](https://github.com/gufranco/tokyo-night-revamped-tmux/discussions)
- [Report an Issue](https://github.com/gufranco/tokyo-night-revamped-tmux/issues)

