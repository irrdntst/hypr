#!/usr/bin/env bash
# Everything that can be verified without a running compositor.
#
#   tests/check.sh
#
# Missing tools are reported as skipped rather than failing, so this runs on a
# bare machine; CI installs them all.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

status=0
pass() { printf '  ok      %s\n' "$1"; }
skip() { printf '  skip    %s (%s)\n' "$1" "$2"; }
fail() { printf '  FAIL    %s\n' "$1"; status=1; }

have() { command -v "$1" >/dev/null 2>&1; }

printf '== Config\n'
if have lua5.4 || have lua; then
    lua_bin="$(command -v lua5.4 || command -v lua)"
    if out="$("$lua_bin" tests/check.lua 2>&1)"; then
        pass "hyprland config"
        printf '%s\n' "$out" | sed 's/^/          /'
    else
        fail "hyprland config"
        printf '%s\n' "$out" | sed 's/^/          /'
    fi
else
    skip "hyprland config" "no lua"
fi

printf '\n== Generated files\n'
if out="$(tools/render.sh --check 2>&1)"; then
    pass "generated files match their sources"
else
    fail "render drift"
    printf '%s\n' "$out" | sed 's/^/          /'
fi

printf '\n== Syntax\n'
if have python3; then
    if python3 - <<'PY'
import json, re, sys
for path, strip in [("config/waybar/config.jsonc", True), (".luarc.json", False)]:
    text = open(path).read()
    if strip:
        text = re.sub(r'^\s*//.*$', '', text, flags=re.M)
    try:
        json.loads(text)
    except Exception as exc:
        print(f"{path}: {exc}")
        sys.exit(1)
PY
    then pass "json"; else fail "json"; fi
else
    skip "json" "no python3"
fi

shell_files=(install.sh tools/*.sh tests/*.sh config/hypr/scripts/*.sh)
if bash -n "${shell_files[@]}" 2>/dev/null; then
    pass "shell syntax (${#shell_files[@]} files)"
else
    fail "shell syntax"
    bash -n "${shell_files[@]}" 2>&1 | sed 's/^/          /'
fi

if have shellcheck; then
    if out="$(shellcheck -S warning "${shell_files[@]}" 2>&1)"; then
        pass "shellcheck"
    else
        fail "shellcheck"
        printf '%s\n' "$out" | sed 's/^/          /'
    fi
else
    skip "shellcheck" "not installed"
fi

printf '\n== Permissions\n'
not_executable=()
for script in "${shell_files[@]}"; do
    [[ -x "$script" ]] || not_executable+=("$script")
done
if (( ${#not_executable[@]} == 0 )); then
    pass "every script is executable"
else
    fail "not executable: ${not_executable[*]}"
fi

printf '\n'
if (( status == 0 )); then
    printf 'All checks passed.\n'
else
    printf 'Some checks failed.\n'
fi
exit "$status"
