#!/usr/bin/env bash
# apt-updater v3.5 — Strict unbound variable safety & robust lifecycle
set -euo pipefail

# ─────────────────────────────────────────────
#  CLI FLAGS & CODES
# ─────────────────────────────────────────────
ENABLE_COLOR=1
DRY_RUN_ONLY=0
LANG_CHOICE="auto"

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
  --no-color        Disable ANSI colors
  --dry-run-only    Disable the real upgrade option
  --lang=en|fr      Force language (default: auto-detect)
  -h, --help        Show this help
USAGE
      exit 0
      ;;
  esac
done

# ─────────────────────────────────────────────
#  COULEURS / STYLES
# ─────────────────────────────────────────────
if [[ "$ENABLE_COLOR" -eq 1 ]] && command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
  BOLD=$(tput bold)    DIM=$(tput dim)       RESET=$(tput sgr0)
  FG_BLUE=$(tput setaf 4)   FG_CYAN=$(tput setaf 6)  FG_GREEN=$(tput setaf 2)
  FG_YELLOW=$(tput setaf 3) FG_RED=$(tput setaf 1)   FG_WHITE=$(tput setaf 7)
  BG_BLUE=$(tput setab 4)   BG_GREEN=$(tput setab 2) BG_YELLOW=$(tput setab 3)
else
  BOLD="" DIM="" RESET=""
  FG_BLUE="" FG_CYAN="" FG_GREEN="" FG_YELLOW="" FG_RED="" FG_WHITE=""
  BG_BLUE="" BG_GREEN="" BG_YELLOW=""
fi

# ─────────────────────────────────────────────
#  TAILLE DU TERMINAL
# ─────────────────────────────────────────────
TERM_COLS=80

_update_term_size() {
  if command -v tput >/dev/null 2>&1; then
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    # Valider que la valeur est un entier positif
    [[ "$cols" =~ ^[0-9]+$ ]] && (( cols > 0 )) && TERM_COLS=$cols
  fi
}
_update_term_size

# Piège SIGWINCH : protégé contre les faux signaux en cours d'opération apt
_SIGWINCH_PENDING=0
trap '_SIGWINCH_PENDING=1' SIGWINCH

_check_resize() {
  if (( _SIGWINCH_PENDING )); then
    _SIGWINCH_PENDING=0
    _update_term_size
  fi
}

# ─────────────────────────────────────────────
#  LOGGING
# ─────────────────────────────────────────────
LOG_DIR="${HOME}/.cache/apt-updater"
LOG_FILE="${LOG_DIR}/history.log"
mkdir -p "$LOG_DIR"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$LOG_FILE"
}

# ─────────────────────────────────────────────
#  INTERNATIONALISATION
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
    app_name)           echo "apt-updater" ;;
    app_version)        echo "v3.5" ;;
    app_tagline)        [[ $lang == fr ]] && echo "Gestionnaire de mises à jour interactif"     || echo "Interactive upgrade manager" ;;
    last_refresh)       [[ $lang == fr ]] && echo "Dernier refresh"                              || echo "Last refresh" ;;
    last_refresh_none)  [[ $lang == fr ]] && echo "jamais"                                       || echo "never" ;;
    press_enter)        [[ $lang == fr ]] && echo "Appuyez sur Entrée pour continuer…"           || echo "Press Enter to continue…" ;;
    checking_updates)   [[ $lang == fr ]] && echo "VÉRIFICATION DES MISES À JOUR EN COURS..."   || echo "CHECKING FOR UPDATES IN PROGRESS..." ;;
    refresh_done)       [[ $lang == fr ]] && echo "MISE À JOUR DE LA LISTE EFFECTUÉE AVEC SUCCÈS !" || echo "LIST UPDATE COMPLETED SUCCESSFULLY!" ;;
    packages_found)     [[ $lang == fr ]] && echo "paquet(s) prêt(s) à être géré(s)."           || echo "package(s) ready to manage." ;;
    no_list_loaded)     [[ $lang == fr ]] && echo "Liste non chargée — lancez un refresh (r)"   || echo "List not loaded — run a refresh first (r)" ;;
    upgradable_title)   [[ $lang == fr ]] && echo "Paquets upgradables"                          || echo "Upgradable packages" ;;
    no_packages)        [[ $lang == fr ]] && echo "Aucun paquet disponible."                     || echo "No packages available." ;;
    no_selected)        [[ $lang == fr ]] && echo "Aucun paquet sélectionné."                    || echo "No packages selected." ;;
    will_update)        [[ $lang == fr ]] && echo "Mise à jour de"                               || echo "Will upgrade" ;;
    proceed_prompt)     [[ $lang == fr ]] && echo "Continuer ? [o/N] "                           || echo "Proceed? [y/N] " ;;
    # .: regex stockée dans une variable locale pour éviter tout problème d'interprétation
    confirm_regex)      [[ $lang == fr ]] && echo '^[OoYy]$'                                     || echo '^[Yy]$' ;;
    canceled)           [[ $lang == fr ]] && echo "Annulé."                                      || echo "Canceled." ;;
    upgrading)          [[ $lang == fr ]] && echo "Mise à jour…"                                 || echo "Upgrading…" ;;
    upgrade_ok)         [[ $lang == fr ]] && echo "Mise à jour terminée avec succès."            || echo "Upgrade completed successfully." ;;
    dryrun_ok)          [[ $lang == fr ]] && echo "Simulation terminée."                         || echo "Dry-run completed." ;;
    download_label)     [[ $lang == fr ]] && echo "Téléchargement"                               || echo "Download" ;;
    disk_label)         [[ $lang == fr ]] && echo "Espace disque"                                || echo "Disk space" ;;
    menu_title)         [[ $lang == fr ]] && echo "Menu Principal"                               || echo "Main Menu" ;;
    menu_refresh)       [[ $lang == fr ]] && echo "Refresh de la liste"                          || echo "Refresh list" ;;
    menu_view)          [[ $lang == fr ]] && echo "Voir la liste des paquets"                    || echo "View packages list" ;;
    menu_upgrade)       [[ $lang == fr ]] && echo "Sélectionner et mettre à jour"                || echo "Select & upgrade" ;;
    menu_dry)           [[ $lang == fr ]] && echo "Dry-run (Simulation)"                         || echo "Dry-run preview" ;;
    menu_hold)          [[ $lang == fr ]] && echo "Gestion des holds"                            || echo "Hold manager" ;;
    menu_logs)          [[ $lang == fr ]] && echo "Historique des logs"                          || echo "Logs history" ;;
    menu_lang)          [[ $lang == fr ]] && echo "Changer la langue"                            || echo "Change language" ;;
    menu_quit)          [[ $lang == fr ]] && echo "Quitter"                                      || echo "Quit" ;;
    menu_security)      [[ $lang == fr ]] && echo "sécurité"                                     || echo "security" ;;
    app_exit)           [[ $lang == fr ]] && echo "Fermeture de l'application."                  || echo "Closing application." ;;
    input_prompt)       [[ $lang == fr ]] && echo "Entrez les numéros (ex: 1 3 5-9) ou 'q' pour annuler: " \
                                          || echo "Enter numbers (e.g. 1 3 5-9) or 'q' to cancel: " ;;
    invalid_input)      [[ $lang == fr ]] && echo "Saisie invalide ou numéro hors plage."        || echo "Invalid selection or number out of bounds." ;;
    hold_manager)       [[ $lang == fr ]] && echo "Gestionnaire de holds"                        || echo "Hold manager" ;;
    held_title)         [[ $lang == fr ]] && echo "Paquets en hold"                              || echo "Held packages" ;;
    no_held)            [[ $lang == fr ]] && echo "Aucun paquet en hold."                        || echo "No held packages." ;;
    hold_apply)         [[ $lang == fr ]] && echo "Appliquer Hold"                               || echo "Apply Hold" ;;
    hold_remove)        [[ $lang == fr ]] && echo "Retirer Hold"                                 || echo "Remove Hold" ;;
    hold_view)          [[ $lang == fr ]] && echo "Voir les paquets figés"                       || echo "View held packages" ;;
    hold_back)          [[ $lang == fr ]] && echo "Retour"                                       || echo "Back" ;;
    sudo_failed)        [[ $lang == fr ]] && echo "Erreur d'authentification ou privilèges refusés. Retour au menu." \
                                          || echo "Authentication failed or privileges denied. Returning to menu." ;;
    update_failed)      [[ $lang == fr ]] && echo "La mise à jour a échoué. Retour au menu."     || echo "Update failed. Returning to menu." ;;
    dryrun_failed)      [[ $lang == fr ]] && echo "La simulation a échoué. Retour au menu."      || echo "Dry-run failed. Returning to menu." ;;
    dryrun_disabled)    [[ $lang == fr ]] && echo "[Mode Simulation Actif] Mise à jour réelle désactivée." \
                                          || echo "[Simulation Mode Active] Real upgrade disabled." ;;
    log_none)           [[ $lang == fr ]] && echo "Pas d'historique de log trouvé."              || echo "No log history found." ;;
    lang_title)         [[ $lang == fr ]] && echo "Langue / Language"                            || echo "Language / Langue" ;;
    *) echo "$key" ;;
  esac
}

# ─────────────────────────────────────────────
#  UTILITAIRES SYSTÈME
# ─────────────────────────────────────────────
run_cmd() {
  if [[ $(id -u) -eq 0 ]]; then "$@"; else sudo "$@"; fi
}

read_tty_line() {
  local __var="$1"
  local prompt="$2"
  if [[ -t 0 ]]; then
    IFS= read -r -p "$prompt" "$__var" < /dev/tty || return 1
  else
    IFS= read -r -p "$prompt" "$__var" || return 1
  fi
}

read_tty_char() {
  local __var="$1"
  if [[ -t 0 ]]; then
    IFS= read -rsn1 "$__var" < /dev/tty || return 1
  else
    IFS= read -rsn1 "$__var" || return 1
  fi
}

with_errexit_disabled() {
  local had_errexit=0
  [[ $- == *e* ]] && had_errexit=1
  set +e
  "$@"
  local rc=$?
  (( had_errexit )) && set -e
  return $rc
}

ensure_sudo() {
  if [[ $(id -u) -ne 0 ]]; then
    echo " "
    # .: ne pas invalider le cache si déjà valide — évite de demander
    # le mot de passe inutilement. On tente -v d'abord, on invalide
    # seulement en cas d'échec pour forcer une vraie saisie.
    if ! sudo -vn 2>/dev/null; then
      sudo -k
      if ! sudo -v 2>/dev/null; then
        echo "  ${FG_RED}✗ $(msg sudo_failed)${RESET}"
        log ERROR "Échec de l'authentification sudo"
        return 1
      fi
    fi
  fi
  return 0
}

# ─────────────────────────────────────────────
#  ÉTAT & TABLEAUX
# ─────────────────────────────────────────────
UPGRADABLE=()
UPGRADABLE_VERSIONS_CUR=()
UPGRADABLE_VERSIONS_NEW=()
UPGRADABLE_TYPES=()
HELD_PACKAGES=()
LAST_REFRESH=""
SELECTED_IDX=()

# ─────────────────────────────────────────────
#  REFRESH
# ─────────────────────────────────────────────
refresh_updates() {
  ensure_sudo || { pause; return 1; }

  _check_resize
  tput clear 2>/dev/null || clear
  echo ""
  echo "  ${BG_YELLOW}${FG_WHITE}${BOLD} ➜ $(msg checking_updates) ${RESET}"
  echo ""

  run_cmd apt-get update

  LAST_REFRESH=$(date '+%Y-%m-%d %H:%M:%S')
  log INFO "apt-get update exécuté"

  UPGRADABLE=()
  UPGRADABLE_VERSIONS_CUR=()
  UPGRADABLE_VERSIONS_NEW=()
  UPGRADABLE_TYPES=()

  # .: utiliser dpkg-query + apt-cache policy pour un parsing fiable,
  # indépendant de la locale et du format de sortie d'apt list.
  local list_raw
  list_raw=$(apt list --upgradable 2>/dev/null | tail -n +2)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    local name="${line%%/*}"
    local rem="${line#*/}"
    # .: extraction robuste — le format est :
    #   nom/repo arch version_new [upgradable from: version_cur]
    local version_new="?"
    local version_cur="?"

    # Extraire la version nouvelle (premier token après "arch ")
    if [[ "$rem" =~ [[:space:]]([^[:space:]]+)[[:space:]] ]]; then
      version_new="${BASH_REMATCH[1]}"
    fi
    # .: pattern insensible à la casse et aux variantes de locale apt
    if [[ "$line" =~ \[upgradable[[:space:]]from:[[:space:]]([^]]+)\] ]] || \
       [[ "$line" =~ \[mise[[:space:]]à[[:space:]]jour[[:space:]]depuis[[:space:]]:?[[:space:]]([^]]+)\] ]]; then
      version_cur="${BASH_REMATCH[1]}"
    fi

    local type_tag="normal"
    # .: vérifier uniquement le champ repo (avant le premier espace)
    # pour éviter les faux positifs sur des noms de paquets contenant "security"
    local repo_field="${rem%%[[:space:]]*}"
    if [[ "$repo_field" == *security* ]]; then
      type_tag="security"
    fi

    UPGRADABLE+=("$name")
    UPGRADABLE_VERSIONS_CUR+=("$version_cur")
    UPGRADABLE_VERSIONS_NEW+=("$version_new")
    UPGRADABLE_TYPES+=("$type_tag")
  done <<< "$list_raw"

  local found=${#UPGRADABLE[@]}
  echo ""
  echo "  ${BG_GREEN}${FG_WHITE}${BOLD} ✓ $(msg refresh_done) ${RESET}"
  # .: chaîne passée par msg() — plus de texte français codé en dur
  echo "  ${FG_GREEN}  Trouvé ${found} $(msg packages_found)${RESET}"
  log INFO "Trouvé ${found} paquets"
  pause
}

# ─────────────────────────────────────────────
#  AFFICHAGE
# ─────────────────────────────────────────────
show_size_info() {
  local output dl disk
  output=$(run_cmd apt-get -s --only-upgrade install "$@" 2>/dev/null || true)
  dl=$(printf '%s\n'   "$output" | grep -E 'Need to get|Il est nécessaire' | head -1 || true)
  disk=$(printf '%s\n' "$output" | grep -E 'After this operation|Après cette' | head -1 || true)
  [[ -n "$dl" ]]   && echo "  ${FG_CYAN}$(msg download_label)${RESET}: $dl"
  [[ -n "$disk" ]] && echo "  ${FG_CYAN}$(msg disk_label)${RESET}:     $disk"
}

_strip_ansi() {
  printf '%s' "$1" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g'
}

_visible_len() {
  local plain; plain=$(_strip_ansi "$1")
  echo "${#plain}"
}

_statusbar() {
  _check_resize
  local hint="$1"
  local right_info; right_info="$(msg app_name) $(msg app_version)"
  local left_plain=" ${hint} "
  local right_plain=" ${right_info} "
  local left_len right_len pad
  left_len=$(_visible_len "$left_plain")
  right_len=$(_visible_len "$right_plain")
  pad=$(( TERM_COLS - left_len - right_len ))
  (( pad < 0 )) && pad=0

  printf '%s' "${BG_BLUE}${FG_WHITE}${BOLD}${left_plain}${RESET}"
  printf '%*s' "$pad" ''
  printf '%s%s\n' "${BG_BLUE}${FG_WHITE}${BOLD}${right_plain}" "${RESET}"
}

_header() {
  _check_resize
  local refresh_info
  if [[ -n "$LAST_REFRESH" ]]; then
    refresh_info="${DIM}$(msg last_refresh): ${LAST_REFRESH}${RESET}"
  else
    refresh_info="${DIM}$(msg last_refresh): $(msg last_refresh_none)${RESET}"
  fi
  echo "  ${FG_BLUE}${BOLD}$(msg app_name)${RESET} ${DIM}$(msg app_version)${RESET}  ·  ${DIM}$(msg app_tagline)${RESET}"
  echo "  ${refresh_info}"
  echo ""
}

