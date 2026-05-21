#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Usage: apt-updater.sh

Interactive updater for apt packages that are currently upgradable.
USAGE
  exit 0
fi

if command -v tput >/dev/null 2>&1; then
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

run_cmd() {
  if [[ $(id -u) -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

spinner_run() {
  local -r msg="$1"
  shift
  local -a cmd=("$@")
  local -a frames=("-" "\\" "|" "/")
  local i=0

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
  clear
  echo "${FG_BLUE}${BOLD}apt-updater${RESET}"
  echo "${DIM}Modern CLI for selective apt upgrades${RESET}"
  if [[ -n "$LAST_REFRESH" ]]; then
    echo "${DIM}Last refresh: $LAST_REFRESH${RESET}"
  else
    echo "${DIM}Last refresh: not run yet${RESET}"
  fi
  echo ""
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
  spinner_run "Checking for updates" run_cmd apt-get update
  LAST_REFRESH=$(date '+%Y-%m-%d %H:%M:%S')
  mapfile -t UPGRADABLE < <(apt list --upgradable 2>/dev/null | tail -n +2 | awk -F/ '{print $1}' | sort -u)
}

list_updates() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "No upgradable packages loaded. Run a refresh first."
    return 0
  fi

  echo "${BOLD}Upgradable packages${RESET}"
  for i in "${!UPGRADABLE[@]}"; do
    printf '[%d] %s\n' "$((i + 1))" "${UPGRADABLE[$i]}"
  done
}

select_and_upgrade() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "No package list loaded. Run refresh first."
    return 0
  fi

  list_updates
  echo ""
  read -r -p "Select packages (e.g. 1 3 5-7, a=all, q=quit): " selection

  if [[ "$selection" == "q" ]]; then
    echo "No changes."
    return 0
  fi

  mapfile -t selected_indices < <(parse_selection "$selection" "${#UPGRADABLE[@]}")

  if (( ${#selected_indices[@]} == 0 )); then
    echo "No packages selected."
    return 0
  fi

  local -a selected_packages=()
  for idx in "${selected_indices[@]}"; do
    selected_packages+=("${UPGRADABLE[$((idx - 1))]}")
  done

  echo ""
  echo "Will update: ${selected_packages[*]}"
  read -r -p "Proceed? [y/N]: " confirm

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Canceled."
    return 0
  fi

  spinner_run "Upgrading selected packages" run_cmd apt-get install --only-upgrade -y "${selected_packages[@]}"
}

main_menu() {
  while true; do
    print_banner
    echo "${BOLD}Menu${RESET}"
    echo "  1) Refresh update list"
    echo "  2) View upgradable packages"
    echo "  3) Select and upgrade"
    echo "  4) Exit"
    echo ""
    read -r -p "Choose an option [1-4]: " choice
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
