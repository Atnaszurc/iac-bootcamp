#!/usr/bin/env bash
# =============================================================================
# run-tests.sh — Terraform Test Runner for hashi-training
# =============================================================================
#
# Runs `terraform test` on all testable examples.
# Core training uses local/libvirt providers (command = plan, no daemon needed).
# Cloud modules use mock_provider blocks (Terraform 1.7+, no credentials needed).
#
# USAGE:
#   ./scripts/run-tests.sh              # Run all testable examples
#   ./scripts/run-tests.sh TF-100       # Run only TF-100 examples
#   ./scripts/run-tests.sh TF-102       # Run only TF-102 examples
#   ./scripts/run-tests.sh AWS-200      # Run only AWS mock tests
#   ./scripts/run-tests.sh AZ-200       # Run only Azure mock tests
#   ./scripts/run-tests.sh MC-300       # Run only MC-300 multi-cloud tests
#   ./scripts/run-tests.sh cloud        # Run all cloud mock tests
#   ./scripts/run-tests.sh --list       # List all testable examples (no run)
#   ./scripts/run-tests.sh --help       # Show this help
#
# REQUIREMENTS:
#   - Terraform >= 1.7.0 (for mock_provider support in cloud tests)
#   - Run from the hashi-training/ root directory
#
# CORE TRAINING (local/libvirt providers — command = plan, no daemon needed):
#   TF-101 (all), TF-102 (all), TF-103 (all), TF-104 (all)
#   TF-201/moved-blocks, TF-202 (all), TF-203 (all), TF-204/removed-blocks, TF-204/identity-import
#   TF-301/3-sensitive-values, TF-301/4-cross-variable-validation, TF-301/5-ephemeral-values
#   TF-302/3-lifecycle-arguments, TF-302/4-write-only-attributes
#   TF-305/1-workspaces, TF-306 (all)
#
# CLOUD MODULES (mock_provider — no credentials needed):
#   AWS-201, AWS-202, AWS-203, AWS-204
#   AZ-201, AZ-202, AZ-203, AZ-204
#   MC-301, MC-302, MC-303, MC-304
#
# SKIPPED (require live credentials or remote backend):
#   TF-305/2-remote-backends, TF-305/3-remote-state-sharing  → Remote backend
#   TF-401, TF-402, TF-403, TF-404                           → HCP Terraform
# =============================================================================

set -euo pipefail

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Script location ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ─── All testable example directories (relative to REPO_ROOT) ─────────────────
TESTABLE_EXAMPLES=(
  # ── TF-100: Fundamentals ────────────────────────────────────────────────────
  "TF-100-fundamentals/TF-101-intro-basics/example"
  "TF-100-fundamentals/TF-101-intro-basics/4-null-resource-terraform-data/example"

  "TF-100-fundamentals/TF-102-variables-loops/example"
  "TF-100-fundamentals/TF-102-variables-loops/1-variables/example"
  "TF-100-fundamentals/TF-102-variables-loops/2-loops/example"
  "TF-100-fundamentals/TF-102-variables-loops/3-env-vars/example"
  "TF-100-fundamentals/TF-102-variables-loops/4-functions/example"
  "TF-100-fundamentals/TF-102-variables-loops/5-for-expressions/example"

  "TF-100-fundamentals/TF-103-infrastructure/example"
  "TF-100-fundamentals/TF-103-infrastructure/1-networks/example"
  "TF-100-fundamentals/TF-103-infrastructure/2-security/example"
  "TF-100-fundamentals/TF-103-infrastructure/3-virtual-machines/example"

  "TF-100-fundamentals/TF-104-state-cli/example"
  "TF-100-fundamentals/TF-104-state-cli/1-cli/example"
  "TF-100-fundamentals/TF-104-state-cli/2-state/example"
  "TF-100-fundamentals/TF-104-state-cli/3-modules-intro/example"

  # ── TF-200: Modules & Patterns ──────────────────────────────────────────────
  "TF-200-modules/TF-201-module-design/example"
  "TF-200-modules/TF-201-module-design/moved-blocks/example"

  "TF-200-modules/TF-202-advanced-patterns/example"
  "TF-200-modules/TF-202-advanced-patterns/2-canary-deployments/example"

  "TF-200-modules/TF-203-yaml-config/example"
  "TF-200-modules/TF-203-yaml-config/json-config/example"

  "TF-200-modules/TF-204-import-migration/example"
  "TF-200-modules/TF-204-import-migration/removed-blocks/example"
  "TF-200-modules/TF-204-import-migration/identity-import/example"

  # ── TF-300: Advanced ────────────────────────────────────────────────────────
  "TF-300-advanced/TF-301-validation/3-sensitive-values/example"
  "TF-300-advanced/TF-301-validation/4-cross-variable-validation/example"
  "TF-300-advanced/TF-301-validation/5-ephemeral-values/example"
  "TF-300-advanced/TF-302-conditions-checks/3-lifecycle-arguments/example"
  "TF-300-advanced/TF-302-conditions-checks/4-write-only-attributes/example"
  "TF-300-advanced/TF-303-test-framework/example"
  "TF-300-advanced/TF-305-workspaces-remote-state/1-workspaces/example"
  "TF-300-advanced/TF-306-functions/1-string-functions/example"
  "TF-300-advanced/TF-306-functions/2-collection-functions/example"
  "TF-300-advanced/TF-306-functions/3-filesystem-functions/example"
  "TF-300-advanced/TF-306-functions/4-encoding-functions/example"

  # ── Cloud Modules: AWS-200 (mock_provider — no credentials needed) ──────────
  "cloud-modules/AWS-200-terraform/AWS-201-setup-auth/example"
  "cloud-modules/AWS-200-terraform/AWS-202-compute-networking/example"
  "cloud-modules/AWS-200-terraform/AWS-203-security-storage/example"
  "cloud-modules/AWS-200-terraform/AWS-204-advanced-patterns/example"

  # ── Cloud Modules: AZ-200 (mock_provider — no credentials needed) ───────────
  "cloud-modules/AZ-200-terraform/AZ-201-setup-auth/example"
  "cloud-modules/AZ-200-terraform/AZ-202-compute-networking/example"
  "cloud-modules/AZ-200-terraform/AZ-203-security-storage/example"
  "cloud-modules/AZ-200-terraform/AZ-204-advanced-patterns/example"

  # ── Cloud Modules: MC-300 (mock_provider — both AWS + Azure, no credentials) ─
  "cloud-modules/MC-300-multi-cloud/MC-301-strategy/example"
  "cloud-modules/MC-300-multi-cloud/MC-302-abstraction/example"
  "cloud-modules/MC-300-multi-cloud/MC-303-networking/example"
  "cloud-modules/MC-300-multi-cloud/MC-304-advanced-patterns/example"
)

