#!/usr/bin/env bash
# Keep the launcher honest: hide entries whose program is not installed.
#
#   tools/apps.sh            report what the launcher shows and what is stale
#   tools/apps.sh --prune    hide the stale ones, unhide anything now valid
#   tools/apps.sh --restore  drop every override this script created
#   tools/apps.sh --check    verify apps/defaults.env points at entries that exist
#
# A desktop entry is stale when the program in its TryExec (or the first word
# of Exec) is not on PATH. That happens after uninstalling something, and with
# entries shipped by packages that never installed the binary they name.
#
# Hiding is done the standard way: a same-named file in
# ~/.local/share/applications with NoDisplay=true, which shadows the system
# one. Nothing is deleted, and --restore puts it all back.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
OVERRIDE_DIR="$DATA_HOME/applications"
MARKER="X-Hypr-Pruned=true"

MODE="audit"
case "${1:-}" in
    --prune)   MODE="prune" ;;
    --restore) MODE="restore" ;;
    --check)   MODE="check" ;;
    -h|--help) sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "") ;;
    *) printf 'unknown option: %s\n' "$1" >&2; exit 1 ;;
esac

# Every applications directory, in XDG precedence order.
app_dirs() {
    printf '%s\n' "$OVERRIDE_DIR"
    local dirs="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    printf '%s\n' "${dirs//:/$'\n'}" | while read -r dir; do
        [[ -n "$dir" ]] && printf '%s/applications\n' "$dir"
    done
}

# The value of a key in the [Desktop Entry] group.
entry_value() {
    local file="$1" key="$2"
    awk -F= -v key="$key" '
        /^\[/ { group = ($0 == "[Desktop Entry]") }
        group && $1 == key { sub(/^[^=]*=/, ""); print; exit }
    ' "$file"
}

# The program an entry runs, with field codes and env prefixes stripped.
entry_program() {
    local file="$1" command
    command="$(entry_value "$file" TryExec)"
    [[ -z "$command" ]] && command="$(entry_value "$file" Exec)"
    [[ -z "$command" ]] && return 1

    # env VAR=value prog ...  ->  prog
    read -r -a words <<< "$command"
    local index=0
    if [[ "${words[0]:-}" == "env" ]]; then
        index=1
        while [[ "${words[index]:-}" == *=* ]]; do index=$((index + 1)); done
    fi

    local program="${words[index]:-}"
    program="${program%\"}"; program="${program#\"}"
    printf '%s' "${program##*/}"
}

is_ours() { grep -qF "$MARKER" "$1" 2>/dev/null; }

hide_entry() {
    local id="$1" reason="$2" name="$3"
    mkdir -p "$OVERRIDE_DIR"
    cat > "$OVERRIDE_DIR/$id" <<ENTRY
[Desktop Entry]
Type=Application
Name=${name:-$id}
Exec=/bin/true
NoDisplay=true
$MARKER
# Hidden by tools/apps.sh: $reason
# Remove this file, or run tools/apps.sh --restore, to bring it back.
ENTRY
}

# --- always-hidden list ------------------------------------------------------
declare -A always_hidden=()
if [[ -f "$ROOT/apps/hidden.list" ]]; then
    while IFS= read -r line; do
        line="${line%%#*}"
        line="$(printf '%s' "$line" | tr -d '[:space:]')"
        [[ -n "$line" ]] && always_hidden["$line"]=1
    done < "$ROOT/apps/hidden.list"
fi

# --- restore -----------------------------------------------------------------
if [[ "$MODE" == "restore" ]]; then
    removed=0
    for file in "$OVERRIDE_DIR"/*.desktop; do
        [[ -e "$file" ]] || continue
        if is_ours "$file"; then
            rm "$file"
            printf '  restored %s\n' "$(basename "$file")"
            removed=$((removed + 1))
        fi
    done
    printf '%d override(s) removed\n' "$removed"
    exit 0
fi

# --- check the declared defaults --------------------------------------------
if [[ "$MODE" == "check" ]]; then
    status=0
    while IFS= read -r line; do
        line="${line%%#*}"
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"; id="${line#*=}"
        key="$(printf '%s' "$key" | tr -d '[:space:]')"
        id="$(printf '%s' "$id" | tr -d '[:space:]')"
        [[ -z "$id" ]] && continue

        found=""
        while read -r dir; do
            [[ -f "$dir/$id" ]] && { found="$dir/$id"; break; }
        done < <(app_dirs)

        if [[ -n "$found" ]]; then
            printf '  ok      %-14s %s\n' "$key" "$id"
        else
            printf '  MISSING %-14s %s — install it, or point apps/defaults.env elsewhere\n' \
                "$key" "$id"
            status=1
        fi
    done < "$ROOT/apps/defaults.env"
    exit "$status"
fi

# --- audit / prune -----------------------------------------------------------
declare -A seen=()
stale=0 hidden=0 healed=0 shown=0

while read -r dir; do
    [[ -d "$dir" ]] || continue
    for file in "$dir"/*.desktop; do
        [[ -e "$file" ]] || continue
        id="$(basename "$file")"
        [[ -n "${seen[$id]:-}" ]] && continue   # first match wins, per XDG
        seen["$id"]=1

        if is_ours "$file"; then
            # One of ours. Is the real entry valid again?
            real=""
            while read -r other; do
                [[ "$other" == "$OVERRIDE_DIR" ]] && continue
                [[ -f "$other/$id" ]] && { real="$other/$id"; break; }
            done < <(app_dirs)

            program=""
            [[ -n "$real" ]] && program="$(entry_program "$real")"
            if [[ -n "$program" ]] && command -v "$program" >/dev/null 2>&1 \
               && [[ -z "${always_hidden[$id]:-}" ]]; then
                if [[ "$MODE" == "prune" ]]; then
                    rm "$file"
                    printf '  unhidden  %-40s %s is back\n' "$id" "$program"
                    healed=$((healed + 1))
                else
                    printf '  stale-hide %-39s %s exists again\n' "$id" "$program"
                fi
            else
                hidden=$((hidden + 1))
            fi
            continue
        fi

        name="$(entry_value "$file" Name)"
        no_display="$(entry_value "$file" NoDisplay)"
        is_hidden="$(entry_value "$file" Hidden)"
        [[ "$no_display" == "true" || "$is_hidden" == "true" ]] && continue

        if [[ -n "${always_hidden[$id]:-}" ]]; then
            if [[ "$MODE" == "prune" ]]; then
                hide_entry "$id" "listed in apps/hidden.list" "$name"
                printf '  hid       %-40s listed in apps/hidden.list\n' "$id"
                hidden=$((hidden + 1))
            else
                printf '  would hide %-39s listed in apps/hidden.list\n' "$id"
                stale=$((stale + 1))
            fi
            continue
        fi

        program="$(entry_program "$file")"
        if [[ -z "$program" ]]; then
            shown=$((shown + 1))
            continue
        fi

        if command -v "$program" >/dev/null 2>&1; then
            shown=$((shown + 1))
        else
            stale=$((stale + 1))
            if [[ "$MODE" == "prune" ]]; then
                hide_entry "$id" "$program is not installed" "$name"
                printf '  hid       %-40s %s not installed\n' "$id" "$program"
            else
                printf '  stale     %-40s %s not installed\n' "$id" "$program"
            fi
        fi
    done
done < <(app_dirs)

printf '\n%d entries shown, %d stale, %d already hidden' "$shown" "$stale" "$hidden"
[[ "$MODE" == "prune" ]] && printf ', %d unhidden' "$healed"
printf '\n'

if [[ "$MODE" == "audit" && $stale -gt 0 ]]; then
    printf 'Run tools/apps.sh --prune to hide them.\n'
fi
