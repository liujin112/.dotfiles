# Shared platform detection for Devbox setup scripts.
# Load output.bash before sourcing this file.

if [[ -n "${_DEVBOX_PLATFORM_BASH_LOADED:-}" ]]; then
  return 0
fi

detect_os() {
  local os

  if ! os="$(uname -s 2>/dev/null)" || [[ -z "$os" ]]; then
    error "Unable to detect operating system"
    return 1
  fi

  case "$os" in
  Darwin) printf '%s\n' "macos" ;;
  Linux) printf '%s\n' "linux" ;;
  FreeBSD) printf '%s\n' "freebsd" ;;
  *) printf '%s\n' "$os" ;;
  esac
}

detect_arch() {
  local arch

  if ! arch="$(uname -m 2>/dev/null)" || [[ -z "$arch" ]]; then
    error "Unable to detect architecture"
    return 1
  fi

  case "$arch" in
  x86_64 | amd64 | x64) printf '%s\n' "x86_64" ;;
  arm64 | aarch64) printf '%s\n' "arm64" ;;
  *) printf '%s\n' "$arch" ;;
  esac
}

_DEVBOX_PLATFORM_BASH_LOADED=1
