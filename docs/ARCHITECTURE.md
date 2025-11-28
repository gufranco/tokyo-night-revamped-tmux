# Architecture Documentation

This document describes the architecture and design decisions of yoru.

## 📐 Overview

yoru follows a **modular, layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                      tokyo-night.tmux                        │
│                     (Entry Point)                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│            src/lib/tmux/theme-config.sh                      │
│          (Theme Configuration & Setup)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌──────────────────┐          ┌──────────────────┐
│  status-left.sh  │          │ status-right.sh  │
│  (Left Status)   │          │ (Right Status)   │
└────────┬─────────┘          └────────┬─────────┘
         │                              │
         │        ┌─────────────────────┴────────────┐
         │        │                                  │
         ▼        ▼                                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    Widget Layer                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ System   │  │   Git    │  │ Network  │  │ Context  │   │
│  │ Widget   │  │ Widget   │  │ Widget   │  │ Widget   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │
      ┌──────────────┴──────────────┬──────────────────────┐
      │                             │                      │
      ▼                             ▼                      ▼
┌──────────────┐          ┌──────────────────┐    ┌──────────────┐
│ Platform     │          │ UI Components    │    │  Utilities   │
│ Layer        │          │                  │    │              │
│              │          │ - Colors         │    │ - Cache      │
│ - CPU        │          │ - Themes         │    │ - Validator  │
│ - GPU        │          │ - Format         │    │ - Logger     │
│ - RAM        │          │ - Tooltips       │    │ - Health     │
│ - Disk       │          │                  │    │              │
│ - Network    │          │                  │    │              │
└──────────────┘          └──────────────────┘    └──────────────┘
```

---

## 🏗️ Core Principles

### 1. SOLID Principles

#### Single Responsibility
Each module has ONE clear responsibility:
- `cpu.sh` - CPU metrics only
- `cache.sh` - Caching logic only
- `themes.sh` - Theme definitions only

#### Open/Closed
- Extensible through configuration
- New widgets can be added without modifying core
- New themes can be added without changing existing code

#### Liskov Substitution
- All widgets implement the same interface
- Platform-specific implementations are interchangeable

#### Interface Segregation
- Small, focused modules
- No unnecessary dependencies

#### Dependency Inversion
- Depend on abstractions (widget interface)
- Not on concrete implementations

### 2. DRY (Don't Repeat Yourself)

- Shared logic in utility functions
- Common patterns abstracted
- Single source of truth for constants

### 3. Lazy Loading

- Dependencies loaded only when needed
- Widget scripts source libs on-demand
- Minimal startup cost

---

## 📦 Module Breakdown

### Entry Point: `tokyo-night.tmux`

**Purpose**: Plugin entry point called by TPM

**Responsibilities**:
- Source theme configuration
- Initialize tmux environment

**Code**:
```bash
#!/usr/bin/env bash
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${PLUGIN_DIR}/src/lib/tmux/theme-config.sh"
```

**Design Decision**: Minimal code here. All logic delegated to libraries.

---

### Theme Configuration: `src/lib/tmux/theme-config.sh`

**Purpose**: Configure tmux status line and colors

**Responsibilities**:
- Set tmux options
- Configure status-left and status-right
- Apply theme colors

**Key Functions**:
- Sets up status line format
- Embeds widget execution directly in tmux config

**Design Decision**: Direct embedding avoids intermediate script execution issues.

---

### Widget Layer

#### Widget Interface

All widgets follow this pattern:

```bash
#!/usr/bin/env bash

# 1. Source dependencies
source "${LIB_DIR}/widget/widget-loader.sh"

# 2. Early exit checks
is_minimal_session && exit 0
is_widget_enabled "@yoru_show_<widget>" || exit 0

# 3. Check cache
local cache_key="<widget>"
if is_cache_valid "$cache_key"; then
  get_cached_value "$cache_key"
  exit 0
fi

# 4. Collect metrics
local metric=$(get_metric)

# 5. Format output
local output=$(format_widget "$metric")

# 6. Cache result
set_cached_value "$cache_key" "$output"

# 7. Display
echo "$output"
```

#### Widget Loader: `src/lib/widget/widget-loader.sh`

**Purpose**: Lazy-load dependencies for widgets

**Design Decision**: 
- Sources all dependencies a widget might need
- Called once per widget execution
- Avoids global sourcing

---

### Platform Layer

#### Design Philosophy

**Problem**: Different platforms have different APIs for the same metric.

**Solution**: Abstraction layer with platform detection.

#### Structure

```
src/lib/
├── cpu/cpu.sh           # CPU abstraction
├── gpu/gpu.sh           # GPU abstraction
├── ram/ram.sh           # RAM abstraction
├── disk/disk.sh         # Disk abstraction
└── network/network.sh   # Network abstraction
```

#### Example: CPU Usage

```bash
get_cpu_usage_percentage() {
  local os
  os="$(get_os)"
  
  case "${os}" in
    Darwin*)
      # macOS implementation
      ;;
    Linux*)
      # Linux implementation
      ;;
  esac
}
```

**Design Decision**: 
- Single function interface
- Platform detection at runtime
- Fallback to safe defaults

---

### UI Layer

#### Color System

**3-tier color system**:

1. **Theme Layer** (`themes.sh`)
   - Base colors from Tokyo Night palette
   - Platform: `THEME[cyan]="#7dcfff"`

2. **Color Config Layer** (`color-config.sh`)
   - User customization
   - Reads tmux options
   - Falls back to theme colors

3. **Color Scale Layer** (`color-scale.sh`)
   - Dynamic colors based on metrics
   - Color gradients (cyan → yellow → red)
   - Usage-based icon selection

**Flow**:
```
User Config → Color Config → Color Scale → Widget
     ↓             ↓              ↓
  Custom       Fallback      Dynamic
  Colors       to Theme      Scaling
