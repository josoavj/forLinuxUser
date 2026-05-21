#!/usr/bin/env bash
# apt-updater v2 — Interactive TUI for selective apt upgrades
# Usage: apt-updater.sh [--no-color] [--dry-run-only] [--lang en|fr] [-h|--help]
set -euo pipefail

# ─────────────────────────────────────────────
#  CLI FLAGS
# ─────────────────────────────────────────────
ENABLE_COLOR=1
DRY_RUN_ONLY=0
LANG_CHOICE="auto"
AUTO_REFRESH_ON_START=0
GLOBAL_OLD_STTY=""

for arg in "$@"; do
  case "$arg" in
    --no-color)       ENABLE_COLOR=0 ;;
    --dry-run-only)   DRY_RUN_ONLY=1 ;;
    --lang=en)        LANG_CHOICE="en" ;;
    --lang=fr)        LANG_CHOICE="fr" ;;
    -h|--help)
      cat <<'USAGE'
Usage: apt-updater.sh [options]

Options:
  --no-color        Disable ANSI colors (for pipes / logs)
  --dry-run-only    Disable the real upgrade option
  --lang=en|fr      Force language (default: auto-detect)
  -h, --help        Show this help

Navigation (TUI):
  ↑ / ↓ / k / j    Move cursor
  Space             Toggle package selection
  a                 Select all / deselect all
  Enter             Confirm action
  q / Esc           Back / Quit
USAGE
      exit 0
      ;;
  esac
done

# ─────────────────────────────────────────────
#  COLORS & STYLES
# ─────────────────────────────────────────────
if [[ "$ENABLE_COLOR" -eq 1 ]] && command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
  BOLD=$(tput bold)
  DIM=$(tput dim)
  RESET=$(tput sgr0)
  REVERSE=$(tput rev)
  FG_BLUE=$(tput setaf 4)
  FG_CYAN=$(tput setaf 6)
  FG_GREEN=$(tput setaf 2)
  FG_YELLOW=$(tput setaf 3)
  FG_RED=$(tput setaf 1)
  FG_WHITE=$(tput setaf 7)
  FG_MAGENTA=$(tput setaf 5)
  BG_BLUE=$(tput setab 4)
  BG_BLACK=$(tput setab 0)
else
  BOLD="" DIM="" RESET="" REVERSE="" FG_BLUE="" FG_CYAN=""
  FG_GREEN="" FG_YELLOW="" FG_RED="" FG_WHITE="" FG_MAGENTA=""
  BG_BLUE="" BG_BLACK=""
fi

# ─────────────────────────────────────────────
#  TERMINAL DIMENSIONS
# ─────────────────────────────────────────────
TERM_COLS=80
TERM_ROWS=24
_update_term_size() {
  if command -v tput >/dev/null 2>&1; then
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
    TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
  fi
}
_update_term_size
trap '_update_term_size' SIGWINCH

# ─────────────────────────────────────────────
#  LOGGING (persistent)
# ─────────────────────────────────────────────
LOG_DIR="${HOME}/.cache/apt-updater"
LOG_FILE="${LOG_DIR}/history.log"
mkdir -p "$LOG_DIR"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$LOG_FILE"
}

# ─────────────────────────────────────────────
#  i18n  (was tr — conflict with Unix tr)
# ─────────────────────────────────────────────
_current_lang() {
  if [[ "$LANG_CHOICE" == "en" || "$LANG_CHOICE" == "fr" ]]; then
    echo "$LANG_CHOICE"; return
  fi
  if [[ "${LANG:-}" == fr* || "${LC_ALL:-}" == fr* || "${LC_MESSAGES:-}" == fr* ]]; then
    echo "fr"
  else
    echo "en"
  fi
}

