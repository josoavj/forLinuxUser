#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Usage: apt-updater.sh

Interactive updater for apt packages that are currently upgradable.
USAGE
  exit 0
fi

run_cmd() {
  if [[ $(id -u) -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
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

run_cmd apt-get update

mapfile -t upgradable < <(apt list --upgradable 2>/dev/null | tail -n +2 | awk -F/ '{print $1}' | sort -u)

if (( ${#upgradable[@]} == 0 )); then
  echo "No upgradable packages found."
  exit 0
fi

echo "Upgradable packages:"
for i in "${!upgradable[@]}"; do
  printf '[%d] %s\n' "$((i + 1))" "${upgradable[$i]}"
done

echo ""
read -r -p "Select packages to update (e.g. 1 3 5-7, a=all, q=quit): " selection

if [[ "$selection" == "q" ]]; then
  echo "No changes."
  exit 0
fi

mapfile -t selected_indices < <(parse_selection "$selection" "${#upgradable[@]}")

if (( ${#selected_indices[@]} == 0 )); then
  echo "No packages selected."
  exit 0
fi

selected_packages=()
for idx in "${selected_indices[@]}"; do
  selected_packages+=("${upgradable[$((idx - 1))]}")
done

echo ""
echo "Will update: ${selected_packages[*]}"
read -r -p "Proceed? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Canceled."
  exit 0
fi

run_cmd apt-get install --only-upgrade -y "${selected_packages[@]}"
