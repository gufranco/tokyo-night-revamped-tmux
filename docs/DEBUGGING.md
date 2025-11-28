# Debugging Guide

This guide helps you debug issues with Tokyo Night Revamped Tmux.

## 🔍 Quick Diagnosis

### Check Tmux Version

```bash
tmux -V
# Should be 3.0 or higher
```

### Check Bash Version

```bash
bash --version
# Should be 4.2 or higher
```

### Verify Plugin Installation

```bash
ls -la ~/.tmux/plugins/tokyo-night-revamped-tmux/
# Should see src/, test/, tokyo-night.tmux
```

---

## 🐛 Common Issues

### Issue: Status Bar Not Showing

**Symptoms**: Empty status line

**Diagnosis**:
```bash
# Check if tmux loaded the plugin
tmux show-options -g | grep tokyo-night

# Check status line settings
tmux show-options -g status
tmux show-options -g status-left
tmux show-options -g status-right
```

**Solutions**:
1. Reload tmux configuration: `tmux source ~/.tmux.conf`
2. Check plugin installation: `~/.tmux/plugins/tpm/bin/install_plugins`
3. Verify status is on: `set -g status on`

---

### Issue: Widgets Showing "0" or Empty

**Symptoms**: System shows "0%", Git shows nothing

**Diagnosis**:
```bash
# Test widget directly
bash ~/.tmux/plugins/tokyo-night-revamped-tmux/src/system-widget.sh

# Check for errors
bash -x ~/.tmux/plugins/tokyo-night-revamped-tmux/src/system-widget.sh 2>&1 | less
```

**Solutions**:
1. Check widget is enabled: `tmux show-options -g | grep show_system`
2. Clear cache: `rm -rf ~/.tmux/tokyo-night-cache/`
3. Check permissions: `ls -la ~/.tmux/tokyo-night-cache/`

---

### Issue: Git Widget Not Working

**Symptoms**: No git info in status line

**Diagnosis**:
```bash
# Check if you're in a git repo
git status

# Test git widget
cd /path/to/repo
bash ~/.tmux/plugins/tokyo-night-revamped-tmux/src/git-widget.sh $(pwd)

# Check git web features
gh --version  # For GitHub
glab --version  # For GitLab
jq --version  # For JSON parsing
```

**Solutions**:
1. Enable git widget: `set -g @tokyo-night-tmux_show_git 1`
2. Navigate to a git repository
3. Install dependencies: `brew install gh jq` or `apt install gh jq`
4. Authenticate: `gh auth login`

---

### Issue: Network Widget Showing Wrong Speed

**Symptoms**: Network speed is 0 or incorrect

**Diagnosis**:
```bash
# Find default interface
route get default  # macOS
ip route show default  # Linux

# Test network widget
bash ~/.tmux/plugins/tokyo-night-revamped-tmux/src/network-widget.sh

# Check interface name
tmux show-options -g | grep netspeed_iface
```

**Solutions**:
1. Set correct interface: `set -g @tokyo-night-tmux_netspeed_iface "en0"`
2. Check interface exists: `ifconfig` or `ip addr`
3. Clear cache: `rm ~/.tmux/tokyo-night-cache/network.cache`

---

## 🔬 Advanced Debugging

### Enable Debug Logging

```bash
# In .tmux.conf
set -g @tokyo-night-tmux_enable_logging 1
set -g @tokyo-night-tmux_enable_profiling 1

# Reload config
tmux source ~/.tmux.conf

# View logs
tail -f ~/.tmux/tokyo-night-logs/errors.log
tail -f ~/.tmux/tokyo-night-logs/performance.log
```

### Debug Individual Functions

```bash
# Source the library
source ~/.tmux/plugins/tokyo-night-revamped-tmux/src/lib/platform-detector.sh

# Call function directly
get_cpu_usage_percentage
get_total_memory_kb
get_gpu_usage_percentage

# Test with different values
source ~/.tmux/plugins/tokyo-night-revamped-tmux/src/lib/utils/system.sh
safe_divide 100 0 999  # Should return 999
validate_percentage 150  # Should return 100
```

### Trace Script Execution

```bash
# Enable bash debug mode
bash -x ~/.tmux/plugins/tokyo-night-revamped-tmux/src/system-widget.sh 2>&1 | tee debug.log

# Specific function
bash -c 'set -x; source src/lib/cpu/cpu.sh; get_cpu_usage_percentage'
```

### Check Cache State

```bash
# List all cache files
ls -lh ~/.tmux/tokyo-night-cache/

# Check cache age
stat ~/.tmux/tokyo-night-cache/system.cache

# View cache content
cat ~/.tmux/tokyo-night-cache/system.cache

# Clear specific cache
rm ~/.tmux/tokyo-night-cache/system.cache

# Clear all caches
rm -rf ~/.tmux/tokyo-night-cache/
```

### Test Platform Detection

```bash
# Source platform functions
source ~/.tmux/plugins/tokyo-night-revamped-tmux/src/lib/platform-detector.sh

# Check OS
get_os  # Should return "Darwin" or "Linux"

# Check architecture
get_arch  # Should return "arm64", "x86_64", etc.

# Check Apple Silicon
is_apple_silicon && echo "Apple Silicon" || echo "Not Apple Silicon"
```

---

## 🧪 Running Tests

### Run All Tests

```bash
cd ~/.tmux/plugins/tokyo-night-revamped-tmux
make test
```

### Run Specific Test Suite