_section() {
  local title="$1"
  local count="${2:-}"
  local badge=""
  [[ -n "$count" ]] && badge=" ${DIM}(${count})${RESET}"
  echo "  ${FG_BLUE}${BOLD}▐${RESET} ${BOLD}${title}${RESET}${badge}"
  echo ""
}

_format_pkg_line() {
  local idx=$1 name=$2 type=$3
  local type_tag
  if [[ "$type" == *security* ]]; then
    type_tag="${FG_RED}sec${RESET}"
  else
    type_tag="${DIM}std${RESET}"
  fi
  printf '[%2d] %-24s %s' "$((idx + 1))" "$name" "$type_tag"
}

_draw_two_column_flat() {
  local -n pkgs=$1 types=$2
  local total=${#pkgs[@]}

  if (( total == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_packages)${RESET}"
    return 0
  fi

  local gutter=4
  local col_width=$(( (TERM_COLS - gutter - 6) / 2 ))
  local half=$(( (total + 1) / 2 ))

  for (( i=0; i<half; i++ )); do
    local left_idx=$i
    local right_idx=$(( i + half ))
    local left_text="" right_text=""

    left_text="  $(_format_pkg_line "$left_idx" "${pkgs[$left_idx]}" "${types[$left_idx]}")"

    if (( right_idx < total )); then
      right_text="$(_format_pkg_line "$right_idx" "${pkgs[$right_idx]}" "${types[$right_idx]}")"
    fi

    local vis_l; vis_l=$(_visible_len "$left_text")
    local pad_l=$(( col_width - vis_l + 2 ))
    (( pad_l < 0 )) && pad_l=0
    printf '%s%*s%*s%s\n' "$left_text" "$pad_l" "" "$gutter" "" "$right_text"
  done
  echo
}

# ─────────────────────────────────────────────
#  SÉLECTION
# ─────────────────────────────────────────────
parse_selection() {
  local input="$1" max_val="$2"
  SELECTED_IDX=()
  [[ -z "$input" || "$input" == "q" ]] && return 1

  for part in $input; do
    if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      # .: utiliser les groupes de capture nommés pour éviter
      # l'ambiguïté de ${part%%-*} sur des nombres comme "10-20"
      local start="${BASH_REMATCH[1]}"
      local end="${BASH_REMATCH[2]}"
      if (( start < 1 || end > max_val || start > end )); then return 1; fi
      for (( i=start; i<=end; i++ )); do
        SELECTED_IDX+=("$((i - 1))")
      done
    elif [[ "$part" =~ ^[0-9]+$ ]]; then
      if (( part < 1 || part > max_val )); then return 1; fi
      SELECTED_IDX+=("$((part - 1))")
    else
      return 1
    fi
  done

  # .: dédupliquer les indices pour éviter de mettre à jour
  # deux fois le même paquet si l'utilisateur entre "1 1 2"
  local -A seen=()
  local deduped=()
  for idx in "${SELECTED_IDX[@]}"; do
    if [[ -z "${seen[$idx]+x}" ]]; then
      seen[$idx]=1
      deduped+=("$idx")
    fi
  done
  SELECTED_IDX=("${deduped[@]}")

  return 0
}

# ─────────────────────────────────────────────
#  VUES
# ─────────────────────────────────────────────
do_view_list() {
  _check_resize
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; return
  fi
  tput clear 2>/dev/null || clear
  _header
  _section "$(msg upgradable_title)" "${#UPGRADABLE[@]}"
  _draw_two_column_flat UPGRADABLE UPGRADABLE_TYPES
  _statusbar "$(msg menu_view)"
  pause
}

get_user_selection() {
  local title="$1"
  local -n _pkgs=$2 _types=$3
  local total=${#_pkgs[@]}

  _check_resize
  tput clear 2>/dev/null || clear
  _header
  _section "$title" "$total"

  _draw_two_column_flat _pkgs _types
  _statusbar "$(msg input_prompt)"

  echo ""
  echo -n "  $(msg input_prompt)"
  local user_input
  if ! read_tty_line user_input ""; then
    echo "  $(msg canceled)"
    return 1
  fi

  if [[ "$user_input" == "q" ]]; then
    SELECTED_IDX=()
    return 1
  fi

  if ! parse_selection "$user_input" "$total"; then
    echo "  ${FG_RED}$(msg invalid_input)${RESET}"
    pause
    return 1
  fi
  return 0
}

confirm_timeout() {
  local prompt="$1" timeout="${2:-30}"
  # .: stocker la regex dans une variable locale pour garantir
  # une interprétation correcte par [[ =~ ]] (pas de quotes autour de la var)
  local confirm_re; confirm_re=$(msg confirm_regex)
  local answer="" remaining=$timeout
  tput cnorm 2>/dev/null || true
  while (( remaining > 0 )); do
    printf '\r%s [%ss] ' "$prompt" "$remaining"
    if [[ -t 0 ]]; then
      IFS= read -rsn1 -t 1 answer < /dev/tty || true
    else
      IFS= read -rsn1 -t 1 answer || true
    fi
    if [[ -n "$answer" ]]; then
      echo "$answer"
      [[ "$answer" =~ $confirm_re ]] && return 0 || return 1
    fi
    (( remaining-- ))
  done
  echo ""
  return 1
}

pause() {
  printf '\n  %s' "${DIM}$(msg press_enter)${RESET}"
  read_tty_char _ || true
}

# ─────────────────────────────────────────────
#  UPGRADE
# ─────────────────────────────────────────────
do_select_and_upgrade() {
  with_errexit_disabled do_select_and_upgrade_impl
}

do_select_and_upgrade_impl() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; return
  fi

  ensure_sudo || { pause; return; }

  if ! get_user_selection "$(msg upgradable_title)" UPGRADABLE UPGRADABLE_TYPES; then
    return
  fi

  if (( ${#SELECTED_IDX[@]} == 0 )); then
    echo "  $(msg no_selected)"; pause; return
  fi

  local -a pkgs=()
  _check_resize
  tput clear 2>/dev/null || clear
  _header
  echo "  ${BOLD}$(msg will_update):${RESET}"

  for idx in "${SELECTED_IDX[@]}"; do
    pkgs+=("${UPGRADABLE[$idx]}")
    # .: accès sécurisé aux tableaux — utiliser ${arr[idx]:-?}
    # pour éviter que set -u ne cause un crash si l'index est hors bornes
    local cur_v="${UPGRADABLE_VERSIONS_CUR[$idx]:-?}"
    local new_v="${UPGRADABLE_VERSIONS_NEW[$idx]:-?}"
    echo "    ${FG_GREEN}·${RESET} ${UPGRADABLE[$idx]} ${DIM}${cur_v}${RESET} -> ${FG_GREEN}${new_v}${RESET}"
  done
  echo ""

  show_size_info "${pkgs[@]}"
  echo ""

  if [[ "$DRY_RUN_ONLY" -eq 1 ]]; then
    # .: message passé par msg()
    echo "  ${FG_YELLOW}$(msg dryrun_disabled)${RESET}"
    pause; return
  fi

  if ! confirm_timeout "  $(msg proceed_prompt)" 30; then
    echo "  $(msg canceled)"; pause; return
  fi

  echo ""
  echo "  ${BOLD}$(msg upgrading)${RESET}"
  echo ""

  if ! run_cmd apt-get --show-progress -o Dpkg::Progress-Fancy=1 \
       install --only-upgrade -y "${pkgs[@]}" < /dev/tty; then
    echo "  ${FG_RED}$(msg update_failed)${RESET}"
    log ERROR "Échec mise à jour : ${pkgs[*]}"
    pause
    return
  fi

  log INFO "Paquets mis à jour : ${pkgs[*]}"
  # .: message passé par msg()
  echo "  ${FG_GREEN}$(msg upgrade_ok)${RESET}"

  # Retirer les paquets mis à jour de la liste locale
  # .: reconstruire les tableaux plutôt que de les vider
  # — conserve les paquets non sélectionnés
  local -a new_upgradable=() new_cur=() new_new=() new_types=()
  local -A upgraded=()
  for p in "${pkgs[@]}"; do upgraded["$p"]=1; done

  for (( i=0; i<${#UPGRADABLE[@]}; i++ )); do
    if [[ -z "${upgraded[${UPGRADABLE[$i]}]+x}" ]]; then
      new_upgradable+=("${UPGRADABLE[$i]}")
      new_cur+=("${UPGRADABLE_VERSIONS_CUR[$i]}")
      new_new+=("${UPGRADABLE_VERSIONS_NEW[$i]}")
      new_types+=("${UPGRADABLE_TYPES[$i]}")
    fi
  done
  UPGRADABLE=("${new_upgradable[@]+"${new_upgradable[@]}"}")
  UPGRADABLE_VERSIONS_CUR=("${new_cur[@]+"${new_cur[@]}"}")
  UPGRADABLE_VERSIONS_NEW=("${new_new[@]+"${new_new[@]}"}")
  UPGRADABLE_TYPES=("${new_types[@]+"${new_types[@]}"}")

  pause
}

# ─────────────────────────────────────────────
#  DRY-RUN
# ─────────────────────────────────────────────
do_dry_run() {
  with_errexit_disabled do_dry_run_impl
}

do_dry_run_impl() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; return
  fi

  ensure_sudo || { pause; return; }

  if get_user_selection "$(msg upgradable_title) (Dry-Run)" UPGRADABLE UPGRADABLE_TYPES; then
    local -a pkgs=()
    for idx in "${SELECTED_IDX[@]}"; do pkgs+=("${UPGRADABLE[$idx]}"); done
    echo ""
    if ! run_cmd apt-get --show-progress -o Dpkg::Progress-Fancy=1 \
         install --only-upgrade --dry-run "${pkgs[@]}" < /dev/tty; then
      echo "  ${FG_RED}$(msg dryrun_failed)${RESET}"
      log ERROR "Échec dry-run : ${pkgs[*]}"
      pause
      return
    fi
    # .: message passé par msg()
    echo "  ${FG_GREEN}$(msg dryrun_ok)${RESET}"
    pause
  fi
}

# ─────────────────────────────────────────────
#  HOLD MANAGER
# ─────────────────────────────────────────────
do_hold_manager() {
  while true; do
    _check_resize
    tput clear 2>/dev/null || clear
    _header
    _section "$(msg hold_manager)"
    # .: libellés des options passés par msg()
    echo "  ${BOLD}1${RESET}  $(msg hold_apply)"
    echo "  ${BOLD}2${RESET}  $(msg hold_remove)"
    echo "  ${BOLD}3${RESET}  $(msg hold_view)"
    echo "  ${BOLD}q${RESET}  $(msg hold_back)"
    echo ""
    _statusbar "1-3 action  q $(msg hold_back)"

    local choice
    read_tty_char choice || return
    case "$choice" in
      1)
        ensure_sudo || { pause; continue; }
        if (( ${#UPGRADABLE[@]} == 0 )); then
          echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; continue
        fi
        if get_user_selection "$(msg hold_apply)" UPGRADABLE UPGRADABLE_TYPES; then
          for idx in "${SELECTED_IDX[@]}"; do
            run_cmd apt-mark hold "${UPGRADABLE[$idx]}"
          done
          pause
        fi ;;
      2)
        ensure_sudo || { pause; continue; }
        mapfile -t HELD_PACKAGES < <(apt-mark showhold 2>/dev/null)
        if (( ${#HELD_PACKAGES[@]} == 0 )); then
          echo "  ${FG_YELLOW}$(msg no_held)${RESET}"; pause; continue
        fi
        # .: construire le tableau de types associé plutôt qu'une
        # boucle séparée — les deux tableaux doivent être de même taille
        local -a held_types=()
        for _ in "${HELD_PACKAGES[@]}"; do held_types+=("normal"); done

        if get_user_selection "$(msg hold_remove)" HELD_PACKAGES held_types; then
          for idx in "${SELECTED_IDX[@]}"; do
            run_cmd apt-mark unhold "${HELD_PACKAGES[$idx]}"
          done
          pause
        fi ;;
      3)
        _check_resize
        tput clear 2>/dev/null || clear
        _header
        _section "$(msg held_title)"
        local held_list
        held_list=$(apt-mark showhold 2>/dev/null || true)
        if [[ -z "$held_list" ]]; then
          echo "  ${FG_YELLOW}$(msg no_held)${RESET}"
        else
          echo "$held_list" | while IFS= read -r p; do
            echo "  ${FG_CYAN}·${RESET} $p"
          done
        fi
        pause ;;
      q) return ;;
    esac
  done
}

# ─────────────────────────────────────────────
#  LOGS
# ─────────────────────────────────────────────
do_show_logs() {
  _check_resize
  tput clear 2>/dev/null || clear
  _header
  _section "Logs"
  if [[ -f "$LOG_FILE" ]]; then
    tail -n 20 "$LOG_FILE"
  else
    # .: message passé par msg()
    echo "  ${FG_YELLOW}$(msg log_none)${RESET}"
  fi
  pause
}

# ─────────────────────────────────────────────
#  LANGUE
# ─────────────────────────────────────────────
select_language() {
  _check_resize
  tput clear 2>/dev/null || clear
  _header
  # .: titre passé par msg()
  _section "$(msg lang_title)"
  echo "  ${BOLD}1${RESET}  English"
  echo "  ${BOLD}2${RESET}  Français"
  local lang_choice
  read_tty_char lang_choice || return
  case "$lang_choice" in
    1) LANG_CHOICE="en" ;;
    2) LANG_CHOICE="fr" ;;
  esac
}

# ─────────────────────────────────────────────
#  MENU PRINCIPAL
# ─────────────────────────────────────────────
main_menu() {
  trap 'tput cnorm 2>/dev/null || true; echo ""; echo "  $(msg app_exit)"; echo ""' EXIT INT TERM

  while true; do
    _check_resize
    tput clear 2>/dev/null || clear
    _header
    _section "$(msg menu_title)"

    local pkg_count="${#UPGRADABLE[@]}"
    local sec_count=0
    # .: tester la taille du tableau avant de boucler — évite
    # l'expansion en élément vide avec ${arr[@]:-} quand set -u est actif
    if (( ${#UPGRADABLE_TYPES[@]} > 0 )); then
      for t in "${UPGRADABLE_TYPES[@]}"; do
        [[ "$t" == "security" ]] && (( sec_count++ )) || true
      done
    fi

    local c_pkg="${FG_CYAN}${pkg_count}${RESET}"
    local c_sec=""
    (( sec_count > 0 )) && c_sec="  ${FG_RED}${BOLD}⚠  ${sec_count} $(msg menu_security)${RESET}"

    printf '  %s  %-24s [%s paquets]%s\n' "${BOLD}r${RESET}" "$(msg menu_refresh)" "$c_pkg" "$c_sec"
    printf '  %s  %-24s\n' "${BOLD}v${RESET}" "$(msg menu_view)"
    printf '  %s  %-24s\n' "${BOLD}u${RESET}" "$(msg menu_upgrade)"
    printf '  %s  %-24s\n' "${BOLD}d${RESET}" "$(msg menu_dry)"
    printf '  %s  %-24s\n' "${BOLD}h${RESET}" "$(msg menu_hold)"
    printf '  %s  %-24s\n' "${BOLD}l${RESET}" "$(msg menu_logs)"
    printf '  %s  %-24s\n' "${BOLD}L${RESET}" "$(msg menu_lang)"
    printf '  %s  %-24s\n' "${BOLD}q${RESET}" "$(msg menu_quit)"
    echo ""
    _statusbar "r v u d h  l logs  L $(msg menu_lang)  q quit"

    local choice
    read_tty_char choice || continue
    case "$choice" in
      r) refresh_updates ;;
      v) do_view_list ;;
      u) do_select_and_upgrade ;;
      d) do_dry_run ;;
      h) do_hold_manager ;;
      # .: séparer l (logs) et L (langue) en deux branches distinctes
      # — dans la version originale, l|L absorbait L avant la branche "L",
      # rendant le changement de langue totalement inaccessible
      l) do_show_logs ;;
      L) select_language ;;
      q) exit 0 ;;
    esac
  done
}

main_menu