msg() {
  local key="$1"
  local lang; lang=$(_current_lang)
  case "$key" in
    app_name)          echo "apt-updater" ;;
    app_version)       echo "v2.0" ;;
    app_tagline)       [[ $lang == fr ]] && echo "Gestionnaire de mises à jour interactif" \
                         || echo "Interactive upgrade manager" ;;
    last_refresh)      [[ $lang == fr ]] && echo "Dernier refresh" || echo "Last refresh" ;;
    last_refresh_none) [[ $lang == fr ]] && echo "jamais" || echo "never" ;;
    press_enter)       [[ $lang == fr ]] && echo "Entrée pour continuer…" || echo "Press Enter to continue…" ;;
    checking_updates)  [[ $lang == fr ]] && echo "Vérification des mises à jour" || echo "Checking for updates" ;;
    no_list_loaded)    [[ $lang == fr ]] && echo "Liste non chargée — lancez un refresh (r)" \
                         || echo "List not loaded — run a refresh first (r)" ;;
    upgradable_title)  [[ $lang == fr ]] && echo "Paquets upgradables" || echo "Upgradable packages" ;;
    no_packages)       [[ $lang == fr ]] && echo "Aucun paquet disponible." || echo "No packages available." ;;
    no_changes)        [[ $lang == fr ]] && echo "Aucun changement." || echo "No changes." ;;
    no_selected)       [[ $lang == fr ]] && echo "Aucun paquet sélectionné." || echo "No packages selected." ;;
    will_update)       [[ $lang == fr ]] && echo "Mise à jour de" || echo "Will upgrade" ;;
    proceed_prompt)    [[ $lang == fr ]] && echo "Continuer ? [o/N] " || echo "Proceed? [y/N] " ;;
    confirm_regex)     [[ $lang == fr ]] && echo '^[OoYy]$' || echo '^[Yy]$' ;;
    canceled)          [[ $lang == fr ]] && echo "Annulé." || echo "Canceled." ;;
    upgrading)         [[ $lang == fr ]] && echo "Mise à jour…" || echo "Upgrading…" ;;
    summary)           [[ $lang == fr ]] && echo "Résumé" || echo "Summary" ;;
    updated)           [[ $lang == fr ]] && echo "Mis à jour" || echo "Updated" ;;
    status)            [[ $lang == fr ]] && echo "Statut" || echo "Status" ;;
    status_ok)         [[ $lang == fr ]] && echo "succès" || echo "success" ;;
    status_fail)       [[ $lang == fr ]] && echo "échec" || echo "failed" ;;
    errors_found)      [[ $lang == fr ]] && echo "Erreurs détectées" || echo "Errors detected" ;;
    dry_run_for)       [[ $lang == fr ]] && echo "Simulation pour" || echo "Dry-run for" ;;
    hold_manager)      [[ $lang == fr ]] && echo "Gestionnaire de holds" || echo "Hold manager" ;;
    no_held)           [[ $lang == fr ]] && echo "Aucun paquet en hold." || echo "No held packages." ;;
    held_title)        [[ $lang == fr ]] && echo "Paquets en hold" || echo "Held packages" ;;
    holding)           [[ $lang == fr ]] && echo "Hold appliqué" || echo "Holding" ;;
    unholding)         [[ $lang == fr ]] && echo "Hold retiré" || echo "Unholding" ;;
    invalid_option)    [[ $lang == fr ]] && echo "Option invalide." || echo "Invalid option." ;;
    bye)               [[ $lang == fr ]] && echo "Au revoir." || echo "Bye." ;;
    download_label)    [[ $lang == fr ]] && echo "Téléchargement" || echo "Download" ;;
    disk_label)        [[ $lang == fr ]] && echo "Espace disque" || echo "Disk space" ;;
    nav_hint)          [[ $lang == fr ]] \
                         && echo "↑↓ naviguer  space sélectionner  a tout  enter valider  q retour" \
                         || echo "↑↓ navigate  space select  a all  enter confirm  q back" ;;
    menu_title)        [[ $lang == fr ]] && echo "Menu" || echo "Menu" ;;
    menu_refresh)      [[ $lang == fr ]] && echo "Refresh de la liste" || echo "Refresh list" ;;
    menu_view)         [[ $lang == fr ]] && echo "Voir les paquets" || echo "View packages" ;;
    menu_upgrade)      [[ $lang == fr ]] && echo "Selectionner et mettre a jour" || echo "Select & upgrade" ;;
    menu_dry)          [[ $lang == fr ]] && echo "Dry-run" || echo "Dry-run preview" ;;
    menu_hold)         [[ $lang == fr ]] && echo "Gestion des holds" || echo "Hold manager" ;;
    menu_logs)         [[ $lang == fr ]] && echo "Historique" || echo "Logs" ;;
    menu_lang)         [[ $lang == fr ]] && echo "Langue" || echo "Language" ;;
    menu_help)         [[ $lang == fr ]] && echo "Aide" || echo "Help" ;;
    menu_quit)         [[ $lang == fr ]] && echo "Quitter" || echo "Quit" ;;
    menu_upgradable)   [[ $lang == fr ]] && echo "upgradables" || echo "upgradable" ;;
    menu_security)     [[ $lang == fr ]] && echo "securite" || echo "security" ;;
    select_hint)       [[ $lang == fr ]] \
                         && echo "Entrez les numéros (ex: 1 3 5-7, a=tout, q=annuler): " \
                         || echo "Enter numbers (e.g. 1 3 5-7, a=all, q=cancel): " ;;
    timeout_warn)      [[ $lang == fr ]] && echo "Annulation automatique dans" || echo "Auto-cancel in" ;;
    log_path)          echo "$LOG_FILE" ;;
    *) echo "$key" ;;
  esac
}

# ─────────────────────────────────────────────
#  PRIVILEGES
# ─────────────────────────────────────────────
run_cmd() {
  if [[ $(id -u) -eq 0 ]]; then "$@"; else sudo "$@"; fi
}
ensure_sudo() {
  if [[ $(id -u) -ne 0 ]]; then
    sudo -k
    if ! sudo -v; then
      echo "  ${FG_RED}sudo failed. Please retry.${RESET}"
      return 1
    fi
  fi
  return 0
}

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────
UPGRADABLE=()
UPGRADABLE_VERSIONS_CUR=()
UPGRADABLE_VERSIONS_NEW=()
UPGRADABLE_TYPES=()       # "security" or "normal"
HELD_PACKAGES=()
LAST_REFRESH=""
SELECTED_IDX=()           # indices of selected packages (0-based)
CURSOR=0                  # TUI cursor position

