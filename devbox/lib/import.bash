# Shared module importer for Devbox commands and setup scripts.

if [[ -n "${_DEVBOX_IMPORT_BASH_LOADED:-}" ]]; then
  return 0
fi

_DEVBOX_IMPORT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" || {
  printf '%s\n' "Error: unable to resolve Devbox library directory" >&2
  return 1
}

import() {
  local module

  if [[ "$#" -eq 0 ]]; then
    printf '%s\n' "Error: import requires at least one module" >&2
    return 1
  fi

  for module in "$@"; do
    case "$module" in
    output) ;;
    platform)
      import output || return 1
      ;;
    installer)
      import platform || return 1
      ;;
    *)
      printf '%s\n' "Error: unknown Devbox module: $module" >&2
      return 1
      ;;
    esac

    case "$module" in
    output) [[ -n "${_DEVBOX_OUTPUT_BASH_LOADED:-}" ]] && continue ;;
    platform) [[ -n "${_DEVBOX_PLATFORM_BASH_LOADED:-}" ]] && continue ;;
    installer) [[ -n "${_DEVBOX_INSTALLER_BASH_LOADED:-}" ]] && continue ;;
    esac

    if [[ ! -f "$_DEVBOX_IMPORT_DIR/$module.bash" ]]; then
      printf '%s\n' "Error: Devbox module not found: $_DEVBOX_IMPORT_DIR/$module.bash" >&2
      return 1
    fi

    # shellcheck disable=SC1090
    source "$_DEVBOX_IMPORT_DIR/$module.bash" || return 1
  done
}

_DEVBOX_IMPORT_BASH_LOADED=1
