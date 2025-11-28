# GitHub Repository Configuration Checklist

Complete estas ações no GitHub para finalizar o rebranding para **yoru**:

## 🔧 **Configurações do Repositório** (Obrigatório)

### 1. Renomear o Repositório
```
Settings → General → Repository name
Antigo: tokyo-night-revamped-tmux
Novo:   yoru
```
✅ **Importante:** GitHub cria redirect automático

### 2. Atualizar Descrição
```
Settings → General → Description
```
**Texto sugerido:**
```
🌙 yoru (夜) - A nocturnal tmux experience. Beautiful theme with Tokyo Night aesthetics and enterprise-grade tooling.
```

### 3. Atualizar Website (opcional)
```
Settings → General → Website
```
**Sugestão:**
```
https://github.com/gufranco/yoru
```

### 4. Atualizar Topics/Tags
```
Settings → General → Topics
```
**Tags sugeridas:**
```
tmux, tmux-theme, tokyo-night, yoru, terminal, bash, 
tmux-plugin, statusline, japanese, minimalism, nerd-fonts
```

---

## 📋 **Configurações Avançadas** (Recomendado)

### 5. Branch Protection
```
Settings → Branches → Add branch protection rule
Branch name pattern: master
```
**Regras recomendadas:**
- [x] Require pull request reviews before merging
- [x] Require status checks to pass before merging
  - [x] Tests
  - [x] Lint
- [x] Require branches to be up to date before merging
- [x] Include administrators

### 6. Configurar GitHub Pages (opcional)
```
Settings → Pages
Source: gh-pages branch (or main/docs)
```
**Uso:** Documentação online

### 7. Habilitar Discussions
```
Settings → General → Features
[x] Discussions
```
**Benefício:** Comunidade pode fazer perguntas

### 8. Configurar Code Security
```
Settings → Code security and analysis
```
**Habilitar:**
- [x] Dependency graph
- [x] Dependabot alerts
- [x] Dependabot security updates
- [x] Dependabot version updates
- [x] Code scanning (CodeQL)
- [x] Secret scanning

---

## 🏷️ **Releases** (Para Primeira Release)

### 9. Criar Tag e Release
```bash
# Criar tag localmente
git tag -a v1.0.0 -m "Release 1.0.0 - yoru first release"
git push origin v1.0.0
```

Depois no GitHub:
```
Releases → Create a new release
Tag: v1.0.0
Title: yoru 1.0.0 - 夜
```

**Release notes sugeridas:**
```markdown
# yoru 1.0.0 - 夜 (Night)

First official release of yoru (formerly tokyo-night-revamped-tmux).

## 🌙 What is yoru?

A nocturnal tmux experience inspired by Tokyo nights. Beautiful theme 
with Tokyo Night aesthetics and enterprise-grade developer tooling.

## ✨ Highlights

- 🎨 Beautiful Tokyo Night color scheme
- 📊 Rich widgets (System, Git, Network, Context)
- ⚡ High performance with smart caching
- 🔧 Highly customizable
- 🌍 Cross-platform (macOS & Linux)
- 🎯 Enterprise-grade CI/CD and tooling

## 📦 Installation

\```bash
set -g @plugin 'gufranco/yoru'
\```

See [README](https://github.com/gufranco/yoru#readme) for complete documentation.

## 🎉 New in 1.0.0

- Complete rebranding to yoru
- Comprehensive CI/CD workflows
- Extensive documentation (7,000+ lines)
- Pre-commit hooks
- Benchmarking suite
- 5 ready-to-use configuration examples
- Custom widget development templates

## 📚 Documentation

- [README](https://github.com/gufranco/yoru#readme)
- [Configuration Examples](https://github.com/gufranco/yoru/tree/master/examples)
- [API Documentation](https://github.com/gufranco/yoru/blob/master/docs/API.md)
- [Architecture](https://github.com/gufranco/yoru/blob/master/docs/ARCHITECTURE.md)
- [Contributing](https://github.com/gufranco/yoru/blob/master/CONTRIBUTING.md)
```

---

## 🎨 **Customizações Visuais** (Opcional mas Recomendado)

### 10. Social Preview Image
```
Settings → General → Social preview
```
**Criar imagem:** 1280x640px com:
- Logo "yoru 夜"
- Screenshot do tmux com o tema
- Fundo Tokyo Night

### 11. README Badges
Já incluído! Mas você pode adicionar mais:
```markdown
![GitHub release](https://img.shields.io/github/v/release/gufranco/yoru)
![GitHub stars](https://img.shields.io/github/stars/gufranco/yoru)
![GitHub forks](https://img.shields.io/github/forks/gufranco/yoru)
![GitHub issues](https://img.shields.io/github/issues/gufranco/yoru)
![GitHub pull requests](https://img.shields.io/github/issues-pr/gufranco/yoru)
```

---

## 🔗 **Links para Atualizar**

### 12. Links Externos
Se você mencionou o projeto em:
- [ ] Seu site pessoal
- [ ] LinkedIn
- [ ] Twitter/X
- [ ] Dev.to
- [ ] Reddit
- [ ] Outros projetos/READMEs

Atualize para: `github.com/gufranco/yoru`

---

## 📢 **Comunicação** (Opcional)

### 13. Anunciar o Rebranding

**GitHub Discussion:**
```markdown
# 🌙 We're now yoru!

We've rebranded from tokyo-night-revamped-tmux to **yoru** (夜 - night in Japanese).

## Why?
- More elegant and memorable
- Stronger brand identity
- Shorter, cleaner option names
- Japanese minimalism aesthetic

## What changed?
- Repository name: yoru
- Plugin name: gufranco/yoru
- Option prefix: @yoru_* (instead of @tokyo-night-tmux_*)

## Migration
See [MIGRATION.md](docs/MIGRATION.md) for migration instructions.

The redirect from old name works automatically! 🎉
```

---

## ✅ **Checklist Resumido**

```
Obrigatório:
  [ ] 1. Renomear repositório para "yoru"
  [ ] 2. Atualizar descrição
  [ ] 3. Adicionar topics/tags

Recomendado:
  [ ] 4. Configurar branch protection
  [ ] 5. Habilitar Discussions
  [ ] 6. Habilitar security features
  [ ] 7. Criar primeira release (v1.0.0)

Opcional:
  [ ] 8. Social preview image
  [ ] 9. Configurar GitHub Pages
  [ ] 10. Anunciar rebranding
```

---

## 🚀 **Pronto para Usar!**

Após renomear no GitHub, os usuários podem instalar com:

```bash
set -g @plugin 'gufranco/yoru'
```

**O redirect do nome antigo funciona automaticamente!** ✨

---

Salvei este checklist em `GITHUB_ACTIONS_CHECKLIST.md` para referência.