# ─────────────────────────────────────────────
#  SPINNER
# ─────────────────────────────────────────────
spinner_run() {
  local msg="$1"; shift
  local frames=('-' '\' '|' '/')
  local i=0

  if [[ ! -t 1 ]]; then
    echo "$msg…"
    "$@"
    return $?
  fi

  printf '%s ' "${DIM}${msg}${RESET}"
  "$@" >/dev/null 2>&1 &
  local pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    printf '\b%s' "${frames[$((i++ % 4))]}"
    sleep 0.08
  done
  wait "$pid"
  local rc=$?
  if (( rc == 0 )); then printf '\b%s\n' "${FG_GREEN}✓${RESET}"
  else               printf '\b%s\n' "${FG_RED}✗${RESET}"
  fi
  return $rc
}

# ─────────────────────────────────────────────
#  REFRESH
# ─────────────────────────────────────────────
refresh_updates() {
  ensure_sudo || return 1
  spinner_run "$(msg checking_updates)" run_cmd apt-get update
  LAST_REFRESH=$(date '+%Y-%m-%d %H:%M:%S')
  log INFO "apt-get update completed"

  UPGRADABLE=()
  UPGRADABLE_VERSIONS_CUR=()
  UPGRADABLE_VERSIONS_NEW=()
  UPGRADABLE_TYPES=()

  local security_sources
  security_sources=$(apt-cache policy 2>/dev/null | grep -i security | awk '{print $2}' | sort -u || true)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local name version_new archive
    name=$(echo "$line" | awk -F/ '{print $1}')
    version_new=$(echo "$line" | grep -oP '\[.*\K[^ ]+(?= =>)' || echo "")
    local version_cur
    version_cur=$(dpkg-query -W -f='${Version}' "$name" 2>/dev/null || echo "?")
    archive=$(echo "$line" | grep -oP 'security' || echo "normal")

    UPGRADABLE+=("$name")
    UPGRADABLE_VERSIONS_CUR+=("$version_cur")
    UPGRADABLE_VERSIONS_NEW+=("$version_new")
    UPGRADABLE_TYPES+=("$archive")
  done < <(apt list --upgradable 2>/dev/null | tail -n +2 | sort -u)

  log INFO "Found ${#UPGRADABLE[@]} upgradable packages"
}

# ─────────────────────────────────────────────
#  SIZE INFO
# ─────────────────────────────────────────────
show_size_info() {
  local output dl disk
  output=$(run_cmd apt-get -s --only-upgrade install "$@" 2>/dev/null || true)
  dl=$(printf '%s\n' "$output" | grep -E 'Need to get|Il est nécessaire' | head -1)
  disk=$(printf '%s\n' "$output" | grep -E 'After this operation|Après cette' | head -1)
  [[ -n "$dl" ]]   && echo "  ${FG_CYAN}$(msg download_label)${RESET}: $dl"
  [[ -n "$disk" ]] && echo "  ${FG_CYAN}$(msg disk_label)${RESET}:     $disk"
}

# ─────────────────────────────────────────────
#  PARSE SELECTION  (fixed dedup + validation)
# ─────────────────────────────────────────────
parse_selection() {
  local input="$1"
  local max="$2"
  local -A seen=()

  input="${input//,/ }"
  [[ -z "$input" ]] && return 0

  for token in $input; do
    case "$token" in
      a)
        for ((i=1; i<=max; i++)); do seen[$i]=1; done
        break ;;
      [0-9]*-[0-9]*)
        local s=${token%-*} e=${token#*-}
        if (( s < 1 || e < 1 || s > max || e > max || s > e )); then
          echo "Invalid range: $token" >&2; return 1
        fi
        for ((i=s; i<=e; i++)); do seen[$i]=1; done ;;
      [0-9]*)
        if (( token < 1 || token > max )); then
          echo "Invalid index: $token" >&2; return 1
        fi
        seen[$token]=1 ;;
      *)
        echo "Unknown token: $token" >&2; return 1 ;;
    esac
  done

  # Output sorted, deduplicated indices
  for i in "${!seen[@]}"; do echo "$i"; done | sort -n
}

# ─────────────────────────────────────────────
#  TUI DRAWING HELPERS
# ─────────────────────────────────────────────

# Draw a horizontal rule
_hline() {
  local width="${1:-$TERM_COLS}"
  local char="${2:-─}"
  printf '%*s' "$width" '' | tr ' ' "$char"
  echo
}