# ─── Counters ─────────────────────────────────────────────────────────────────
PASSED=0
FAILED=0
SKIPPED=0
FAILED_DIRS=()

# ─── Helper functions ─────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${BLUE}  hashi-training Terraform Test Runner${RESET}"
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${RESET}"
  echo ""
}

print_usage() {
  echo "Usage: $0 [FILTER] [OPTIONS]"
  echo ""
  echo "  FILTER     Optional: filter examples by path substring"
  echo ""
  echo "  OPTIONS:"
  echo "    --list   List all testable examples without running them"
  echo "    --help   Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                  Run all ${#TESTABLE_EXAMPLES[@]} testable examples"
  echo "  $0 TF-100           Run only TF-100 examples"
  echo "  $0 TF-102           Run only TF-102 examples"
  echo "  $0 TF-306           Run only TF-306 function examples"
  echo "  $0 AWS-200          Run only AWS mock tests"
  echo "  $0 AZ-200           Run only Azure mock tests"
  echo "  $0 cloud            Run all cloud mock tests"
  echo "  $0 --list           List all testable examples"
}

check_terraform_version() {
  if ! command -v terraform &>/dev/null; then
    echo -e "${RED}ERROR: terraform not found in PATH${RESET}"
    echo "Install Terraform >= 1.7.0: https://developer.hashicorp.com/terraform/install"
    exit 1
  fi

  local tf_version
  tf_version=$(terraform version -json | grep terraform_version | sed 's/.*: "\(.*\)".*/\1/')
  local major minor patch
  IFS='.' read -r major minor patch <<< "$tf_version"

  if [[ "$major" -lt 1 ]] || [[ "$major" -eq 1 && "$minor" -lt 7 ]]; then
    echo -e "${RED}ERROR: Terraform >= 1.7.0 required (for mock_provider support)${RESET}"
    echo "Current version: $tf_version"
    exit 1
  fi

  echo -e "${GREEN}✓ Terraform $tf_version${RESET}"
}

