#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Dependency Health Check${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

check_required() {
  local tool="$1"
  local min_version="$2"
  
  if command -v "$tool" >/dev/null 2>&1; then
    local version
    case "$tool" in
      tmux)
        version=$($tool -V | awk '{print $2}')
        ;;
      bash)
        version=$BASH_VERSION
        ;;
      *)
        version=$($tool --version 2>/dev/null | head -1)
        ;;
    esac
    
    echo -e "${GREEN}✓${NC} $tool: $version"
    
    if [[ -n "$min_version" ]]; then
      echo -e "  ${BLUE}Minimum required:${NC} $min_version"
    fi
    
    return 0
  else
    echo -e "${RED}✗${NC} $tool: NOT FOUND"
    if [[ -n "$min_version" ]]; then
      echo -e "  ${RED}Required version:${NC} $min_version+"
    fi
    return 1
  fi
}

check_optional() {
  local tool="$1"
  local purpose="$2"
  local install_cmd="$3"
  
  if command -v "$tool" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $tool: available"
    echo -e "  ${BLUE}Purpose:${NC} $purpose"
    return 0
  else
    echo -e "${YELLOW}○${NC} $tool: not installed (optional)"
    echo -e "  ${BLUE}Purpose:${NC} $purpose"
    echo -e "  ${BLUE}Install:${NC} $install_cmd"
    return 1
  fi
}

echo -e "${BLUE}=== Required Dependencies ===${NC}"
echo ""

required_ok=0
check_required "tmux" "3.0+" || required_ok=1
check_required "bash" "4.2+" || required_ok=1
echo ""

echo -e "${BLUE}=== Core Features ===${NC}"
echo ""

check_optional "git" "Git widget (local repository status)" "Usually pre-installed"
echo ""

echo -e "${BLUE}=== Optional Features ===${NC}"
echo ""

echo -e "${YELLOW}Git Web Integration:${NC}"
check_optional "gh" "GitHub PRs, issues, reviews" "brew install gh / apt install gh"
check_optional "glab" "GitLab MRs, issues" "brew install glab / apt install glab"
check_optional "jq" "JSON parsing for Git web features" "brew install jq / apt install jq"
echo ""

echo -e "${YELLOW}Weather Widget:${NC}"
check_optional "curl" "Fetch weather data" "Usually pre-installed"
check_optional "wget" "Alternative to curl" "brew install wget / apt install wget"
echo ""

echo -e "${YELLOW}Network Widget (Linux):${NC}"
check_optional "ip" "Network interface detection" "Usually pre-installed"
check_optional "ifconfig" "Alternative to ip" "Usually pre-installed"
echo ""

echo -e "${YELLOW}System Monitoring (Linux):${NC}"
check_optional "free" "Memory/swap monitoring" "Usually pre-installed"
check_optional "sensors" "Temperature monitoring" "apt install lm-sensors"
echo ""

echo -e "${YELLOW}GPU Monitoring (Linux):${NC}"
check_optional "nvidia-smi" "NVIDIA GPU monitoring" "Install NVIDIA drivers"
check_optional "rocm-smi" "AMD GPU monitoring" "Install ROCm"
echo ""

echo -e "${YELLOW}Temperature Monitoring (macOS):${NC}"
check_optional "istats" "CPU/GPU temperature" "gem install iStats"
check_optional "osx-cpu-temp" "Alternative temperature tool" "brew install osx-cpu-temp"
echo ""

echo -e "${YELLOW}Audio/Bluetooth (Optional):${NC}"
check_optional "blueutil" "Bluetooth info (macOS)" "brew install blueutil"
check_optional "SwitchAudioSource" "Audio device (macOS)" "brew install switchaudio-osx"
check_optional "pactl" "Audio device (Linux)" "Usually pre-installed"
echo ""

echo -e "${YELLOW}Container Monitoring (Optional):${NC}"
check_optional "docker" "Docker container status" "brew install docker / apt install docker.io"
check_optional "kubectl" "Kubernetes pod status" "brew install kubectl / apt install kubectl"
echo ""

echo -e "${BLUE}=== Development Tools ===${NC}"
echo ""

check_optional "shellcheck" "Shell script linting" "brew install shellcheck / apt install shellcheck"
check_optional "bats" "Unit testing" "brew install bats-core / apt install bats"
check_optional "pre-commit" "Git hooks" "pip install pre-commit"
echo ""

echo -e "${BLUE}=== Platform Information ===${NC}"
echo ""
echo -e "${BLUE}OS:${NC} $(uname -s)"
echo -e "${BLUE}Architecture:${NC} $(uname -m)"
echo -e "${BLUE}Bash version:${NC} $BASH_VERSION"

if command -v tmux >/dev/null 2>&1; then
  echo -e "${BLUE}Tmux version:${NC} $(tmux -V)"
fi

echo ""

echo -e "${BLUE}=== Configuration Status ===${NC}"
echo ""

if [[ -f ~/.tmux.conf ]]; then
  echo -e "${GREEN}✓${NC} .tmux.conf found"
  
  if grep -q "tokyo-night-revamped-tmux" ~/.tmux.conf 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Plugin configured in .tmux.conf"
  else
    echo -e "${YELLOW}○${NC} Plugin not found in .tmux.conf"
    echo -e "  ${BLUE}Add:${NC} set -g @plugin 'gufranco/tokyo-night-revamped-tmux'"
  fi
else
  echo -e "${RED}✗${NC} .tmux.conf not found"
  echo -e "  ${BLUE}Create:${NC} touch ~/.tmux.conf"
fi

if [[ -d ~/.tmux/plugins/tpm ]]; then
  echo -e "${GREEN}✓${NC} TPM (Tmux Plugin Manager) installed"
else
  echo -e "${YELLOW}○${NC} TPM not installed"
  echo -e "  ${BLUE}Install:${NC} git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
fi

if [[ -d ~/.tmux/plugins/tokyo-night-revamped-tmux ]]; then
  echo -e "${GREEN}✓${NC} Plugin installed"
  
  cd ~/.tmux/plugins/tokyo-night-revamped-tmux
  local version
  version=$(git describe --tags 2>/dev/null || echo "unknown")
  echo -e "  ${BLUE}Version:${NC} $version"
else
  echo -e "${YELLOW}○${NC} Plugin not installed"
  echo -e "  ${BLUE}Install:${NC} Inside tmux, press Ctrl+b + I"
fi

echo ""

echo -e "${BLUE}=== Summary ===${NC}"
echo ""

if [[ $required_ok -eq 0 ]]; then
  echo -e "${GREEN}✓ All required dependencies are installed${NC}"
  echo -e "${GREEN}✓ You can use Tokyo Night Revamped Tmux${NC}"
else
  echo -e "${RED}✗ Some required dependencies are missing${NC}"
  echo -e "${RED}✗ Install missing dependencies before using the plugin${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}For more help, see:${NC}"
echo -e "  ${BLUE}•${NC} README: https://github.com/gufranco/tokyo-night-revamped-tmux#readme"
echo -e "  ${BLUE}•${NC} Troubleshooting: docs/DEBUGGING.md"
echo ""