# Truncate string to N visible chars
_trunc() {
  local str="$1"
  local max="$2"
  if (( ${#str} > max )); then
    echo "${str:0:$((max-1))}…"
  else
    printf "%-${max}s" "$str"
  fi
}

# Status bar at bottom
_strip_ansi() {
  sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g'
}

_visible_len() {
  local text="$1"
  printf '%s' "$text" | _strip_ansi | wc -m | tr -d ' '
}

_statusbar() {
  local hint="${1:-$(msg nav_hint)}"
  local right_info="${2:-$(msg app_name) $(msg app_version)}"
  local width=$TERM_COLS
  local left_plain=" ${hint} "
  local right_plain=" ${right_info} "
  local left_len
  local right_len
  left_len=$(_visible_len "$left_plain")
  right_len=$(_visible_len "$right_plain")
  local pad=$(( width - left_len - right_len ))
  (( pad < 0 )) && pad=0

  printf '%s' "${BG_BLUE}${FG_WHITE}${BOLD}${left_plain}${RESET}"
  printf '%*s' "$pad" ''
  printf '%s%s\n' "${BG_BLUE}${FG_WHITE}${BOLD}${right_plain}" "${RESET}"
}

# Header banner
_header() {
  local refresh_info
  if [[ -n "$LAST_REFRESH" ]]; then
    refresh_info="${DIM}$(msg last_refresh): ${LAST_REFRESH}${RESET}"
  else
    refresh_info="${DIM}$(msg last_refresh): $(msg last_refresh_none)${RESET}"
  fi

  if (( TERM_ROWS < 22 )); then
    echo "  ${FG_BLUE}${BOLD}$(msg app_name)${RESET} ${DIM}$(msg app_version)${RESET}"
    echo "  ${refresh_info}"
  else
    echo ""
    echo "  ${FG_BLUE}${BOLD}$(msg app_name)${RESET} ${DIM}$(msg app_version)${RESET}  ${DIM}·${RESET}  ${DIM}$(msg app_tagline)${RESET}"
    echo "  ${refresh_info}"
    echo ""
  fi
}

# Section title with accent bar
_section() {
  local title="$1"
  local count="${2:-}"
  local badge=""
  [[ -n "$count" ]] && badge=" ${DIM}(${count})${RESET}"
  echo "  ${FG_BLUE}${BOLD}▐${RESET} ${BOLD}${title}${RESET}${badge}"
  echo ""
}

# ─────────────────────────────────────────────
#  PACKAGE LIST  (two columns + details)
# ─────────────────────────────────────────────
_format_pkg_line() {
  local idx=$1
  local name="$2"
  local cur="$3"
  local new="$4"
  local type="$5"

  local type_tag="${type:-normal}"
  if [[ "$type_tag" == *security* ]]; then
    type_tag="${FG_RED}sec${RESET}"
  else
    type_tag="${FG_CYAN}std${RESET}"
  fi

  printf '[%d] %s %s%s%s %s%s%s %s' \
    "$((idx + 1))" \
    "${FG_WHITE}${name}${RESET}" \
    "${DIM}" "${cur}" "${RESET}" \
    "${FG_GREEN}" "${new}" "${RESET}" \
    "$type_tag"
}

_draw_two_column_list() {
  local -n pkgs=$1
  local -n curs=$2
  local -n news=$3
  local -n types=$4
  local -n sel_ref=$5   # "1" or "" per index
  local highlight="${6:-}"
  local start="${7:-0}"
  local max_rows="${8:-9999}"

  local total=${#pkgs[@]}
  if (( total == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_packages)${RESET}"
    return 0
  fi

  local gutter=4
  local col_width=$(( (TERM_COLS - gutter - 4) / 2 ))
  (( col_width < 24 )) && col_width=24

  local end=$(( start + max_rows ))
  (( end > total )) && end=$total

  local row
  for (( row=0; row<max_rows; row++ )); do
    local left_index=$(( start + row ))
    local right_index=$(( start + row + max_rows ))

    local left_text=""
    local right_text=""
    local left_prefix="" left_suffix=""
    local right_prefix="" right_suffix=""

    if (( left_index < total )); then
      left_text=$(_format_pkg_line "$left_index" "${pkgs[$left_index]}" \
        "${curs[$left_index]:-?}" "${news[$left_index]:-?}" "${types[$left_index]:-normal}")
      if [[ "${sel_ref[$left_index]:-}" == "1" ]]; then
        left_text="${FG_GREEN}✓${RESET} ${left_text}"
      else
        left_text="  ${left_text}"
      fi
      if (( left_index == highlight )); then
        left_prefix="${REVERSE}"; left_suffix="${RESET}"
      fi
    fi

    if (( right_index < total )); then
      right_text=$(_format_pkg_line "$right_index" "${pkgs[$right_index]}" \
        "${curs[$right_index]:-?}" "${news[$right_index]:-?}" "${types[$right_index]:-normal}")
      if [[ "${sel_ref[$right_index]:-}" == "1" ]]; then
        right_text="${FG_GREEN}✓${RESET} ${right_text}"
      else
        right_text="  ${right_text}"
      fi
      if (( right_index == highlight )); then
        right_prefix="${REVERSE}"; right_suffix="${RESET}"
      fi
    fi

    local left_cell=""
    local right_cell=""
    if [[ -n "$left_text" ]]; then
      left_cell=$(_trunc "$left_text" "$col_width")
      left_cell="${left_prefix}${left_cell}${left_suffix}"
    fi
    if [[ -n "$right_text" ]]; then
      right_cell=$(_trunc "$right_text" "$col_width")
      right_cell="${right_prefix}${right_cell}${right_suffix}"
    fi

    printf '  %-*s%*s%-*s\n' "$col_width" "$left_cell" "$gutter" '' "$col_width" "$right_cell"
  done
  echo
}

_detail_block() {
  local -n pkgs=$1
  local -n curs=$2
  local -n news=$3
  local -n types=$4
  local idx=$5

  if (( idx < 0 || idx >= ${#pkgs[@]} )); then
    return 0
  fi

  local name="${pkgs[$idx]}"
  local cur="${curs[$idx]:-?}"
  local new="${news[$idx]:-?}"
  local type="${types[$idx]:-normal}"

  _section "Details"
  printf '  %-12s %s\n' "Package:" "$name"
  printf '  %-12s %s -> %s\n' "Version:" "$cur" "$new"
  printf '  %-12s %s\n' "Type:" "$type"
  echo
}

# ─────────────────────────────────────────────
#  KEYBOARD  (read single keypress)
# ─────────────────────────────────────────────
read_key() {
  KEY=""
  local key
  IFS= read -rsn1 key
  if [[ "$key" == $'\x1b' ]]; then
    local seq
    IFS= read -rsn1 -t 0.05 seq || true
    if [[ "$seq" == "[" ]]; then
      local rest
      IFS= read -rsn1 -t 0.05 rest || true

      # Mouse / scroll sequences
      if [[ "$rest" == "M" || "$rest" == "<" ]]; then
        IFS= read -rsn20 -t 0.05 _ || true
        KEY="MOUSE"
        return
      fi

      if [[ "$rest" == "5" || "$rest" == "6" ]]; then
        local tilde
        IFS= read -rsn1 -t 0.05 tilde || true
        if [[ "$rest" == "5" ]]; then
          KEY="PAGEUP"
        else
          KEY="PAGEDOWN"
        fi
        return
      fi

      case "$rest" in
        A) KEY="UP" ;;
        B) KEY="DOWN" ;;
        C) KEY="RIGHT" ;;
        D) KEY="LEFT" ;;
        *) KEY="ESC" ;;
      esac
    elif [[ -z "$seq" ]]; then
      KEY="ESC"
    else
      KEY="ESC"
    fi
  else
    KEY="$key"
  fi
}

# ─────────────────────────────────────────────
#  TUI SELECTOR  (arrow keys + space)
# ─────────────────────────────────────────────
# Returns via SELECTED_IDX (0-based array of chosen indices)
# Returns 0 on confirm, 1 on cancel
tui_select() {
  local title="$1"
  local -n _pkgs=$2
  local -n _curs=$3
  local -n _news=$4
  local -n _types=$5
  local mode="${6:-multi}"   # multi | single

  local total=${#_pkgs[@]}
  if (( total == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_packages)${RESET}"
    SELECTED_IDX=()
    return 1
  fi

  local cursor=0
  local -a sel=()
  for (( i=0; i<total; i++ )); do sel+=(""); done

  # Restore cursor & echo on exit
  local old_stty; old_stty=$(stty -g 2>/dev/null || true)
  trap 'stty "$old_stty" 2>/dev/null; tput cnorm 2>/dev/null; echo' RETURN
  stty -echo -icanon min 1 time 0 2>/dev/null || true
  tput civis 2>/dev/null || true

  local view_start=0

  while true; do
    tput cup 0 0 2>/dev/null || true
    tput ed 2>/dev/null || true
    _header

    local sel_count=0
    for s in "${sel[@]}"; do [[ "$s" == "1" ]] && (( sel_count++ )) || true; done

    _section "$title" "${#_pkgs[@]}"
    local reserved=12
    (( TERM_ROWS < 22 )) && reserved=7
    local max_rows=$(( TERM_ROWS - reserved ))
    (( max_rows < 4 )) && max_rows=4
    if (( cursor < view_start )); then
      view_start=$cursor
    elif (( cursor >= view_start + max_rows )); then
      view_start=$(( cursor - max_rows + 1 ))
    fi
    _draw_two_column_list _pkgs _curs _news _types sel "$cursor" "$view_start" "$max_rows"
    _detail_block _pkgs _curs _news _types "$cursor"

    # Summary line
    printf '  %s%d selected%s\n\n' "${FG_GREEN}${BOLD}" "$sel_count" "${RESET}"

    local hint
    if [[ "$mode" == "multi" ]]; then
      hint="↑↓ move  space select  a all/none  enter confirm  q cancel"
    else
      hint="↑↓ move  enter confirm  q cancel"
    fi
    _statusbar "$hint"

    read_key
    local key="$KEY"
    case "$key" in
      MOUSE) continue ;;
      UP|k)
        (( cursor > 0 )) && (( cursor-- )) || cursor=$(( total - 1 ))
        ;;
      DOWN|j)
        (( cursor < total - 1 )) && (( cursor++ )) || cursor=0
        ;;
      PAGEUP)
        cursor=$(( cursor - max_rows ))
        (( cursor < 0 )) && cursor=0
        ;;
      PAGEDOWN)
        cursor=$(( cursor + max_rows ))
        (( cursor >= total )) && cursor=$(( total - 1 ))
        ;;
      ' ')
        if [[ "$mode" == "multi" ]]; then
          [[ "${sel[$cursor]}" == "1" ]] && sel[$cursor]="" || sel[$cursor]="1"
        else
          SELECTED_IDX=("$cursor")
          stty "$old_stty" 2>/dev/null; tput cnorm 2>/dev/null
          trap - RETURN
          return 0
        fi
        ;;
      a)
        if [[ "$mode" == "multi" ]]; then
          local all_sel=1
          for s in "${sel[@]}"; do [[ "$s" != "1" ]] && all_sel=0 && break; done
          if (( all_sel )); then
            for (( i=0; i<total; i++ )); do sel[$i]=""; done
          else
            for (( i=0; i<total; i++ )); do sel[$i]="1"; done
          fi
        fi
        ;;
      $'\n'|$'\r'|'')
        if [[ "$mode" == "multi" ]]; then
          SELECTED_IDX=()
          for (( i=0; i<total; i++ )); do
            [[ "${sel[$i]}" == "1" ]] && SELECTED_IDX+=("$i")
          done
          if (( ${#SELECTED_IDX[@]} == 0 )); then
            continue  # don't confirm with nothing
          fi
        else
          SELECTED_IDX=("$cursor")
        fi
        stty "$old_stty" 2>/dev/null; tput cnorm 2>/dev/null
        trap - RETURN
        return 0
        ;;
      q|ESC|Q)
        SELECTED_IDX=()
        stty "$old_stty" 2>/dev/null; tput cnorm 2>/dev/null
        trap - RETURN
        return 1
        ;;
    esac
  done
}

tui_view() {
  local title="$1"
  local -n _pkgs=$2
  local -n _curs=$3
  local -n _news=$4
  local -n _types=$5

  local total=${#_pkgs[@]}
  if (( total == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_packages)${RESET}"
    pause
    return 0
  fi

  local cursor=0
  local view_start=0
  local -a sel_flags=()
  for (( i=0; i<total; i++ )); do sel_flags+=(""); done

  local old_stty; old_stty=$(stty -g 2>/dev/null || true)
  trap 'stty "$old_stty" 2>/dev/null; tput cnorm 2>/dev/null; echo' RETURN
  stty -echo -icanon min 1 time 0 2>/dev/null || true
  tput civis 2>/dev/null || true

  while true; do
    tput cup 0 0 2>/dev/null || true
    tput ed 2>/dev/null || true
    _header

    _section "$title" "${#_pkgs[@]}"
    local reserved=10
    (( TERM_ROWS < 22 )) && reserved=6
    local max_rows=$(( TERM_ROWS - reserved ))
    (( max_rows < 4 )) && max_rows=4
    if (( cursor < view_start )); then
      view_start=$cursor
    elif (( cursor >= view_start + max_rows )); then
      view_start=$(( cursor - max_rows + 1 ))
    fi
    _draw_two_column_list _pkgs _curs _news _types sel_flags "$cursor" "$view_start" "$max_rows"
    _detail_block _pkgs _curs _news _types "$cursor"

    _statusbar "↑↓ scroll  PgUp/PgDn page  q back"

    read_key
    local key="$KEY"
    case "$key" in
      MOUSE) continue ;;
      UP|k)   (( cursor > 0 )) && (( cursor-- )) || cursor=$(( total - 1 )) ;;
      DOWN|j) (( cursor < total - 1 )) && (( cursor++ )) || cursor=0 ;;
      PAGEUP|LEFT)  cursor=$(( cursor - max_rows )); (( cursor < 0 )) && cursor=0 ;;
      PAGEDOWN|RIGHT)  cursor=$(( cursor + max_rows )); (( cursor >= total )) && cursor=$(( total - 1 )) ;;
      q|ESC|Q)
        stty "$old_stty" 2>/dev/null; tput cnorm 2>/dev/null
        trap - RETURN
        return 0
        ;;
    esac
  done
}

