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
  read -r -p "Press Enter to continue..." _
}

print_banner() {
  if [[ "$SHOW_BANNER" -eq 1 ]]; then
    clear
    echo "${FG_BLUE}${BOLD}apt-updater${RESET}"
    echo "${DIM}Modern CLI for selective apt upgrades${RESET}"
    if [[ -n "$LAST_REFRESH" ]]; then
      echo "${DIM}Last refresh: $LAST_REFRESH${RESET}"
    else
      echo "${DIM}Last refresh: not run yet${RESET}"
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
  spinner_run "Checking for updates" run_cmd apt-get update
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
    echo "No upgradable packages loaded. Run a refresh first."
    return 0
  fi

  echo "${BOLD}Upgradable packages${RESET}"
  print_two_columns "${UPGRADABLE[@]}"
}

select_packages() {
  local -n items=$1
  local prompt="$2"

  SELECTED_PACKAGES=()
  if (( ${#items[@]} == 0 )); then
    echo "No packages available."
    return 1
  fi

  print_two_columns "${items[@]}"
  echo ""
  read -r -p "$prompt" selection

  if [[ "$selection" == "q" ]]; then
    echo "No changes."
    return 1
  fi

  mapfile -t selected_indices < <(parse_selection "$selection" "${#items[@]}")

  if (( ${#selected_indices[@]} == 0 )); then
    echo "No packages selected."
    return 1
  fi

  for idx in "${selected_indices[@]}"; do
    SELECTED_PACKAGES+=("${items[$((idx - 1))]}")
  done

  return 0
}

select_and_upgrade() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "No package list loaded. Run refresh first."
    return 0
  fi

  if ! select_packages UPGRADABLE "Select packages (e.g. 1 3 5-7, a=all, q=quit): "; then
    return 0
  fi

  echo ""
  echo "Will update: ${SELECTED_PACKAGES[*]}"
  read -r -p "Proceed? [y/N]: " confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Canceled."
    return 0
  fi

  ensure_sudo
  echo "${BOLD}Upgrading...${RESET}"

  local log_file
  log_file=$(mktemp)
  if run_cmd apt-get --show-progress -o Dpkg::Progress-Fancy=1 install --only-upgrade -y "${SELECTED_PACKAGES[@]}" | tee "$log_file"; then
    echo ""
    echo "${FG_GREEN}${BOLD}Summary${RESET}"
    echo "Updated: ${#SELECTED_PACKAGES[@]} package(s)"
    echo "Status: success"
  else
    echo ""
    echo "${FG_RED}${BOLD}Summary${RESET}"
    echo "Updated: ${#SELECTED_PACKAGES[@]} package(s)"
    echo "Status: failed"
  fi

  local err_count
  err_count=$(grep -E '^(E:|Err:)' "$log_file" | wc -l | tr -d ' ')
  if [[ "$err_count" != "0" ]]; then
    echo "Errors detected: $err_count"
    grep -E '^(E:|Err:)' "$log_file" | head -n 10
  fi
  rm -f "$log_file"
}

dry_run_preview() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "No package list loaded. Run refresh first."
    return 0
  fi

  if ! select_packages UPGRADABLE "Select packages for dry-run (e.g. 1 3 5-7, a=all, q=quit): "; then
    return 0
  fi

  echo ""
  echo "Dry-run for: ${SELECTED_PACKAGES[*]}"
  echo ""
  ensure_sudo
  run_cmd apt-get --show-progress -o Dpkg::Progress-Fancy=1 install --only-upgrade --dry-run "${SELECTED_PACKAGES[@]}"
}

manage_holds() {
  while true; do
    echo "${BOLD}Hold manager${RESET}"
    echo "  1) Hold packages from upgradable list"
    echo "  2) Unhold packages"
    echo "  3) View held packages"
    echo "  4) Back"
    echo ""
    read -r -p "Choose an option [1-4]: " hold_choice
    echo ""

    case "$hold_choice" in
      1)
        if (( ${#UPGRADABLE[@]} == 0 )); then
          echo "No package list loaded. Run refresh first."
          pause
          continue
        fi
        if select_packages UPGRADABLE "Select packages to hold (e.g. 1 3 5-7, a=all, q=quit): "; then
          ensure_sudo
          echo "Holding: ${SELECTED_PACKAGES[*]}"
          run_cmd apt-mark hold "${SELECTED_PACKAGES[@]}"
        fi
        pause
        ;;
      2)
        mapfile -t held < <(apt-mark showhold 2>/dev/null | sort -u)
        if (( ${#held[@]} == 0 )); then
          echo "No held packages."
          pause
          continue
        fi
        if select_packages held "Select packages to unhold (e.g. 1 3 5-7, a=all, q=quit): "; then
          ensure_sudo
          echo "Unholding: ${SELECTED_PACKAGES[*]}"
          run_cmd apt-mark unhold "${SELECTED_PACKAGES[@]}"
        fi
        pause
        ;;
      3)
        mapfile -t held < <(apt-mark showhold 2>/dev/null | sort -u)
        if (( ${#held[@]} == 0 )); then
          echo "No held packages."
        else
          echo "${BOLD}Held packages${RESET}"
          print_two_columns "${held[@]}"
        fi
        pause
        ;;
      4)
        return 0
        ;;
      *)
        echo "Invalid option."
        pause
        ;;
    esac
  done
}

show_help() {
  clear
  echo "${FG_BLUE}${BOLD}apt-updater - Help${RESET}"
  echo ""
  echo "${BOLD}EN${RESET}"
  echo "- Refresh: runs apt update and loads the upgradable list."
  echo "- View: shows upgradable packages in two columns."
  echo "- Upgrade: select packages and run only-upgrade."
  echo "- Dry-run: simulate an upgrade without changes."
  echo "- Hold: prevent upgrades for selected packages (apt-mark hold)."
  echo ""
  echo "${BOLD}FR${RESET}"
  echo "- Refresh : lance apt update et charge la liste upgradable."
  echo "- View : affiche les paquets en deux colonnes."
  echo "- Upgrade : selection des paquets puis only-upgrade."
  echo "- Dry-run : simulation sans modification."
  echo "- Hold : bloque des paquets (apt-mark hold)."
  echo ""
  pause
}

main_menu() {
  if [[ "$AUTO_REFRESH_ON_START" -eq 1 ]]; then
    refresh_updates
  fi

  while true; do
    print_banner
    echo "${BOLD}Menu${RESET}"
    echo "  1) Refresh update list"
    echo "  2) View upgradable packages"
    echo "  3) Select and upgrade"
    echo "  4) Dry-run preview"
    echo "  5) Hold manager"
    echo "  6) Help"
    echo "  7) Exit"
    echo ""
    read -r -p "Choose an option [1-7]: " choice
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
        echo "Bye."
        exit 0
        ;;
      *)
        echo "Invalid option."
        pause
        ;;
    esac
  done
}

main_menu
