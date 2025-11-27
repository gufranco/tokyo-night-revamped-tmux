#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/.."

load_core_libs() {
  source "${LIB_DIR}/utils/coreutils-compat.sh"
  source "${LIB_DIR}/utils/constants.sh"
  source "${LIB_DIR}/ui/themes.sh"
  source "${LIB_DIR}/ui/color-scale.sh"
}

load_widget_base() {
  source "${LIB_DIR}/widget/widget-base.sh"
  source "${LIB_DIR}/utils/cache.sh"
  source "${LIB_DIR}/ui/format.sh"
  source "${LIB_DIR}/utils/error-logger.sh"
  source "${LIB_DIR}/ui/tooltip.sh"
}

load_platform_libs() {
  source "${LIB_DIR}/platform-detector.sh"
}

load_optional_libs() {
  source "${LIB_DIR}/ui/conditional-display.sh"
  source "${LIB_DIR}/utils/historical-data.sh"
  source "${LIB_DIR}/utils/config-validator.sh"
}

load_widget_dependencies() {
  local widget_type="${1:-}"

  load_core_libs

  case "$widget_type" in
    system)
      load_widget_base
      load_platform_libs
      load_optional_libs
      ;;
    git)
      load_widget_base
      source "${LIB_DIR}/git/git.sh"
      ;;
    network)
      load_widget_base
      load_platform_libs
      source "${LIB_DIR}/network/network-utils.sh"
      source "${LIB_DIR}/network/network-speed.sh"
      ;;
    context)
      load_widget_base
      load_platform_libs
      ;;
    *)
      load_widget_base
      load_platform_libs
      ;;
  esac
}

export -f load_core_libs
export -f load_widget_base
export -f load_platform_libs
export -f load_optional_libs
export -f load_widget_dependencies

