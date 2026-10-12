# Shared output helpers for Devbox commands and setup scripts.

if [[ -n "${_DEVBOX_OUTPUT_BASH_LOADED:-}" ]]; then
  return 0
fi

# Colors
RED='\033[0;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info() {
  printf "${BLUE}==>${NC} ${BOLD}%s${NC}\n" "$1"
}

warning() {
  printf "${YELLOW}Warning:${NC} %s\n" "$1" >&2
}

error() {
  printf "${RED}Error:${NC} %s\n" "$1" >&2
}

success() {
  printf "${GREEN}==>${NC} ${BOLD}%s${NC}\n" "$1"
}

_DEVBOX_OUTPUT_BASH_LOADED=1
