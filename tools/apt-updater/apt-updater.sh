#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Usage: apt-updater.sh

Interactive updater for apt packages that are currently upgradable.
USAGE
  exit 0
fi

AUTO_REFRESH_ON_START=0
COLUMN_WIDTH=38
ENABLE_COLOR=1
SHOW_BANNER=1
SPINNER_ENABLED=1
LANG_CHOICE="auto" # auto, en, fr

if [[ "$ENABLE_COLOR" -eq 1 ]] && command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold)
  DIM=$(tput dim)
  RESET=$(tput sgr0)
  FG_BLUE=$(tput setaf 4)
  FG_GREEN=$(tput setaf 2)
  FG_YELLOW=$(tput setaf 3)
  FG_RED=$(tput setaf 1)
else
  BOLD=""
  DIM=""
  RESET=""
  FG_BLUE=""
  FG_GREEN=""
  FG_YELLOW=""
  FG_RED=""
fi

UPGRADABLE=()
LAST_REFRESH=""
SELECTED_PACKAGES=()

current_lang() {
  if [[ "$LANG_CHOICE" == "en" || "$LANG_CHOICE" == "fr" ]]; then
    echo "$LANG_CHOICE"
    return 0
  fi
  if [[ "${LANG:-}" == fr* || "${LC_ALL:-}" == fr* || "${LC_MESSAGES:-}" == fr* ]]; then
    echo "fr"
  else
    echo "en"
  fi
}

tr() {
  local key="$1"
  local lang
  lang=$(current_lang)

  case "$key" in
    banner_title) [[ "$lang" == "fr" ]] && echo "apt-updater" || echo "apt-updater" ;;
    banner_tagline) [[ "$lang" == "fr" ]] && echo "CLI moderne pour des mises a jour selectives" || echo "Modern CLI for selective apt upgrades" ;;
    last_refresh) [[ "$lang" == "fr" ]] && echo "Derniere verification" || echo "Last refresh" ;;
    last_refresh_none) [[ "$lang" == "fr" ]] && echo "non effectue" || echo "not run yet" ;;
    press_enter) [[ "$lang" == "fr" ]] && echo "Appuyez sur Entree pour continuer..." || echo "Press Enter to continue..." ;;
    checking_updates) [[ "$lang" == "fr" ]] && echo "Verification des mises a jour" || echo "Checking for updates" ;;
    no_upgradable_loaded) [[ "$lang" == "fr" ]] && echo "Aucune liste chargee. Lancez un refresh d'abord." || echo "No upgradable packages loaded. Run a refresh first." ;;
    upgradable_title) [[ "$lang" == "fr" ]] && echo "Paquets upgradables" || echo "Upgradable packages" ;;
    no_packages_available) [[ "$lang" == "fr" ]] && echo "Aucun paquet disponible." || echo "No packages available." ;;
    no_changes) [[ "$lang" == "fr" ]] && echo "Aucun changement." || echo "No changes." ;;
    no_packages_selected) [[ "$lang" == "fr" ]] && echo "Aucun paquet selectionne." || echo "No packages selected." ;;
    select_packages_prompt) [[ "$lang" == "fr" ]] && echo "Selectionnez des paquets (ex: 1 3 5-7, a=tout, q=quitter): " || echo "Select packages (e.g. 1 3 5-7, a=all, q=quit): " ;;
    select_dry_prompt) [[ "$lang" == "fr" ]] && echo "Selectionnez pour dry-run (ex: 1 3 5-7, a=tout, q=quitter): " || echo "Select packages for dry-run (e.g. 1 3 5-7, a=all, q=quit): " ;;
    select_hold_prompt) [[ "$lang" == "fr" ]] && echo "Selectionnez pour hold (ex: 1 3 5-7, a=tout, q=quitter): " || echo "Select packages to hold (e.g. 1 3 5-7, a=all, q=quit): " ;;
    select_unhold_prompt) [[ "$lang" == "fr" ]] && echo "Selectionnez pour unhold (ex: 1 3 5-7, a=tout, q=quitter): " || echo "Select packages to unhold (e.g. 1 3 5-7, a=all, q=quit): " ;;
    will_update) [[ "$lang" == "fr" ]] && echo "Mise a jour de" || echo "Will update" ;;
    proceed_prompt) [[ "$lang" == "fr" ]] && echo "Continuer ? [y/N]: " || echo "Proceed? [y/N]: " ;;
    canceled) [[ "$lang" == "fr" ]] && echo "Annule." || echo "Canceled." ;;
    upgrading) [[ "$lang" == "fr" ]] && echo "Mise a jour en cours..." || echo "Upgrading..." ;;
    summary) [[ "$lang" == "fr" ]] && echo "Resume" || echo "Summary" ;;
    updated) [[ "$lang" == "fr" ]] && echo "Mises a jour" || echo "Updated" ;;
    status) [[ "$lang" == "fr" ]] && echo "Statut" || echo "Status" ;;
    status_success) [[ "$lang" == "fr" ]] && echo "succes" || echo "success" ;;
    status_failed) [[ "$lang" == "fr" ]] && echo "echec" || echo "failed" ;;
    errors_detected) [[ "$lang" == "fr" ]] && echo "Erreurs detectees" || echo "Errors detected" ;;
    dry_run_for) [[ "$lang" == "fr" ]] && echo "Dry-run pour" || echo "Dry-run for" ;;
    hold_manager) [[ "$lang" == "fr" ]] && echo "Gestion des holds" || echo "Hold manager" ;;
    hold_opt1) [[ "$lang" == "fr" ]] && echo "Hold depuis la liste upgradable" || echo "Hold packages from upgradable list" ;;
    hold_opt2) [[ "$lang" == "fr" ]] && echo "Unhold des paquets" || echo "Unhold packages" ;;
    hold_opt3) [[ "$lang" == "fr" ]] && echo "Voir les paquets en hold" || echo "View held packages" ;;
    hold_opt4) [[ "$lang" == "fr" ]] && echo "Retour" || echo "Back" ;;
    no_held) [[ "$lang" == "fr" ]] && echo "Aucun paquet en hold." || echo "No held packages." ;;
    held_title) [[ "$lang" == "fr" ]] && echo "Paquets en hold" || echo "Held packages" ;;
    holding) [[ "$lang" == "fr" ]] && echo "Mise en hold" || echo "Holding" ;;
    unholding) [[ "$lang" == "fr" ]] && echo "Retrait du hold" || echo "Unholding" ;;
    menu_title) [[ "$lang" == "fr" ]] && echo "Menu" || echo "Menu" ;;
    menu_refresh) [[ "$lang" == "fr" ]] && echo "Refresh de la liste" || echo "Refresh update list" ;;
    menu_view) [[ "$lang" == "fr" ]] && echo "Voir les paquets upgradables" || echo "View upgradable packages" ;;
    menu_upgrade) [[ "$lang" == "fr" ]] && echo "Selectionner et mettre a jour" || echo "Select and upgrade" ;;
    menu_dry) [[ "$lang" == "fr" ]] && echo "Dry-run" || echo "Dry-run preview" ;;
    menu_hold) [[ "$lang" == "fr" ]] && echo "Gestion des holds" || echo "Hold manager" ;;
    menu_help) [[ "$lang" == "fr" ]] && echo "Aide" || echo "Help" ;;
    menu_lang) [[ "$lang" == "fr" ]] && echo "Langue" || echo "Language" ;;
    menu_exit) [[ "$lang" == "fr" ]] && echo "Quitter" || echo "Exit" ;;
    choose_option) [[ "$lang" == "fr" ]] && echo "Choisissez une option" || echo "Choose an option" ;;
    invalid_option) [[ "$lang" == "fr" ]] && echo "Option invalide." || echo "Invalid option." ;;
    bye) [[ "$lang" == "fr" ]] && echo "Salut." || echo "Bye." ;;
    lang_title) [[ "$lang" == "fr" ]] && echo "Langue" || echo "Language" ;;
    lang_current) [[ "$lang" == "fr" ]] && echo "Actuelle" || echo "Current" ;;
    lang_choose) [[ "$lang" == "fr" ]] && echo "Choisir" || echo "Choose" ;;
    lang_en) echo "English" ;;
    lang_fr) echo "Francais" ;;
    download_label) [[ "$lang" == "fr" ]] && echo "Telechargement" || echo "Download" ;;
    disk_label) [[ "$lang" == "fr" ]] && echo "Espace disque" || echo "Disk" ;;
    *) echo "$key" ;;
  esac
}

run_cmd() {
  if [[ $(id -u) -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

ensure_sudo() {
  if [[ $(id -u) -ne 0 ]]; then
    sudo -k
    sudo -v
  fi
}

show_size_info() {
  local -a pkgs=("$@")
  local output
  local download_line
  local disk_line

  output=$(run_cmd apt-get -s --only-upgrade install "${pkgs[@]}" 2>/dev/null || true)
  download_line=$(printf '%s\n' "$output" | grep -E 'Need to get|Il est nécessaire de prendre' | head -n 1)
  disk_line=$(printf '%s\n' "$output" | grep -E 'After this operation|Après cette opération' | head -n 1)

  if [[ -n "$download_line" ]]; then
    echo "$(tr download_label): $download_line"
  fi
  if [[ -n "$disk_line" ]]; then
    echo "$(tr disk_label): $disk_line"
  fi
}

spinner_run() {
  local -r msg="$1"
  shift
  local -a cmd=("$@")
  local -a frames=("-" "\\" "|" "/")
  local i=0

  if [[ "$SPINNER_ENABLED" -eq 0 ]]; then
    ("${cmd[@]}")
    return $?
  fi

  printf '%s' "${DIM}${msg}${RESET} "
  ("${cmd[@]}") >/dev/null 2>&1 &
  local pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    printf '\b%s' "${frames[$((i % ${#frames[@]}))]}"
    i=$((i + 1))
    sleep 0.1
  done

  wait "$pid"
  local exit_code=$?
  if (( exit_code == 0 )); then
    printf '\b%s\n' "${FG_GREEN}done${RESET}"
  else
    printf '\b%s\n' "${FG_RED}failed${RESET}"
  fi
  return "$exit_code"
}

pause() {
  read -r -p "$(tr press_enter)" _
}

print_banner() {
  if [[ "$SHOW_BANNER" -eq 1 ]]; then
    clear
    echo "${FG_BLUE}${BOLD}$(tr banner_title)${RESET}"
    echo "${DIM}$(tr banner_tagline)${RESET}"
    if [[ -n "$LAST_REFRESH" ]]; then
      echo "${DIM}$(tr last_refresh): $LAST_REFRESH${RESET}"
    else
      echo "${DIM}$(tr last_refresh): $(tr last_refresh_none)${RESET}"
    fi
    echo ""
  fi
}

parse_selection() {
  local input="$1"
  local max="$2"
  local -A seen=()
  local -a result=()
  local token

  input="${input//,/ }"

  if [[ -z "$input" ]]; then
    echo ""
    return 0
  fi

  for token in $input; do
    if [[ "$token" == "a" ]]; then
      for ((i=1; i<=max; i++)); do
        seen[$i]=1
      done
      break
    elif [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
      local start=${token%-*}
      local end=${token#*-}
      if (( start < 1 || end < 1 || start > max || end > max || start > end )); then
        echo "Invalid range: $token" >&2
        return 1
      fi
      for ((i=start; i<=end; i++)); do
        seen[$i]=1
      done
    elif [[ "$token" =~ ^[0-9]+$ ]]; then
      if (( token < 1 || token > max )); then
        echo "Invalid index: $token" >&2
        return 1
      fi
      seen[$token]=1
    else
      echo "Invalid token: $token" >&2
      return 1
    fi
  done

  for i in "${!seen[@]}"; do
    result+=("$i")
  done

  printf '%s\n' "${result[@]}" | sort -n
}

refresh_updates() {
  ensure_sudo
  spinner_run "$(tr checking_updates)" run_cmd apt-get update
  LAST_REFRESH=$(date '+%Y-%m-%d %H:%M:%S')
  mapfile -t UPGRADABLE < <(apt list --upgradable 2>/dev/null | tail -n +2 | awk -F/ '{print $1}' | sort -u)
}

print_two_columns() {
  local -a items=("$@")
  local count=${#items[@]}
  local rows=$(( (count + 1) / 2 ))
  local width=$COLUMN_WIDTH

  if (( count == 0 )); then
    return 0
  fi

  for ((i=0; i<rows; i++)); do
    local left_index=$i
    local right_index=$((i + rows))
    local left_text=""
    local right_text=""

    if (( left_index < count )); then
      left_text=$(printf '[%d] %s' "$((left_index + 1))" "${items[$left_index]}")
    fi
    if (( right_index < count )); then
      right_text=$(printf '[%d] %s' "$((right_index + 1))" "${items[$right_index]}")
    fi

    printf "%-${width}s%s\n" "$left_text" "$right_text"
  done
}

list_updates() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "$(tr no_upgradable_loaded)"
    return 0
  fi

  echo "${BOLD}$(tr upgradable_title)${RESET}"
  print_two_columns "${UPGRADABLE[@]}"
}

select_packages() {
  local -n items=$1
  local prompt="$2"

  SELECTED_PACKAGES=()
  if (( ${#items[@]} == 0 )); then
    echo "$(tr no_packages_available)"
    return 1
  fi

  print_two_columns "${items[@]}"
  echo ""
  read -r -p "$prompt" selection

  if [[ "$selection" == "q" ]]; then
    echo "$(tr no_changes)"
    return 1
  fi

  mapfile -t selected_indices < <(parse_selection "$selection" "${#items[@]}")

  if (( ${#selected_indices[@]} == 0 )); then
    echo "$(tr no_packages_selected)"
    return 1
  fi

  for idx in "${selected_indices[@]}"; do
    SELECTED_PACKAGES+=("${items[$((idx - 1))]}")
  done

  return 0
}

select_and_upgrade() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "$(tr no_upgradable_loaded)"
    return 0
  fi

  if ! select_packages UPGRADABLE "$(tr select_packages_prompt)"; then
    return 0
  fi

  echo ""
  echo "$(tr will_update): ${SELECTED_PACKAGES[*]}"
  read -r -p "$(tr proceed_prompt)" confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "$(tr canceled)"
    return 0
  fi

  ensure_sudo
  echo ""
  show_size_info "${SELECTED_PACKAGES[@]}"
  echo "${BOLD}$(tr upgrading)${RESET}"

  local log_file
  local log_file_err
  log_file=$(mktemp)
  log_file_err=$(mktemp)
  if run_cmd apt-get -qq --show-progress -o Dpkg::Progress-Fancy=1 install --only-upgrade -y "${SELECTED_PACKAGES[@]}" \
    1>"$log_file" 2> >(tee "$log_file_err" >&2); then
    echo ""
    echo "${FG_GREEN}${BOLD}$(tr summary)${RESET}"
    echo "$(tr updated): ${#SELECTED_PACKAGES[@]} package(s)"
    echo "$(tr status): $(tr status_success)"
  else
    echo ""
    echo "${FG_RED}${BOLD}$(tr summary)${RESET}"
    echo "$(tr updated): ${#SELECTED_PACKAGES[@]} package(s)"
    echo "$(tr status): $(tr status_failed)"
  fi

  local err_count
  err_count=$(grep -E '^(E:|Err:)' "$log_file" "$log_file_err" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$err_count" != "0" ]]; then
    echo "$(tr errors_detected): $err_count"
    grep -E '^(E:|Err:)' "$log_file" "$log_file_err" 2>/dev/null | head -n 10
  fi
  rm -f "$log_file" "$log_file_err"
}

dry_run_preview() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "$(tr no_upgradable_loaded)"
    return 0
  fi

  if ! select_packages UPGRADABLE "$(tr select_dry_prompt)"; then
    return 0
  fi

  echo ""
  echo "$(tr dry_run_for): ${SELECTED_PACKAGES[*]}"
  echo ""
  ensure_sudo
  run_cmd apt-get --show-progress -o Dpkg::Progress-Fancy=1 install --only-upgrade --dry-run "${SELECTED_PACKAGES[@]}"
}

manage_holds() {
  while true; do
    echo "${BOLD}$(tr hold_manager)${RESET}"
    echo "  1) $(tr hold_opt1)"
    echo "  2) $(tr hold_opt2)"
    echo "  3) $(tr hold_opt3)"
    echo "  4) $(tr hold_opt4)"
    echo ""
    read -r -p "$(tr choose_option) [1-4]: " hold_choice
    echo ""

    case "$hold_choice" in
      1)
        if (( ${#UPGRADABLE[@]} == 0 )); then
          echo "$(tr no_upgradable_loaded)"
          pause
          continue
        fi
        if select_packages UPGRADABLE "$(tr select_hold_prompt)"; then
          ensure_sudo
          echo "$(tr holding): ${SELECTED_PACKAGES[*]}"
          run_cmd apt-mark hold "${SELECTED_PACKAGES[@]}"
        fi
        pause
        ;;
      2)
        mapfile -t held < <(apt-mark showhold 2>/dev/null | sort -u)
        if (( ${#held[@]} == 0 )); then
          echo "$(tr no_held)"
          pause
          continue
        fi
        if select_packages held "$(tr select_unhold_prompt)"; then
          ensure_sudo
          echo "$(tr unholding): ${SELECTED_PACKAGES[*]}"
          run_cmd apt-mark unhold "${SELECTED_PACKAGES[@]}"
        fi
        pause
        ;;
      3)
        mapfile -t held < <(apt-mark showhold 2>/dev/null | sort -u)
        if (( ${#held[@]} == 0 )); then
          echo "$(tr no_held)"
        else
          echo "${BOLD}$(tr held_title)${RESET}"
          print_two_columns "${held[@]}"
        fi
        pause
        ;;
      4)
        return 0
        ;;
      *)
        echo "$(tr invalid_option)"
        pause
        ;;
    esac
  done
}

show_help() {
  clear
  echo "${FG_BLUE}${BOLD}apt-updater - $(tr menu_help)${RESET}"
  echo ""

  if [[ $(current_lang) == "fr" ]]; then
    echo "- Refresh : lance apt update et charge la liste upgradable."
    echo "- View : affiche les paquets en deux colonnes."
    echo "- Upgrade : selection des paquets puis only-upgrade."
    echo "- Dry-run : simulation sans modification."
    echo "- Hold : bloque des paquets (apt-mark hold)."
  else
    echo "- Refresh: runs apt update and loads the upgradable list."
    echo "- View: shows upgradable packages in two columns."
    echo "- Upgrade: select packages and run only-upgrade."
    echo "- Dry-run: simulate an upgrade without changes."
    echo "- Hold: prevent upgrades for selected packages (apt-mark hold)."
  fi
  echo ""
  pause
}

select_language() {
  local current
  current=$(current_lang)

  clear
  echo "${FG_BLUE}${BOLD}$(tr lang_title)${RESET}"
  echo ""
  echo "$(tr lang_current): $current"
  echo ""
  echo "  1) $(tr lang_en)"
  echo "  2) $(tr lang_fr)"
  echo "  3) Auto"
  echo ""
  read -r -p "$(tr lang_choose) [1-3]: " choice

  case "$choice" in
    1) LANG_CHOICE="en" ;;
    2) LANG_CHOICE="fr" ;;
    3) LANG_CHOICE="auto" ;;
    *)
      echo "$(tr invalid_option)"
      pause
      ;;
  esac
}

main_menu() {
  if [[ "$AUTO_REFRESH_ON_START" -eq 1 ]]; then
    refresh_updates
  fi

  while true; do
    print_banner
    echo "${BOLD}$(tr menu_title)${RESET}"
    echo "  1) $(tr menu_refresh)"
    echo "  2) $(tr menu_view)"
    echo "  3) $(tr menu_upgrade)"
    echo "  4) $(tr menu_dry)"
    echo "  5) $(tr menu_hold)"
    echo "  6) $(tr menu_help)"
    echo "  7) $(tr menu_lang)"
    echo "  8) $(tr menu_exit)"
    echo ""
    read -r -p "$(tr choose_option) [1-8]: " choice
    echo ""

    case "$choice" in
      1)
        refresh_updates
        pause
        ;;
      2)
        list_updates
        pause
        ;;
      3)
        select_and_upgrade
        pause
        ;;
      4)
        dry_run_preview
        pause
        ;;
      5)
        manage_holds
        ;;
      6)
        show_help
        ;;
      7)
        select_language
        ;;
      8)
        echo "$(tr bye)"
        exit 0
        ;;
      *)
        echo "$(tr invalid_option)"
        pause
        ;;
    esac
  done
}

main_menu