```

#### Format Layer

**Purpose**: Consistent formatting across widgets

**Key Functions**:
- `format_segment()` - Format a status segment
- `format_icon()` - Format with color and icon
- `pad_percentage()` - Pad numerical values
- `format_speed()` - Format network speeds

**Design Decision**: Centralized formatting prevents inconsistencies.

---

### Utility Layer

#### Cache System

**Purpose**: Reduce expensive system calls

**Implementation**:
```bash
# Cache structure
~/.tmux/tokyo-night-cache/
├── system.cache
├── git_<path_hash>.cache
├── network.cache
└── weather.cache
```

**Cache Invalidation**:
- Time-based (configurable TTL)
- File modification time
- Manual invalidation

**Design Decision**: 
- Per-widget caching
- Filesystem-based (simple, no deps)
- Automatic cleanup

#### Configuration Validator

**Purpose**: Validate user configuration early

**Checks**:
- Option types (numeric, string, enum)
- Value ranges
- Required dependencies
- Widget combinations

**Design Decision**: Fail early, clear error messages.

#### Error Logger

**Purpose**: Debug issues in production

**Features**:
- Opt-in logging (`@yoru_enable_logging`)
- Rotating log files
- Performance profiling
- Sanitized output

**Design Decision**: Disabled by default for performance.

---

## 🔄 Data Flow

### Typical Widget Execution

```
1. tmux renders status line
   └─> Calls widget script

2. Widget script starts
   └─> Sources widget-loader.sh
       └─> Loads all dependencies

3. Early exit checks
   ├─> Minimal session? → exit
   ├─> Widget disabled? → exit
   └─> Cache valid? → return cached, exit

4. Collect metrics
   └─> Platform-specific function
       └─> System call (expensive)

5. Format output
   ├─> Dynamic color calculation
   ├─> Icon selection
   └─> Format string

6. Cache result
   └─> Write to cache file

7. Return output
   └─> Echo to tmux
```

### Performance Optimization Points

1. **Early Exits**: Skip unnecessary work
2. **Caching**: Avoid redundant system calls
3. **Lazy Loading**: Load only what's needed
4. **Parallel Execution**: Widgets run independently

---

## 🎯 Design Decisions

### Why Bash?

**Pros**:
- Ubiquitous (available everywhere)
- No compilation required
- Direct system integration
- Fast for simple operations

**Cons**:
- Slower than compiled languages
- Error-prone if not careful
- Limited data structures

**Mitigation**:
- Extensive testing
- Input validation
- Defensive programming

### Why File-Based Caching?

**Alternatives Considered**:
- Redis/Memcached (overkill, extra dependency)
- Environment variables (tmux has limits)
- Shared memory (complex, platform-specific)

**Why Files**:
- Simple
- No dependencies
- Cross-platform
- Survives tmux restarts
- Easy to debug

### Why No Configuration File?

**Decision**: Use tmux options instead of separate config file

**Reasons**:
- Native to tmux ecosystem
- No file parsing needed
- Familiar to tmux users
- Validation built-in

---

## 🔐 Security Considerations

### Input Sanitization

All user inputs are sanitized:

```bash
# Widget names
widget_name="${widget_name//[^a-zA-Z0-9_-]/}"

# Paths
path="${path//[^a-zA-Z0-9/_.-]/}"

# Metrics
[[ "$value" =~ ^[0-9]+$ ]] || value="0"
```

### Command Injection Prevention

```bash
# ❌ BAD
eval "echo $user_input"

# ✅ GOOD
echo "${user_input}"
```

### File Permission Checks

```bash
if [[ -w "$cache_dir" ]] 2>/dev/null; then
  # Safe to write
fi
```

---

## 🚀 Performance Profile

### Benchmarks

Typical widget execution times (cached):

| Widget | Time | Notes |
|--------|------|-------|
| System | 5-10ms | Multiple metrics |
| Git | 15-30ms | Depends on repo size |
| Network | 10-20ms | Network calls |
| Context | 5-10ms | Simple formatting |

### Bottlenecks

1. **Git operations** - Large repos slow
2. **Network speed** - Interface detection
3. **GPU metrics** - Platform-specific APIs

### Optimizations Applied

1. **Aggressive caching** - 2-5 second TTL
2. **Early exits** - Skip disabled widgets
3. **Lazy loading** - Load on demand
4. **Minimal dependencies** - Reduce sourcing overhead

---

## 🔮 Future Improvements

### Planned

1. **Parallel metric collection** - Use background jobs
2. **Smart cache invalidation** - Event-based
3. **Precompiled metrics** - Background daemon
4. **Plugin system** - Custom widget support

### Under Consideration

1. **Lua rewrite** - Native tmux scripting
2. **Binary helpers** - For expensive operations
3. **IPC optimization** - Reduce fork/exec overhead

---

## 📚 References

- [tmux Documentation](https://github.com/tmux/tmux/wiki)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Tokyo Night Theme](https://github.com/enkia/tokyo-night-vscode-theme)

---

## 🤝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines.

For questions about architecture, open a [Discussion](https://github.com/gufranco/yoru/discussions).

