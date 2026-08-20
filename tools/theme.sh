#!/usr/bin/env bash
# Render every colour-bearing config from theme/palette.env.
#
#   tools/theme.sh           write the generated configs
#   tools/theme.sh --check   fail if the committed files are out of date
#   tools/theme.sh --diff    show what a render would change
#
# Templates live in theme/templates/. A placeholder is @NAME@, matching a key
# in palette.env. Colours are stored bare, so the template decides the syntax.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PALETTE="$ROOT/theme/palette.env"
TEMPLATES="$ROOT/theme/templates"

MODE="write"
case "${1:-}" in
    --check) MODE="check" ;;
    --diff)  MODE="diff" ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "") ;;
    *) printf 'unknown option: %s\n' "$1" >&2; exit 1 ;;
esac

# template basename -> destination, relative to the repo root
targets() {
    cat <<'MAP'
hypr-look.lua        config/hypr/conf/look.lua
hypr-lock.conf       config/hypr/hyprlock.conf
waybar-style.css     config/waybar/style.css
wofi-style.css       config/wofi/style.css
kitty.conf           config/kitty/kitty.conf
mako-config          config/mako/config
MAP
}

# Build one sed script from the palette: s|@KEY@|value|g per entry.
build_sed_script() {
    local script line key value
    script="$(mktemp)"
    while IFS= read -r line; do
        line="${line%%#*}"
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        key="$(printf '%s' "$key" | tr -d '[:space:]')"
        # Trim surrounding whitespace from the value but keep inner spaces,
        # because font names have them.
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        [[ -z "$key" ]] && continue
        printf 's|@%s@|%s|g\n' "$key" "$value" >> "$script"
    done < "$PALETTE"
    printf '%s' "$script"
}

SED_SCRIPT="$(build_sed_script)"
trap 'rm -f "$SED_SCRIPT"' EXIT

status=0
rendered=0

while read -r template dest; do
    [[ -z "$template" ]] && continue
    src="$TEMPLATES/$template.in"

    if [[ ! -f "$src" ]]; then
        printf 'missing template: %s\n' "$src" >&2
        status=1
        continue
    fi

    out="$(mktemp)"
    sed -f "$SED_SCRIPT" "$src" > "$out"

    # An unresolved placeholder means a typo in the template or a missing key.
    if grep -q '@[A-Z_][A-Z_0-9]*@' "$out"; then
        printf '%s: unresolved placeholders: %s\n' "$dest" \
            "$(grep -o '@[A-Z_][A-Z_0-9]*@' "$out" | sort -u | tr '\n' ' ')" >&2
        status=1
        rm -f "$out"
        continue
    fi

    case "$MODE" in
        write)
            mkdir -p "$(dirname "$ROOT/$dest")"
            if [[ -f "$ROOT/$dest" ]] && cmp -s "$out" "$ROOT/$dest"; then
                printf '  %s unchanged\n' "$dest"
            else
                mv "$out" "$ROOT/$dest"
                printf '  %s written\n' "$dest"
                rendered=$((rendered + 1))
                continue
            fi
            ;;
        check)
            if ! cmp -s "$out" "$ROOT/$dest"; then
                printf '%s is out of date — run tools/theme.sh\n' "$dest" >&2
                status=1
            fi
            ;;
        diff)
            if ! cmp -s "$out" "$ROOT/$dest"; then
                printf '=== %s\n' "$dest"
                diff -u "$ROOT/$dest" "$out" || true
            fi
            ;;
    esac
    rm -f "$out"
done < <(targets)

if [[ "$MODE" == "write" ]]; then
    printf '%d file(s) updated\n' "$rendered"
elif [[ "$MODE" == "check" && $status -eq 0 ]]; then
    printf 'theme: generated files match theme/palette.env\n'
fi

exit "$status"