run_test() {
  local rel_dir="$1"
  local abs_dir="${REPO_ROOT}/${rel_dir}"

  if [[ ! -d "$abs_dir" ]]; then
    echo -e "  ${YELLOW}⚠ SKIP${RESET} ${rel_dir} (directory not found)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if [[ ! -d "${abs_dir}/tests" ]]; then
    echo -e "  ${YELLOW}⚠ SKIP${RESET} ${rel_dir} (no tests/ directory)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  # Colour-code cloud vs core
  if [[ "$rel_dir" == *"cloud-modules"* ]]; then
    echo -e "  ${MAGENTA}▶ RUNNING${RESET} ${rel_dir} ${MAGENTA}[mock]${RESET}"
  else
    echo -e "  ${CYAN}▶ RUNNING${RESET} ${rel_dir}"
  fi

  # Run terraform init quietly, then terraform test
  local init_output test_output
  if ! init_output=$(cd "$abs_dir" && terraform init -upgrade -no-color 2>&1); then
    echo -e "  ${RED}✗ FAIL${RESET} ${rel_dir} — init failed"
    echo "$init_output" | tail -5 | sed 's/^/    /'
    FAILED=$((FAILED + 1))
    FAILED_DIRS+=("$rel_dir")
    return
  fi

  if test_output=$(cd "$abs_dir" && terraform test -no-color 2>&1); then
    local pass_count
    pass_count=$(echo "$test_output" | grep -c "pass$" || true)
    echo -e "  ${GREEN}✓ PASS${RESET} ${rel_dir} (${pass_count} run blocks passed)"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}✗ FAIL${RESET} ${rel_dir}"
    echo "$test_output" | tail -20 | sed 's/^/    /'
    FAILED=$((FAILED + 1))
    FAILED_DIRS+=("$rel_dir")
  fi
}

print_summary() {
  local core_count=0 cloud_count=0
  for dir in "${TESTABLE_EXAMPLES[@]}"; do
    if [[ "$dir" == *"cloud-modules"* ]]; then
      cloud_count=$((cloud_count + 1))
    else
      core_count=$((core_count + 1))
    fi
  done

  echo ""
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}  Test Summary${RESET}"
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${RESET}"
  echo -e "  ${GREEN}Passed:${RESET}  $PASSED"
  echo -e "  ${RED}Failed:${RESET}  $FAILED"
  echo -e "  ${YELLOW}Skipped:${RESET} $SKIPPED"
  echo -e "  ${BOLD}Total:${RESET}   $((PASSED + FAILED + SKIPPED))"

  if [[ ${#FAILED_DIRS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed examples:${RESET}"
    for dir in "${FAILED_DIRS[@]}"; do
      echo -e "  ${RED}✗${RESET} $dir"
    done
  fi

  echo ""
  if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All tests passed! ✓${RESET}"
  else
    echo -e "${RED}${BOLD}$FAILED test(s) failed. ✗${RESET}"
  fi
  echo ""
}

# ─── Main ─────────────────────────────────────────────────────────────────────

# Parse arguments
FILTER=""
LIST_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      print_usage
      exit 0
      ;;
    --list)
      LIST_ONLY=true
      ;;
    --*)
      echo "Unknown option: $arg"
      print_usage
      exit 1
      ;;
    *)
      FILTER="$arg"
      ;;
  esac
done

# Change to repo root
cd "$REPO_ROOT"

print_header

if [[ "$LIST_ONLY" == true ]]; then
  local_count=0
  cloud_count=0
  for dir in "${TESTABLE_EXAMPLES[@]}"; do
    if [[ "$dir" == *"cloud-modules"* ]]; then
      cloud_count=$((cloud_count + 1))
    else
      local_count=$((local_count + 1))
    fi
  done

  echo -e "${BOLD}Testable examples (${#TESTABLE_EXAMPLES[@]} total):${RESET}"
  echo -e "  ${CYAN}Core training: ${local_count} examples (local/libvirt providers)${RESET}"
  echo -e "  ${MAGENTA}Cloud modules: ${cloud_count} examples (mock_provider)${RESET}"
  echo ""
  for dir in "${TESTABLE_EXAMPLES[@]}"; do
    if [[ -z "$FILTER" ]] || [[ "$dir" == *"$FILTER"* ]]; then
      if [[ "$dir" == *"cloud-modules"* ]]; then
        echo -e "  ${MAGENTA}$dir${RESET}"
      else
        echo "  $dir"
      fi
    fi
  done
  echo ""
  exit 0
fi

check_terraform_version
echo ""

# Filter and count
SELECTED=()
for dir in "${TESTABLE_EXAMPLES[@]}"; do
  if [[ -z "$FILTER" ]] || [[ "$dir" == *"$FILTER"* ]]; then
    SELECTED+=("$dir")
  fi
done

if [[ ${#SELECTED[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No examples match filter: '$FILTER'${RESET}"
  echo "Run '$0 --list' to see all testable examples."
  exit 1
fi

echo -e "${BOLD}Running ${#SELECTED[@]} example(s)${RESET}$([ -n "$FILTER" ] && echo " matching '$FILTER'" || echo ""):"
echo ""

for dir in "${SELECTED[@]}"; do
  run_test "$dir"
done

print_summary

# Exit with failure code if any tests failed
[[ $FAILED -eq 0 ]]

# Made with Bob