```bash
# Library tests only
make test-lib

# Widget tests only
make test-widgets

# Specific test file
bats test/lib/system.bats
```

### Run Single Test

```bash
bats test/lib/system.bats --filter "safe_divide"
```

### Debug Failing Tests

```bash
# Verbose output
bats test/lib/system.bats --tap

# With trace
bash -x $(which bats) test/lib/system.bats
```

---

## 🔧 Performance Debugging

### Profile Widget Execution

```bash
# Time widget execution
time bash src/system-widget.sh

# Multiple runs
for i in {1..10}; do
  time bash src/system-widget.sh
done
```

### Identify Slow Functions

```bash
# Enable profiling
set -g @tokyo-night-tmux_enable_profiling 1

# Reload and use tmux
tmux source ~/.tmux.conf

# Check performance log
cat ~/.tmux/tokyo-night-logs/performance.log | sort -t: -k3 -n
```

### Check System Call Overhead

```bash
# Use strace (Linux) or dtruss (macOS)
sudo dtruss -c bash src/system-widget.sh  # macOS
strace -c bash src/system-widget.sh  # Linux
```

---

## 🎯 Platform-Specific Debugging

### macOS

#### GPU Not Working

```bash
# Check ioreg
ioreg -r -d 1 -w 0 -c "IOAccelerator" | grep -E "PerformanceStatistics|utilization"

# Check WindowServer fallback
ps aux | grep WindowServer | grep -v grep
```

#### CPU Temperature

```bash
# Check if istats is installed
which istats

# Install if missing
gem install iStats

# Test
istats cpu
```

#### Memory

```bash
# Check vm_stat
vm_stat

# Check sysctl
sysctl hw.memsize
```

### Linux

#### GPU Not Working

```bash
# NVIDIA
nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader

# AMD
rocm-smi --showuse

# Intel
cat /sys/class/drm/card0/gt_cur_freq_mhz
```

#### CPU Temperature

```bash
# Check thermal zones
ls /sys/class/thermal/thermal_zone*/temp

# Use sensors
sensors

# Install if missing
sudo apt install lm-sensors
sudo sensors-detect
```

#### Memory

```bash
# Check /proc/meminfo
cat /proc/meminfo

# Use free
free -h
```

---

## 📊 Common Error Messages

### "command not found"

**Cause**: Missing dependency

**Solution**:
```bash
# Check what's missing
which git gh jq curl

# Install missing tools
brew install git gh jq  # macOS
sudo apt install git gh jq  # Ubuntu
```

### "permission denied"

**Cause**: Script not executable or cache directory not writable

**Solution**:
```bash
# Fix script permissions
chmod +x ~/.tmux/plugins/tokyo-night-revamped-tmux/src/*.sh

# Fix cache permissions
chmod 755 ~/.tmux/tokyo-night-cache/
```

### "syntax error"

**Cause**: Bash version too old

**Solution**:
```bash
# Check bash version
bash --version

# Upgrade bash
brew install bash  # macOS
sudo apt install bash  # Ubuntu

# Update shell
sudo chsh -s /usr/local/bin/bash
```

---

## 🆘 Getting Help

### Before Asking for Help

1. Check this debugging guide
2. Search [existing issues](https://github.com/gufranco/tokyo-night-revamped-tmux/issues)
3. Enable logging and check logs
4. Test with minimal configuration

### When Reporting Issues

Include:

```bash
# System info
uname -a
tmux -V
bash --version

# Plugin info
ls -la ~/.tmux/plugins/tokyo-night-revamped-tmux/

# Configuration
tmux show-options -g | grep tokyo-night

# Error output
bash -x src/system-widget.sh 2>&1 | tee error.log

# Logs (if enabled)
cat ~/.tmux/tokyo-night-logs/errors.log
```

### Useful Commands

```bash
# Dump all tmux options
tmux show-options -g > tmux-options.txt

# Check tmux messages
tmux show-messages

# Validate configuration
bash src/lib/utils/config-validator.sh

# Health check
bash src/lib/utils/health-check.sh
```

---

## 🔍 Debugging Checklist

Before reporting a bug, check:

- [ ] Using tmux 3.0+ and bash 4.2+
- [ ] Plugin installed correctly via TPM
- [ ] Configuration reloaded (`tmux source ~/.tmux.conf`)
- [ ] Widgets enabled in configuration
- [ ] No conflicting tmux plugins
- [ ] Cache cleared (`rm -rf ~/.tmux/tokyo-night-cache/`)
- [ ] Logs checked (if enabled)
- [ ] Tested with minimal configuration
- [ ] Issue persists after restarting tmux

---

## 💡 Tips & Tricks

### Quick Reset

```bash
# Complete reset
rm -rf ~/.tmux/tokyo-night-cache/
rm -rf ~/.tmux/tokyo-night-logs/
tmux kill-server
tmux
```

### Minimal Configuration

Test with minimal `.tmux.conf`:

```bash
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'gufranco/tokyo-night-revamped-tmux'
run '~/.tmux/plugins/tpm/tpm'
```

### Interactive Debugging

```bash
# Start tmux with debug output
tmux -vv new-session

# Attach with logging
tmux -vv attach

# Check tmux log
cat ~/tmux-*.log
```

---

## 📚 Additional Resources

- [Tmux Manual](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [Bash Debugging](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)
- [GitHub Issues](https://github.com/gufranco/tokyo-night-revamped-tmux/issues)
- [Discussions](https://github.com/gufranco/tokyo-night-revamped-tmux/discussions)

---

**Still stuck?** Open an issue with your debug output!