# ─────────────────────────────────────────────
#  CONFIRM WITH TIMEOUT
# ─────────────────────────────────────────────
confirm_timeout() {
  local prompt="$1"
  local timeout="${2:-30}"
  local regex; regex=$(msg confirm_regex)
  local answer=""
  local remaining=$timeout

  tput cnorm 2>/dev/null || true

  while (( remaining > 0 )); do
    printf '\r%s%s [%ss] ' "$prompt" "" "$remaining"
    IFS= read -rsn1 -t 1 answer || true
    if [[ -n "$answer" ]]; then
      echo "$answer"
      [[ "$answer" =~ $regex ]] && return 0 || return 1
    fi
    (( remaining-- ))
  done
  printf '\r%s  %s\n' "$prompt" "${FG_YELLOW}$(msg timeout_warn) 0s — $(msg canceled)${RESET}"
  return 1
}

# ─────────────────────────────────────────────
#  PAUSE
# ─────────────────────────────────────────────
pause() {
  printf '\n  %s' "${DIM}$(msg press_enter)${RESET}"
  IFS= read -rs _
  echo
}

# ─────────────────────────────────────────────
#  ACTIONS
# ─────────────────────────────────────────────

do_select_and_upgrade() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; return
  fi
  if [[ "$DRY_RUN_ONLY" -eq 1 ]]; then
    echo "  ${FG_YELLOW}--dry-run-only mode active.${RESET}"; pause; return
  fi

  if ! tui_select "$(msg upgradable_title)" \
       UPGRADABLE UPGRADABLE_VERSIONS_CUR UPGRADABLE_VERSIONS_NEW UPGRADABLE_TYPES; then
    echo "  $(msg canceled)"; pause; return
  fi

  local -a pkgs=()
  for idx in "${SELECTED_IDX[@]}"; do pkgs+=("${UPGRADABLE[$idx]}"); done

  clear; _header
  echo "  ${BOLD}$(msg will_update):${RESET}"
  for p in "${pkgs[@]}"; do echo "    ${FG_GREEN}·${RESET} $p"; done
  echo ""
  show_size_info "${pkgs[@]}"
  echo ""

  if ! confirm_timeout "  $(msg proceed_prompt)" 30; then
    echo "  $(msg canceled)"; log INFO "Upgrade canceled"; pause; return
  fi

  ensure_sudo || { pause; return; }
  echo ""
  echo "  ${BOLD}$(msg upgrading)${RESET}"
  echo ""

  local log_out log_err
  log_out=$(mktemp); log_err=$(mktemp)
  local rc=0

  run_cmd apt-get -qq --show-progress \
    -o Dpkg::Progress-Fancy=1 \
    install --only-upgrade -y "${pkgs[@]}" \
    >"$log_out" 2>"$log_err" || rc=$?

  echo ""
  _section "$(msg summary)"

  if (( rc == 0 )); then
    printf '  %-20s %s%s%s\n' "$(msg status):" "${FG_GREEN}${BOLD}" "$(msg status_ok)" "${RESET}"
    log INFO "Upgraded ${#pkgs[@]} packages: ${pkgs[*]}"
  else
    printf '  %-20s %s%s%s\n' "$(msg status):" "${FG_RED}${BOLD}" "$(msg status_fail)" "${RESET}"
    log ERROR "Upgrade failed (rc=$rc) for: ${pkgs[*]}"
  fi
  printf '  %-20s %d\n' "$(msg updated):" "${#pkgs[@]}"

  local err_count
  err_count=$(grep -cE '^(E:|Err:)' "$log_out" "$log_err" 2>/dev/null || true)
  err_count="${err_count//[[:space:]]/}"
  if [[ "$err_count" != "0" && -n "$err_count" ]]; then
    echo ""
    echo "  ${FG_RED}$(msg errors_found): ${err_count}${RESET}"
    grep -E '^(E:|Err:)' "$log_out" "$log_err" 2>/dev/null | head -n 5 \
      | while IFS= read -r line; do echo "    $line"; done
  fi

  rm -f "$log_out" "$log_err"

  # Refresh list after upgrade
  mapfile -t UPGRADABLE < <(apt list --upgradable 2>/dev/null | tail -n +2 | awk -F/ '{print $1}' | sort -u)
  pause
}

