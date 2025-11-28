#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}yoru - Benchmark${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

benchmark_widget() {
  local widget_script="$1"
  local widget_name="$(basename "$widget_script" .sh)"
  local iterations="${2:-10}"
  
  if [[ ! -f "$widget_script" ]]; then
    echo -e "${RED}Widget script not found: $widget_script${NC}"
    return 1
  fi
  
  echo -e "${YELLOW}Benchmarking: $widget_name ($iterations iterations)${NC}"
  
  local total_time=0
  local min_time=999999
  local max_time=0
  
  for ((i=1; i<=iterations; i++)); do
    local start_time
    start_time=$(date +%s%N 2>/dev/null || echo "0")
    
    bash "$widget_script" >/dev/null 2>&1
    
    local end_time
    end_time=$(date +%s%N 2>/dev/null || echo "0")
    
    local exec_time=$((end_time - start_time))
    local exec_ms=$((exec_time / 1000000))
    
    total_time=$((total_time + exec_ms))
    
    if [[ $exec_ms -lt $min_time ]]; then
      min_time=$exec_ms
    fi
    
    if [[ $exec_ms -gt $max_time ]]; then
      max_time=$exec_ms
    fi
    
    printf "."
  done
  
  echo ""
  
  local avg_time=$((total_time / iterations))
  
  echo -e "  ${GREEN}Average:${NC} ${avg_time}ms"
  echo -e "  ${GREEN}Min:${NC} ${min_time}ms"
  echo -e "  ${GREEN}Max:${NC} ${max_time}ms"
  
  if [[ $avg_time -lt 50 ]]; then
    echo -e "  ${GREEN}Performance: Excellent${NC}"
  elif [[ $avg_time -lt 100 ]]; then
    echo -e "  ${GREEN}Performance: Good${NC}"
  elif [[ $avg_time -lt 200 ]]; then
    echo -e "  ${YELLOW}Performance: Acceptable${NC}"
  else
    echo -e "  ${RED}Performance: Needs optimization${NC}"
  fi
  
  echo ""
}

benchmark_function() {
  local function_name="$1"
  local test_cmd="$2"
  local iterations="${3:-100}"
  
  echo -e "${YELLOW}Benchmarking function: $function_name ($iterations iterations)${NC}"
  
  local start_time
  start_time=$(date +%s%N 2>/dev/null || echo "0")
  
  for ((i=1; i<=iterations; i++)); do
    eval "$test_cmd" >/dev/null 2>&1
  done
  
  local end_time
  end_time=$(date +%s%N 2>/dev/null || echo "0")
  
  local total_time=$((end_time - start_time))
  local total_ms=$((total_time / 1000000))
  local avg_time=$((total_ms / iterations))
  
  echo -e "  ${GREEN}Total:${NC} ${total_ms}ms for $iterations iterations"
  echo -e "  ${GREEN}Average:${NC} ${avg_time}ms per call"
  echo ""
}

cd "$PROJECT_ROOT"

echo -e "${BLUE}System Information:${NC}"
echo -e "  OS: $(uname -s)"
echo -e "  Arch: $(uname -m)"
echo -e "  Bash: $BASH_VERSION"
echo -e "  Tmux: $(tmux -V)"
echo ""

echo -e "${BLUE}=== Widget Benchmarks ===${NC}"
echo ""

if [[ -f "src/system-widget.sh" ]]; then
  benchmark_widget "src/system-widget.sh" 10
fi

if [[ -f "src/git-widget.sh" ]]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    benchmark_widget "src/git-widget.sh" 10
  else
    echo -e "${YELLOW}Skipping git-widget (not in git repo)${NC}"
    echo ""
  fi
fi

if [[ -f "src/network-widget.sh" ]]; then
  benchmark_widget "src/network-widget.sh" 10
fi

if [[ -f "src/context-widget.sh" ]]; then
  benchmark_widget "src/context-widget.sh" 10
fi

echo -e "${BLUE}=== Function Benchmarks ===${NC}"
echo ""

source "src/lib/utils/system.sh"
benchmark_function "safe_divide" "safe_divide 100 2 0" 1000

source "src/lib/utils/cache.sh"
benchmark_function "get_cached_value" "get_cached_value test_key" 1000

source "src/lib/ui/format.sh"
benchmark_function "pad_percentage" "pad_percentage 75" 1000

echo -e "${BLUE}=== Cache Performance ===${NC}"
echo ""

rm -rf ~/.tmux/tokyo-night-cache/ 2>/dev/null || true
mkdir -p ~/.tmux/tokyo-night-cache/

echo "Testing cache write performance..."
start=$(date +%s%N)
for i in {1..100}; do
  set_cached_value "bench_$i" "test_value_$i"
done
end=$(date +%s%N)
write_time=$(((end - start) / 1000000))
echo -e "  ${GREEN}100 cache writes:${NC} ${write_time}ms (${write_time}ms avg)"

echo "Testing cache read performance..."
start=$(date +%s%N)
for i in {1..100}; do
  get_cached_value "bench_$i" >/dev/null
done
end=$(date +%s%N)
read_time=$(((end - start) / 1000000))
echo -e "  ${GREEN}100 cache reads:${NC} ${read_time}ms (${read_time}ms avg)"

rm -rf ~/.tmux/tokyo-night-cache/bench_* 2>/dev/null || true

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Benchmark Complete!${NC}"
echo -e "${GREEN}======================================${NC}"

