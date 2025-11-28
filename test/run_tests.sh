#!/usr/bin/env bash

# Script to run all unit tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BATS_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if bats is installed
if ! command -v bats &> /dev/null; then
  echo -e "${RED}Erro: bats não está instalado${NC}"
  echo "Instale com:"
  echo "  macOS: brew install bats-core"
  echo "  Linux: sudo apt-get install bats ou sudo yum install bats"
  exit 1
fi

echo -e "${GREEN}Executando testes unitários...${NC}"
echo ""

# Executar todos os testes
TEST_FILES=(
  "${SCRIPT_DIR}/lib/"*.bats
  "${SCRIPT_DIR}/widgets/"*.bats
)

FAILED=0
PASSED=0
TOTAL=0

for test_file in "${TEST_FILES[@]}"; do
  if [[ -f "$test_file" ]]; then
    echo -e "${YELLOW}Executando: $(basename "$test_file")${NC}"
    if bats "$test_file"; then
      ((PASSED++))
    else
      ((FAILED++))
    fi
    ((TOTAL++))
    echo ""
  fi
done

# Resumo
echo "=========================================="
echo -e "${GREEN}Testes passados: ${PASSED}${NC}"
if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}Testes falhados: ${FAILED}${NC}"
else
  echo -e "${GREEN}Testes falhados: ${FAILED}${NC}"
fi
echo -e "Total de arquivos de teste: ${TOTAL}"
echo "=========================================="

if [[ $FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi

