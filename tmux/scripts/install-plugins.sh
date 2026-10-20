#!/usr/bin/env bash
# Bootstrap TPM plugins and thumbs binaries; called in the background by tmux.
set -Eeuo pipefail

plugins="$HOME/.tmux/plugins"
log_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
tmp_dir=""
mkdir -p "$plugins" "$log_dir"
exec >>"$log_dir/plugin-install.log" 2>&1

# Multiple tmux servers can share this plugin directory.
if command -v flock >/dev/null 2>&1; then
  exec 9>"$plugins/.dotfiles-bootstrap.lock"
  flock -n 9 || exit 0
fi

cleanup() {
  [[ -z "$tmp_dir" ]] || rm -rf -- "$tmp_dir"
}
trap cleanup EXIT

printf '\n[%s] Checking tmux plugins\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
if [[ ! -x "$plugins/tpm/tpm" ]]; then
  GIT_TERMINAL_PROMPT=0 git clone --depth 1 https://github.com/tmux-plugins/tpm "$plugins/tpm"
fi
if [[ ! -f "$plugins/tmux/catppuccin.tmux" || ! -f "$plugins/tmux-thumbs/tmux-thumbs.tmux" ]]; then
  "$plugins/tpm/bin/install_plugins"
fi

thumbs_dir="$plugins/tmux-thumbs"
release_dir="$thumbs_dir/target/release"
version="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$thumbs_dir/Cargo.toml")"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Cannot determine tmux-thumbs version\n' >&2
  exit 1
fi

if [[ ! -x "$release_dir/thumbs" || ! -x "$release_dir/tmux-thumbs" ]] ||
  [[ "$("$release_dir/thumbs" --version)" != "thumbs $version" ]]; then
  target=""
  case "$(uname -s)/$(uname -m)" in
  Linux/x86_64) target="x86_64-unknown-linux-musl.tar.gz" ;;
  Darwin/x86_64) target="x86_64-apple-darwin.zip" ;;
  esac

  if [[ -n "$target" ]]; then
    tmp_dir="$(mktemp -d)"
    archive="tmux-thumbs_${version}_${target}"
    url="https://github.com/fcsonline/tmux-thumbs/releases/download/$version/$archive"
    curl -fsSL --retry 2 --connect-timeout 10 --max-time 120 "$url" -o "$tmp_dir/$archive"
    curl -fsSL --retry 2 --connect-timeout 10 --max-time 30 "$url.sha256sum" -o "$tmp_dir/checksum"
    expected="$(awk 'NR == 1 {print $1}' "$tmp_dir/checksum")"
    if command -v sha256sum >/dev/null 2>&1; then
      actual="$(sha256sum "$tmp_dir/$archive" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
      actual="$(shasum -a 256 "$tmp_dir/$archive" | awk '{print $1}')"
    else
      printf 'sha256sum or shasum is required\n' >&2
      exit 1
    fi
    if [[ ! "$expected" =~ ^[[:xdigit:]]{64}$ || "$actual" != "$expected" ]]; then
      printf 'tmux-thumbs checksum verification failed\n' >&2
      exit 1
    fi
    if [[ "$archive" == *.zip ]]; then
      unzip -p "$tmp_dir/$archive" thumbs >"$tmp_dir/thumbs"
      unzip -p "$tmp_dir/$archive" tmux-thumbs >"$tmp_dir/tmux-thumbs"
    else
      tar -xOzf "$tmp_dir/$archive" thumbs >"$tmp_dir/thumbs"
      tar -xOzf "$tmp_dir/$archive" tmux-thumbs >"$tmp_dir/tmux-thumbs"
    fi
    chmod +x "$tmp_dir/thumbs" "$tmp_dir/tmux-thumbs"
    [[ "$("$tmp_dir/thumbs" --version)" == "thumbs $version" ]]
    mkdir -p "$release_dir"
    install -m 0755 "$tmp_dir/thumbs" "$release_dir/thumbs"
    install -m 0755 "$tmp_dir/tmux-thumbs" "$release_dir/tmux-thumbs"
  elif command -v cargo >/dev/null 2>&1; then
    # Upstream publishes x86_64 binaries only; other architectures need Rust.
    (cd "$thumbs_dir" && cargo build --locked --release --target-dir target)
  else
    printf 'No prebuilt tmux-thumbs for this architecture; cargo is required to build it\n' >&2
    exit 1
  fi
fi

printf 'tmux-thumbs %s ready; reloading tmux config\n' "$version"
tmux source-file "$HOME/.tmux.conf"