do_dry_run() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; return
  fi

  if ! tui_select "$(msg upgradable_title) — dry-run" \
       UPGRADABLE UPGRADABLE_VERSIONS_CUR UPGRADABLE_VERSIONS_NEW UPGRADABLE_TYPES; then
    echo "  $(msg canceled)"; pause; return
  fi

  local -a pkgs=()
  for idx in "${SELECTED_IDX[@]}"; do pkgs+=("${UPGRADABLE[$idx]}"); done

  clear; _header
  echo "  ${BOLD}$(msg dry_run_for):${RESET} ${pkgs[*]}"
  echo ""
  ensure_sudo || { pause; return; }
  run_cmd apt-get --show-progress \
    -o Dpkg::Progress-Fancy=1 \
    install --only-upgrade --dry-run "${pkgs[@]}" \
    | sed 's/^/  /'
  log INFO "Dry-run for: ${pkgs[*]}"
  pause
}

do_hold_manager() {
  while true; do
    clear; _header
    _section "$(msg hold_manager)"

    echo "  ${BOLD}1${RESET}  Hold — depuis la liste upgradable"
    echo "  ${BOLD}2${RESET}  Unhold — retirer un hold"
    echo "  ${BOLD}3${RESET}  Voir les paquets en hold"
    echo "  ${BOLD}q${RESET}  Retour"
    echo ""
    _statusbar "1-3 action  q back"

    local choice
    IFS= read -rsn1 choice
    echo ""

    case "$choice" in
      1)
        if (( ${#UPGRADABLE[@]} == 0 )); then
          echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; continue
        fi
        if tui_select "$(msg hold_manager) — hold" \
             UPGRADABLE UPGRADABLE_VERSIONS_CUR UPGRADABLE_VERSIONS_NEW UPGRADABLE_TYPES; then
          local -a pkgs=()
          for idx in "${SELECTED_IDX[@]}"; do pkgs+=("${UPGRADABLE[$idx]}"); done
          ensure_sudo || { pause; continue; }
          echo "  ${BOLD}$(msg holding):${RESET} ${pkgs[*]}"
          run_cmd apt-mark hold "${pkgs[@]}"
          log INFO "Held: ${pkgs[*]}"
        fi
        pause ;;
      2)
        mapfile -t HELD_PACKAGES < <(apt-mark showhold 2>/dev/null | sort -u)
        if (( ${#HELD_PACKAGES[@]} == 0 )); then
          echo "  ${FG_YELLOW}$(msg no_held)${RESET}"; pause; continue
        fi
        local -a empty_arr=() empty_arr2=() normal_arr=()
        for h in "${HELD_PACKAGES[@]}"; do
          empty_arr+=(""); empty_arr2+=(""); normal_arr+=("normal")
        done
        if tui_select "$(msg hold_manager) — unhold" \
             HELD_PACKAGES empty_arr empty_arr2 normal_arr; then
          local -a pkgs=()
          for idx in "${SELECTED_IDX[@]}"; do pkgs+=("${HELD_PACKAGES[$idx]}"); done
          ensure_sudo || { pause; continue; }
          echo "  ${BOLD}$(msg unholding):${RESET} ${pkgs[*]}"
          run_cmd apt-mark unhold "${pkgs[@]}"
          log INFO "Unheld: ${pkgs[*]}"
        fi
        pause ;;
      3)
        clear; _header
        mapfile -t HELD_PACKAGES < <(apt-mark showhold 2>/dev/null | sort -u)
        if (( ${#HELD_PACKAGES[@]} == 0 )); then
          echo "  ${FG_YELLOW}$(msg no_held)${RESET}"
        else
          _section "$(msg held_title)" "${#HELD_PACKAGES[@]}"
          for h in "${HELD_PACKAGES[@]}"; do
            echo "    ${FG_YELLOW}⊘${RESET} $h"
          done
        fi
        pause ;;
      q|Q|$'\x1b') return ;;
    esac
  done
}

do_view_packages() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    clear; _header
    echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"
    pause
    return
  fi

  tui_view "$(msg upgradable_title)" \
    UPGRADABLE UPGRADABLE_VERSIONS_CUR UPGRADABLE_VERSIONS_NEW UPGRADABLE_TYPES
}

do_show_logs() {
  clear; _header
  _section "Logs"
  if [[ -f "$LOG_FILE" ]]; then
    tail -n 30 "$LOG_FILE" | while IFS= read -r line; do
      if [[ "$line" == *ERROR* ]]; then
        echo "  ${FG_RED}${line}${RESET}"
      elif [[ "$line" == *INFO* ]]; then
        echo "  ${DIM}${line}${RESET}"
      else
        echo "  $line"
      fi
    done
    echo ""
    echo "  ${DIM}$(msg log_path)${RESET}"
  else
    echo "  ${DIM}No log file yet.${RESET}"
  fi
  pause
}

select_language() {
  clear; _header
  _section "Language / Langue"

  local current; current=$(_current_lang)
  echo "  Current / Actuelle: ${FG_GREEN}${current}${RESET}"
  echo ""
  echo "  ${BOLD}1${RESET}  English"
  echo "  ${BOLD}2${RESET}  Français"
  echo "  ${BOLD}3${RESET}  Auto (system)"
  echo ""
  _statusbar "1-3 choose  q back"

  local choice
  IFS= read -rsn1 choice
  case "$choice" in
    1) LANG_CHOICE="en" ;;
    2) LANG_CHOICE="fr" ;;
    3) LANG_CHOICE="auto" ;;
  esac
}

do_help() {
  clear; _header
  _section "Help"
  local lang; lang=$(_current_lang)
  if [[ "$lang" == "fr" ]]; then
    cat <<'EOF'
  Navigation TUI
  ──────────────
  ↑ / k      Monter
  ↓ / j      Descendre
  Space      Sélectionner / déselectionner
  a          Tout sélectionner / déselectionner
  Enter      Confirmer la sélection
  q / Esc    Retour / Annuler

  Menu principal
  ──────────────
  r   Refresh    — lance apt update et recharge la liste
  v   View       — affiche la liste en tableau aligné
  u   Upgrade    — sélecteur TUI puis only-upgrade
  d   Dry-run    — simulation sans modification
  h   Holds      — hold / unhold via apt-mark
  l   Logs       — historique des opérations
  L   Language   — changer la langue
  q   Quit       — quitter

  Fichier de log: ~/.cache/apt-updater/history.log
EOF
  else
    cat <<'EOF'
  TUI navigation
  ──────────────
  ↑ / k      Move up
  ↓ / j      Move down
  Space      Select / deselect
  a          Select all / deselect all
  Enter      Confirm selection
  q / Esc    Back / Cancel

  Main menu
  ─────────
  r   Refresh    — run apt update and reload list
  v   View       — display list in aligned table
  u   Upgrade    — TUI selector then only-upgrade
  d   Dry-run    — simulate without changes
  h   Holds      — hold / unhold via apt-mark
  l   Logs       — operation history
  L   Language   — change language
  q   Quit

  Log file: ~/.cache/apt-updater/history.log
EOF
  fi
  pause
}

# ─────────────────────────────────────────────
#  MAIN MENU
# ─────────────────────────────────────────────
main_menu() {
  [[ "$AUTO_REFRESH_ON_START" -eq 1 ]] && refresh_updates

  # Save terminal state
  GLOBAL_OLD_STTY=$(stty -g 2>/dev/null || true)
  trap '[[ -n "${GLOBAL_OLD_STTY-}" ]] && stty "$GLOBAL_OLD_STTY" 2>/dev/null || true; tput cnorm 2>/dev/null; tput rmcup 2>/dev/null; echo' EXIT INT TERM

  tput smcup 2>/dev/null || true

  while true; do
    tput cup 0 0 2>/dev/null || true
    tput ed 2>/dev/null || true
    _header

    local pkg_count="${#UPGRADABLE[@]}"
    local sec_count=0
    for t in "${UPGRADABLE_TYPES[@]}"; do [[ "$t" == *security* ]] && (( sec_count++ )) || true; done

    _section "$(msg menu_title)"

    local c_pkg="${FG_CYAN}${pkg_count}${RESET}"
    local c_sec=""
    (( sec_count > 0 )) && c_sec="  ${FG_RED}${BOLD}⚠  ${sec_count} $(msg menu_security)${RESET}"

    printf '  %s  %-24s %s%s\n' "${BOLD}r${RESET}" "$(msg menu_refresh)" "" ""
    printf '  %s  %-24s %s%s\n' "${BOLD}v${RESET}" "$(msg menu_view)" \
      "[${c_pkg} $(msg menu_upgradable)${RESET}]" "$c_sec"
    printf '  %s  %-24s\n' "${BOLD}u${RESET}" "$(msg menu_upgrade)"
    printf '  %s  %-24s\n' "${BOLD}d${RESET}" "$(msg menu_dry)"
    printf '  %s  %-24s\n' "${BOLD}h${RESET}" "$(msg menu_hold)"
    printf '  %s  %-24s\n' "${BOLD}l${RESET}" "$(msg menu_logs)"
    printf '  %s  %-24s\n' "${BOLD}L${RESET}" "$(msg menu_lang)"
    printf '  %s  %-24s\n' "${BOLD}?${RESET}" "$(msg menu_help)"
    printf '  %s  %-24s\n' "${BOLD}q${RESET}" "$(msg menu_quit)"
    echo ""

    _statusbar "r refresh  u upgrade  d dry-run  h holds  ? help  q quit"

    read_key
    local key="$KEY"
    echo ""

    case "$key" in
      MOUSE) continue ;;
      r|R) clear; refresh_updates; pause ;;
      v|V) do_view_packages ;;
      u|U) do_select_and_upgrade ;;
      d|D) do_dry_run ;;
      h|H) do_hold_manager ;;
      l)   do_show_logs ;;
      L)   select_language ;;
      '?') do_help ;;
      q|Q|$'\x1b')
        tput rmcup 2>/dev/null || true
        echo "$(msg bye)"
        log INFO "Session ended"
        exit 0
        ;;
      *) ;;
    esac
  done
}

main_menu