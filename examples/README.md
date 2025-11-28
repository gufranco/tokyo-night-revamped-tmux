# Configuration Examples

This directory contains example configurations for different use cases.

## 📋 Available Examples

### 1. [minimal.tmux.conf](minimal.tmux.conf)
**Perfect for**: Users who want the theme with minimal overhead

**Features**:
- System widget only (CPU, Memory, Battery)
- Refresh rate: 5 seconds
- Minimal resource usage

**Quick Start**:
```bash
cp examples/minimal.tmux.conf ~/.tmux.conf
```

---

### 2. [power-user.tmux.conf](power-user.tmux.conf)
**Perfect for**: Power users who want all features enabled

**Features**:
- All widgets enabled (System, Git, Network, Context)
- Full Git integration (GitHub/GitLab)
- Network monitoring with VPN detection
- Weather and timezone support
- Custom key bindings
- Refresh rate: 3 seconds

**Quick Start**:
```bash
cp examples/power-user.tmux.conf ~/.tmux.conf
```

**Requirements**:
```bash
# macOS
brew install gh jq

# Ubuntu
sudo apt install gh jq
```

---

### 3. [developer.tmux.conf](developer.tmux.conf)
**Perfect for**: Software developers with Git integration focus

**Features**:
- System widget (CPU, Memory, Disk)
- Maximum Git integration
- GitHub/GitLab PRs, issues, reviews
- Git stash, ahead/behind, last commit
- Essential context (time/date)
- Refresh rate: 5 seconds

**Quick Start**:
```bash
cp examples/developer.tmux.conf ~/.tmux.conf

# Authenticate with GitHub/GitLab
gh auth login
glab auth login  # if using GitLab
```

---

### 4. [minimal-performance.tmux.conf](minimal-performance.tmux.conf)
**Perfect for**: Maximum performance with minimal resource usage

**Features**:
- System widget only (CPU, Memory)
- Longest refresh rate: 10 seconds
- Minimal history: 10,000 lines
- No logging/profiling
- Absolute minimal resource usage

**Quick Start**:
```bash
cp examples/minimal-performance.tmux.conf ~/.tmux.conf
```

---

### 5. [themes/custom-colors.tmux.conf](themes/custom-colors.tmux.conf)
**Perfect for**: Customizing colors to match your setup

**Features**:
- Examples of all customizable colors
- Alternative color schemes (Nord, Dracula, Gruvbox)
- Per-widget color customization

**Usage**:
```bash
# Add to your existing .tmux.conf
cat examples/themes/custom-colors.tmux.conf >> ~/.tmux.conf
# Then uncomment and modify the colors you want
```

---

## 🚀 Quick Setup Guide

### First Time Setup

1. **Install TPM** (Tmux Plugin Manager):
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

2. **Choose an example**:
   ```bash
   # For minimal setup
   cp examples/minimal.tmux.conf ~/.tmux.conf

   # OR for full features
   cp examples/power-user.tmux.conf ~/.tmux.conf

   # OR for development
   cp examples/developer.tmux.conf ~/.tmux.conf
   ```

3. **Install plugins**:
   ```bash
   # Start tmux
   tmux

   # Install plugins (inside tmux)
   # Press: Ctrl+a (or Ctrl+b) + I (capital i)
   ```

4. **Reload configuration**:
   ```bash
   # Inside tmux, press: Ctrl+a (or Ctrl+b) + r
   # Or run: tmux source ~/.tmux.conf
   ```

---

## 🎨 Customization Guide

### Changing Widget Order

```bash
set -g @yoru_widgets_order "system,git,netspeed,context"
# Change order: "git,system,context,netspeed"
# Remove widgets: "system,git"  # Only system and git
```

### Adjusting Refresh Rate

```bash
# Default: 5 seconds
set -g @yoru_refresh_rate 5

# Faster updates (more CPU usage)
set -g @yoru_refresh_rate 2

# Slower updates (less CPU usage)
set -g @yoru_refresh_rate 10
```

### Enabling/Disabling Features

```bash
# Enable a feature
set -g @yoru_show_git 1

# Disable a feature
set -g @yoru_show_git 0
```

### Custom Colors

See [themes/custom-colors.tmux.conf](themes/custom-colors.tmux.conf) for all available color options.

---

## 📊 Performance Comparison

| Configuration | CPU Usage | Memory | Refresh Rate | Widgets |
|---------------|-----------|--------|--------------|---------|
| Minimal | ~0.1% | ~5MB | 5s | 1 |
| Minimal Performance | ~0.05% | ~3MB | 10s | 1 |
| Developer | ~0.3% | ~10MB | 5s | 3 |
| Power User | ~0.5% | ~15MB | 3s | 4 |

*Values are approximate and depend on your system*

---

## 🔧 Troubleshooting

### Widgets Not Showing

1. Check widget is enabled:
   ```bash
   tmux show-options -g | grep tokyo-night
   ```

2. Reload configuration:
   ```bash
   tmux source ~/.tmux.conf
   ```

3. Check for errors:
   ```bash
   tmux show-messages
   ```

### Git Widget Not Working

1. Navigate to a git repository
2. Check if `gh` or `glab` is installed:
   ```bash
   gh --version
   glab --version
   ```
3. Authenticate:
   ```bash
   gh auth login
   ```

### Performance Issues

1. Increase refresh rate:
   ```bash
   set -g @yoru_refresh_rate 10
   ```

2. Disable expensive features:
   ```bash
   set -g @yoru_git_disable_auto_fetch 1
   set -g @yoru_netspeed_ping 0
   ```

3. Use minimal configuration

---

## 💡 Tips

### Combining Examples

You can mix and match settings from different examples:

```bash
# Start with minimal
cp examples/minimal.tmux.conf ~/.tmux.conf

# Add Git widget from developer config
echo "set -g @yoru_show_git 1" >> ~/.tmux.conf
```

### Testing Changes

Before committing to a configuration:

1. Make changes in a test file
2. Source it: `tmux source test.tmux.conf`
3. If it works, move to `~/.tmux.conf`

### Backing Up

Always backup your current configuration:

```bash
cp ~/.tmux.conf ~/.tmux.conf.backup
```

---

## 📚 Additional Resources

- [Main README](../README.md) - Full documentation
- [CONTRIBUTING](../CONTRIBUTING.md) - Development guide
- [ARCHITECTURE](../docs/ARCHITECTURE.md) - Technical details
- [DEBUGGING](../docs/DEBUGGING.md) - Troubleshooting guide

---

## 🆘 Need Help?

- [Report an Issue](https://github.com/gufranco/yoru-revamped-tmux-revamped-tmux/issues)
- [Ask a Question](https://github.com/gufranco/yoru-revamped-tmux-revamped-tmux/discussions)
- [Read the Docs](https://github.com/gufranco/yoru-revamped-tmux-revamped-tmux#readme)

