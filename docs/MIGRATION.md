# Migration Guide

This guide helps you migrate between major versions of yoru.

## 📋 Table of Contents

- [Latest Changes](#latest-changes)
- [Breaking Changes](#breaking-changes)
- [Deprecations](#deprecations)
- [Automated Migration](#automated-migration)
- [Manual Migration](#manual-migration)

---

## Latest Changes

### Current Version: 1.x

**No breaking changes yet**. This is the first major release.

---

## Breaking Changes

### Future: Version 2.0 (Planned)

**Not released yet**. This section will be updated when breaking changes are introduced.

Potential breaking changes being considered:
- Widget script names may change
- Some configuration options may be renamed for consistency
- Minimum tmux version may increase to 3.2+
- Minimum bash version may increase to 5.0+

---

## Deprecations

### None Currently

No features are currently deprecated.

### Deprecation Policy

When we deprecate a feature:
1. **Warning Phase** (1 release) - Feature works but shows deprecation warning
2. **Compatibility Phase** (1 release) - Old and new way both work
3. **Removal Phase** (next major) - Old way is removed

Example timeline:
- v1.5: Feature X deprecated (warning shown)
- v1.6: Both old and new way work
- v2.0: Old way removed

---

## Automated Migration

### Future: Migration Script

We plan to provide an automated migration script:

```bash
# Will be available in future releases
./scripts/migrate.sh --from 1.x --to 2.x
```

This script will:
- Backup your current configuration
- Update option names
- Migrate custom colors
- Update widget order
- Validate new configuration

---

## Manual Migration

### Checking Your Version

```bash
# Check installed version
cd ~/.tmux/plugins/yoru
git describe --tags
```

### Backup Your Configuration

**Always backup before migrating**:

```bash
cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d)
```

### General Migration Steps

1. **Read the changelog**: Check `CHANGELOG.md` for your version
2. **Update the plugin**: `~/.tmux/plugins/tpm/bin/update_plugins`
3. **Update configuration**: Follow version-specific guides below
4. **Test**: Reload tmux and verify everything works
5. **Report issues**: If something breaks, report it

---

## Version-Specific Migrations

### Migrating to 1.x (Initial Release)

**From**: Custom setup or other themes  
**To**: yoru 1.x

#### Step 1: Install TPM

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

#### Step 2: Update .tmux.conf

Add to your `.tmux.conf`:

```bash
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'gufranco/yoru'

# Your configuration here

run '~/.tmux/plugins/tpm/tpm'
```

#### Step 3: Install Plugin

```bash
# Inside tmux, press: Ctrl+b + I
```

#### Step 4: Configure Widgets

Choose which widgets to enable:

```bash
# System widget
set -g @yoru_show_system 1

# Git widget
set -g @yoru_show_git 1

# Network widget
set -g @yoru_show_netspeed 1

# Context widget
set -g @yoru_show_context 1
```

#### Step 5: Reload

```bash
tmux source ~/.tmux.conf
```

---

## Configuration Option Changes

### Current Options

No changes yet. Reference for future versions:

| Old Option | New Option | Notes |
|------------|------------|-------|
| - | - | No changes |

---

## Widget API Changes

### Current API

No changes yet. Reference for future versions:

| Old Function | New Function | Notes |
|--------------|--------------|-------|
| - | - | No changes |

---

## Troubleshooting Migration

### Common Issues

#### Issue: Plugin Not Loading

**Solution**:
```bash
# Reinstall TPM
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Reinstall plugins
tmux kill-server
tmux
# Press: Ctrl+b + I
```

#### Issue: Old Configuration Not Working

**Solution**:
1. Check CHANGELOG.md for breaking changes
2. Compare with examples/ directory
3. Start with minimal config and add features gradually

#### Issue: Widgets Not Showing

**Solution**:
```bash
# Clear cache
rm -rf ~/.tmux/tokyo-night-cache/

# Reload
tmux source ~/.tmux.conf
```

### Getting Help

If migration fails:

1. Check [DEBUGGING.md](DEBUGGING.md)
2. Search [existing issues](https://github.com/gufranco/yoru/issues)
3. Open a new issue with:
   - Old version
   - New version
   - Error messages
   - Configuration file

---

## Best Practices

### Before Migrating

- [ ] Backup configuration
- [ ] Read changelog
- [ ] Check breaking changes
- [ ] Test in separate session

### During Migration

- [ ] Follow migration guide
- [ ] Update incrementally
- [ ] Test after each change
- [ ] Keep notes

### After Migration

- [ ] Verify all features work
- [ ] Clear caches
- [ ] Restart tmux completely
- [ ] Report any issues

---

## Rollback

### Rolling Back to Previous Version

If something breaks:

```bash
# 1. Restore backup
cp ~/.tmux.conf.backup ~/.tmux.conf

# 2. Checkout old version
cd ~/.tmux/plugins/yoru
git fetch --all --tags
git checkout tags/v1.0.0  # Replace with your version

# 3. Reload
tmux source ~/.tmux.conf
```

---

## Future-Proofing

### Tips to Minimize Migration Impact

1. **Use recommended settings**: Follow examples/ configurations
2. **Avoid deprecated features**: Check changelog regularly
3. **Keep plugin updated**: Update at least monthly
4. **Test updates**: Try updates in test environment first
5. **Monitor releases**: Watch GitHub releases

### Semantic Versioning

We follow [Semantic Versioning](https://semver.org/):

- **Major** (x.0.0): Breaking changes
- **Minor** (1.x.0): New features, no breaking changes
- **Patch** (1.0.x): Bug fixes only

### Staying Updated

```bash
# Check for updates
cd ~/.tmux/plugins/yoru
git fetch
git log HEAD..origin/master --oneline

# Update
~/.tmux/plugins/tpm/bin/update_plugins
```

---

## See Also

- [CHANGELOG.md](../CHANGELOG.md) - Detailed change log
- [README.md](../README.md) - Main documentation
- [DEBUGGING.md](DEBUGGING.md) - Troubleshooting
- [examples/](../examples/) - Configuration examples

---

## Questions?

- [Report Migration Issue](https://github.com/gufranco/yoru/issues/new?template=bug_report.yml)
- [Ask Question](https://github.com/gufranco/yoru/discussions)

