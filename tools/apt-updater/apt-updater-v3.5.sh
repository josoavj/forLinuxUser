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
    # FIX: regex stockée dans une variable locale pour éviter tout problème d'interprétation
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
    refresh_title)      [[ $lang == fr ]] && echo "Mise à jour des sources"                      || echo "Updating package sources" ;;
    refresh_step1)      [[ $lang == fr ]] && echo "Synchronisation des sources apt"              || echo "Synchronising apt sources" ;;
    refresh_step2)      [[ $lang == fr ]] && echo "Lecture de la liste upgradable"               || echo "Reading upgradable list" ;;
    refresh_step3)      [[ $lang == fr ]] && echo "Analyse terminée"                             || echo "Analysis complete" ;;
    refresh_running)    [[ $lang == fr ]] && echo "Mise à jour en cours…  Ctrl-C pour annuler"  || echo "Refreshing…  Ctrl-C to cancel" ;;
    refresh_done_hint)  [[ $lang == fr ]] && echo "Entrée pour continuer"                        || echo "Press Enter to continue" ;;
    refresh_apt_failed) [[ $lang == fr ]] && echo "apt-get update a échoué. Vérifiez votre connexion ou les sources." \
                                          || echo "apt-get update failed. Check your connection or sources." ;;
    refresh_uptodate)   [[ $lang == fr ]] && echo "Système à jour — aucun paquet à mettre à jour." \
                                          || echo "System is up to date — nothing to upgrade." ;;
    upgrade_title)      [[ $lang == fr ]] && echo "Installation des mises à jour"                || echo "Installing upgrades" ;;
    dryrun_title)       [[ $lang == fr ]] && echo "Simulation de mise à jour"                    || echo "Upgrade dry-run" ;;
    upgrade_step1)      [[ $lang == fr ]] && echo "Authentification sudo"                         || echo "Sudo authentication" ;;
    upgrade_step2)      [[ $lang == fr ]] && echo "Téléchargement et installation"               || echo "Download and install" ;;
    upgrade_step3)      [[ $lang == fr ]] && echo "Finalisation"                                 || echo "Finalising" ;;
    upgrade_running)    [[ $lang == fr ]] && echo "Installation en cours…  Ctrl-C pour annuler" || echo "Installing…  Ctrl-C to cancel" ;;
    upgrade_count_label)[[ $lang == fr ]] && echo "opération(s) apt détectée(s)"                || echo "apt operation(s) detected" ;;
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
    # FIX: ne pas invalider le cache si déjà valide — évite de demander
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
#  REFRESH — UI ANIMÉE
# ─────────────────────────────────────────────

# Dessine le cadre statique de la page refresh (titre + 3 étapes + zone log)
# Positions des lignes (0-based depuis le haut de l'écran) :
#   0-2   : marges
#   3     : titre
#   5     : étape 1 — apt-get update
#   6     : étape 2 — lecture de la liste
#   7     : étape 3 — résumé
#   9     : ligne de log défilant
#   11    : barre de progression
#   13    : statusbar
_refresh_ROW_TITLE=2
_refresh_ROW_STEP1=5
_refresh_ROW_STEP2=7
_refresh_ROW_STEP3=9
_refresh_ROW_LOG=11
_refresh_ROW_BAR=13
_refresh_ROW_STATUS=15

# États des étapes : 0=en attente  1=en cours  2=ok  3=erreur
_refresh_draw_frame() {
  _check_resize
  tput clear 2>/dev/null || clear
  tput civis 2>/dev/null || true   # masquer le curseur

  # — Titre
  tput cup "$_refresh_ROW_TITLE" 0
  printf '  %s%s%s  %s·%s  %s' \
    "${FG_BLUE}${BOLD}" "$(msg app_name)" "${RESET}" \
    "${DIM}" "${RESET}" \
    "${DIM}$(msg refresh_title)${RESET}"

  # — Les 3 étapes (état initial : en attente)
  _refresh_draw_step "$_refresh_ROW_STEP1" 0 "$(msg refresh_step1)"
  _refresh_draw_step "$_refresh_ROW_STEP2" 0 "$(msg refresh_step2)"
  _refresh_draw_step "$_refresh_ROW_STEP3" 0 "$(msg refresh_step3)"

  # — Barre vide
  _refresh_draw_bar 0

  # — Statusbar
  tput cup "$_refresh_ROW_STATUS" 0
  _statusbar "$(msg refresh_running)"
}

# Dessine une étape à la ligne $1, état $2 (0=wait 1=run 2=ok 3=err), label $3
_refresh_draw_step() {
  local row="$1" state="$2" label="$3"
  local icon color
  case "$state" in
    0) icon="○" ; color="${DIM}" ;;
    1) icon="◉" ; color="${FG_CYAN}${BOLD}" ;;
    2) icon="✓" ; color="${FG_GREEN}${BOLD}" ;;
    3) icon="✗" ; color="${FG_RED}${BOLD}" ;;
  esac
  tput cup "$row" 0
  # Effacer la ligne entière avant de réécrire
  tput el 2>/dev/null || printf '\033[2K'
  printf '  %s%s%s  %s' "$color" "$icon" "${RESET}" "$label"
}

# Dessine la barre de progression : $1 = pourcentage 0-100
_refresh_draw_bar() {
  local pct="$1"
  local inner=$(( TERM_COLS - 6 ))
  (( inner < 10 )) && inner=10
  local filled=$(( pct * inner / 100 ))
  local empty=$(( inner - filled ))

  tput cup "$_refresh_ROW_BAR" 0
  tput el 2>/dev/null || printf '\033[2K'
  printf '  %s[%s%s%s%s%s]%s  %s%3d%%%s' \
    "${DIM}" \
    "${RESET}${FG_CYAN}${BOLD}" \
    "$(printf '%*s' "$filled" '' | tr ' ' '█')" \
    "${RESET}${DIM}" \
    "$(printf '%*s' "$empty"  '' | tr ' ' '░')" \
    "${RESET}${DIM}" "${RESET}" \
    "${FG_CYAN}${BOLD}" "$pct" "${RESET}"
}

# Affiche une ligne de log défilant à la ligne dédiée (tronquée à TERM_COLS-4)
_refresh_draw_log() {
  local line="$1"
  local maxlen=$(( TERM_COLS - 4 ))
  (( maxlen < 10 )) && maxlen=10
  # Tronquer si trop long
  if (( ${#line} > maxlen )); then
    line="${line:0:$(( maxlen - 1 ))}…"
  fi
  tput cup "$_refresh_ROW_LOG" 0
  tput el 2>/dev/null || printf '\033[2K'
  printf '  %s%s%s' "${DIM}" "$line" "${RESET}"
}

# Anime un spinner sur la ligne $1 pendant que le PID $2 tourne.
# Met à jour la progression en parsant un fichier temporaire écrit
# par le lecteur de pipe en parallèle.
# $3 = fichier de compteur (écrit par le lecteur apt)
# $4 = total estimé de sources (pour le %)
_refresh_spin_while() {
  local row="$1" pid="$2" cntfile="$3" total_src="$4" label="$5"
  local frames=('◉' '◎' '◉' '◌')
  local fi=0
  local color="${FG_CYAN}${BOLD}"

  while kill -0 "$pid" 2>/dev/null; do
    local fetched=0
    [[ -f "$cntfile" ]] && fetched=$(cat "$cntfile" 2>/dev/null || echo 0)
    local pct=0
    if (( total_src > 0 && fetched > 0 )); then
      pct=$(( fetched * 90 / total_src ))   # on garde 10% pour la phase parse
      (( pct > 90 )) && pct=90
    else
      # Pas de total connu : animation indéterminée (va jusqu'à 50%)
      (( pct < 50 )) && pct=$(( pct + 1 ))
    fi

    tput cup "$row" 0
    tput el 2>/dev/null || printf '\033[2K'
    printf '  %s%s%s  %s' \
      "$color" "${frames[$fi]}" "${RESET}" "$label"

    _refresh_draw_bar "$pct"
    fi=$(( (fi + 1) % ${#frames[@]} ))
    sleep 0.12
  done
}

# Fonction principale de refresh
refresh_updates() {
  ensure_sudo || { pause; return 1; }

  _check_resize
  _refresh_draw_frame

  # ── Étape 1 : apt-get update ──────────────────────────────────────────
  _refresh_draw_step "$_refresh_ROW_STEP1" 1 "$(msg refresh_step1)"

  # Fichiers temporaires
  local tmpdir; tmpdir=$(mktemp -d)
  local pipe_log="${tmpdir}/apt.log"
  local cnt_file="${tmpdir}/fetched_count"
  local total_file="${tmpdir}/total_src"
  echo 0 > "$cnt_file"
  echo 0 > "$total_file"
  mkfifo "$pipe_log"

  # Lancer apt-get update ; stdout+stderr → pipe
  run_cmd apt-get update > "$pipe_log" 2>&1 &
  local apt_pid=$!

  # Lecteur du pipe en arrière-plan : parse les lignes apt et met à jour
  # cnt_file + affiche le log défilant
  (
    local fetched=0 total=0
    while IFS= read -r aptline; do
      # Compter les sources (Hit:/Get:/Ign:)
      if [[ "$aptline" =~ ^(Get|Hit|Ign):[0-9] ]]; then
        (( fetched++ )) || true
        echo "$fetched" > "$cnt_file"
      fi
      # Détecter le total de sources depuis la ligne "Reading package lists"
      if [[ "$aptline" =~ ^Fetched ]] || [[ "$aptline" =~ ^[0-9]+[[:space:]]+(packages|paquets) ]]; then
        echo "$fetched" > "$total_file"
      fi
      # Afficher la ligne de log (depuis le process principal via tput)
      # On écrit dans un second fichier lu par le spinner
      printf '%s\n' "$aptline" >> "${tmpdir}/lastlog"
    done < "$pipe_log"
  ) &
  local reader_pid=$!

  # Spinner + barre de progression pendant apt-get update
  local total_src=0
  local fi=0
  local frames=('◉' '◎' '◉' '◌')
  while kill -0 "$apt_pid" 2>/dev/null; do
    local fetched=0
    [[ -f "$cnt_file" ]] && fetched=$(cat "$cnt_file" 2>/dev/null || echo 0)
    # Lire la dernière ligne de log et l'afficher
    if [[ -f "${tmpdir}/lastlog" ]]; then
      local lastline
      lastline=$(tail -1 "${tmpdir}/lastlog" 2>/dev/null || true)
      [[ -n "$lastline" ]] && _refresh_draw_log "$lastline"
    fi

    local pct=0
    if (( fetched > 3 )); then
      # Estimation souple : 1 source ≈ 3-4% jusqu'à 85%
      pct=$(( fetched * 4 ))
      (( pct > 85 )) && pct=85
    fi

    tput cup "$_refresh_ROW_STEP1" 0
    tput el 2>/dev/null || printf '\033[2K'
    printf '  %s%s%s  %s' \
      "${FG_CYAN}${BOLD}" "${frames[$fi]}" "${RESET}" "$(msg refresh_step1)"

    _refresh_draw_bar "$pct"
    fi=$(( (fi + 1) % 4 ))
    sleep 0.12
  done

  wait "$apt_pid"
  local apt_exit=$?
  wait "$reader_pid" 2>/dev/null || true

  # Vider la ligne de log
  tput cup "$_refresh_ROW_LOG" 0
  tput el 2>/dev/null || printf '\033[2K'

  if (( apt_exit != 0 )); then
    _refresh_draw_step "$_refresh_ROW_STEP1" 3 "$(msg refresh_step1)"
    _refresh_draw_bar 0
    tput cup $(( _refresh_ROW_STATUS + 2 )) 0
    echo ""
    echo "  ${FG_RED}$(msg refresh_apt_failed)${RESET}"
    log ERROR "apt-get update a échoué (exit $apt_exit)"
    rm -rf "$tmpdir"
    tput cnorm 2>/dev/null || true
    pause; return 1
  fi

  _refresh_draw_step "$_refresh_ROW_STEP1" 2 "$(msg refresh_step1)"
  _refresh_draw_bar 90

  LAST_REFRESH=$(date '+%Y-%m-%d %H:%M:%S')
  log INFO "apt-get update exécuté"

  # ── Étape 2 : lecture de la liste upgradable ──────────────────────────
  _refresh_draw_step "$_refresh_ROW_STEP2" 1 "$(msg refresh_step2)"

  UPGRADABLE=()
  UPGRADABLE_VERSIONS_CUR=()
  UPGRADABLE_VERSIONS_NEW=()
  UPGRADABLE_TYPES=()

  local list_raw
  list_raw=$(apt list --upgradable 2>/dev/null | tail -n +2)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    local name="${line%%/*}"
    local rem="${line#*/}"
    local version_new="?"
    local version_cur="?"

    if [[ "$rem" =~ [[:space:]]([^[:space:]]+)[[:space:]] ]]; then
      version_new="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ \[upgradable[[:space:]]from:[[:space:]]([^]]+)\] ]] || \
       [[ "$line" =~ \[mise[[:space:]]à[[:space:]]jour[[:space:]]depuis[[:space:]]:?[[:space:]]([^]]+)\] ]]; then
      version_cur="${BASH_REMATCH[1]}"
    fi

    local type_tag="normal"
    local repo_field="${rem%%[[:space:]]*}"
    if [[ "$repo_field" == *security* ]]; then
      type_tag="security"
    fi

    UPGRADABLE+=("$name")
    UPGRADABLE_VERSIONS_CUR+=("$version_cur")
    UPGRADABLE_VERSIONS_NEW+=("$version_new")
    UPGRADABLE_TYPES+=("$type_tag")
  done <<< "$list_raw"

  _refresh_draw_step "$_refresh_ROW_STEP2" 2 "$(msg refresh_step2)"
  _refresh_draw_bar 97

  rm -rf "$tmpdir"

  # ── Étape 3 : résumé ─────────────────────────────────────────────────
  local found=${#UPGRADABLE[@]}
  local sec_count=0
  if (( ${#UPGRADABLE_TYPES[@]} > 0 )); then
    for t in "${UPGRADABLE_TYPES[@]}"; do
      [[ "$t" == "security" ]] && (( sec_count++ )) || true
    done
  fi

  _refresh_draw_step "$_refresh_ROW_STEP3" 2 "$(msg refresh_step3)"
  _refresh_draw_bar 100

  # — Ligne de résumé sous la barre
  tput cup $(( _refresh_ROW_BAR + 2 )) 0
  tput el 2>/dev/null || printf '\033[2K'
  if (( found == 0 )); then
    printf '  %s✓ %s%s\n' "${FG_GREEN}${BOLD}" "$(msg refresh_uptodate)" "${RESET}"
  else
    printf '  %s✓ %s%s' "${FG_GREEN}${BOLD}" "" "${RESET}"
    printf '%s%d%s %s' "${FG_CYAN}${BOLD}" "$found" "${RESET}" "$(msg packages_found)"
    if (( sec_count > 0 )); then
      printf '  %s⚠ %d %s%s' "${FG_RED}${BOLD}" "$sec_count" "$(msg menu_security)" "${RESET}"
    fi
    printf '\n'
  fi

  # — Statusbar finale
  tput cup "$_refresh_ROW_STATUS" 0
  _statusbar "$(msg refresh_done_hint)"

  log INFO "Trouvé ${found} paquets (${sec_count} sécurité)"
  tput cnorm 2>/dev/null || true
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
      # FIX: utiliser les groupes de capture nommés pour éviter
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

  # FIX: dédupliquer les indices pour éviter de mettre à jour
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
  # FIX: stocker la regex dans une variable locale pour garantir
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
#  UPGRADE — UI ANIMÉE
# ─────────────────────────────────────────────

# Positions des lignes pour l'écran d'upgrade :
#   0     : marge
#   1     : titre
#   3     : étape 1 — sudo
#   5     : étape 2 — téléchargement / install
#   7     : étape 3 — nettoyage / finalisation
#   9     : ligne de log défilant (sortie apt)
#   11    : barre de progression
#   13    : compteur paquets traités
#   15    : statusbar
_upgrade_ROW_TITLE=1
_upgrade_ROW_STEP1=3
_upgrade_ROW_STEP2=5
_upgrade_ROW_STEP3=7
_upgrade_ROW_LOG=9
_upgrade_ROW_BAR=11
_upgrade_ROW_COUNT=13
_upgrade_ROW_STATUS=15

_upgrade_draw_step() {
  local row="$1" state="$2" label="$3"
  local icon color
  case "$state" in
    0) icon="○" ; color="${DIM}" ;;
    1) icon="◉" ; color="${FG_CYAN}${BOLD}" ;;
    2) icon="✓" ; color="${FG_GREEN}${BOLD}" ;;
    3) icon="✗" ; color="${FG_RED}${BOLD}" ;;
  esac
  tput cup "$row" 0
  tput el 2>/dev/null || printf '\033[2K'
  printf '  %s%s%s  %s' "$color" "$icon" "${RESET}" "$label"
}

_upgrade_draw_bar() {
  local pct="$1"
  local inner=$(( TERM_COLS - 6 ))
  (( inner < 10 )) && inner=10
  local filled=$(( pct * inner / 100 ))
  local empty=$(( inner - filled ))
  tput cup "$_upgrade_ROW_BAR" 0
  tput el 2>/dev/null || printf '\033[2K'
  printf '  %s[%s%s%s%s%s]%s  %s%3d%%%s' \
    "${DIM}" \
    "${RESET}${FG_GREEN}${BOLD}" \
    "$(printf '%*s' "$filled" '' | tr ' ' '█')" \
    "${RESET}${DIM}" \
    "$(printf '%*s' "$empty"  '' | tr ' ' '░')" \
    "${RESET}${DIM}" "${RESET}" \
    "${FG_GREEN}${BOLD}" "$pct" "${RESET}"
}

_upgrade_draw_log() {
  local line="$1"
  local maxlen=$(( TERM_COLS - 4 ))
  (( maxlen < 10 )) && maxlen=10
  if (( ${#line} > maxlen )); then line="${line:0:$(( maxlen - 1 ))}…"; fi
  tput cup "$_upgrade_ROW_LOG" 0
  tput el 2>/dev/null || printf '\033[2K'
  printf '  %s%s%s' "${DIM}" "$line" "${RESET}"
}

_upgrade_draw_count() {
  local done_n="$1" total_n="$2"
  tput cup "$_upgrade_ROW_COUNT" 0
  tput el 2>/dev/null || printf '\033[2K'
  printf '  %s%d / %d%s  %s' \
    "${FG_CYAN}${BOLD}" "$done_n" "$total_n" "${RESET}" \
    "$(msg upgrade_count_label)"
}

_upgrade_draw_frame() {
  local title_key="$1"   # upgrade_title ou dryrun_title
  _check_resize
  tput clear 2>/dev/null || clear
  tput civis 2>/dev/null || true

  tput cup "$_upgrade_ROW_TITLE" 0
  printf '  %s%s%s  %s·%s  %s' \
    "${FG_BLUE}${BOLD}" "$(msg app_name)" "${RESET}" \
    "${DIM}" "${RESET}" \
    "${DIM}$(msg $title_key)${RESET}"

  _upgrade_draw_step "$_upgrade_ROW_STEP1" 0 "$(msg upgrade_step1)"
  _upgrade_draw_step "$_upgrade_ROW_STEP2" 0 "$(msg upgrade_step2)"
  _upgrade_draw_step "$_upgrade_ROW_STEP3" 0 "$(msg upgrade_step3)"
  _upgrade_draw_bar 0

  tput cup "$_upgrade_ROW_STATUS" 0
  _statusbar "$(msg upgrade_running)"
}

# Lance apt-get en arrière-plan, anime la progression en parsant sa sortie.
# $1 = mode : "real" ou "dry"
# $2..N = paquets
_upgrade_run_apt() {
  local mode="$1"; shift
  local -a pkgs=("$@")
  local total_pkgs=${#pkgs[@]}

  local tmpdir; tmpdir=$(mktemp -d)
  local pipe_out="${tmpdir}/apt.out"
  local lastlog_file="${tmpdir}/lastlog"
  local done_file="${tmpdir}/done_count"
  local apt_exit_file="${tmpdir}/apt_exit"
  echo 0 > "$done_file"
  mkfifo "$pipe_out"

  # Lancer apt-get
  if [[ "$mode" == "dry" ]]; then
    run_cmd apt-get -o Dpkg::Progress-Fancy=0 \
      install --only-upgrade --dry-run -y "${pkgs[@]}" \
      > "$pipe_out" 2>&1 &
  else
    run_cmd apt-get -o Dpkg::Progress-Fancy=0 \
      install --only-upgrade -y "${pkgs[@]}" \
      > "$pipe_out" 2>&1 &
  fi
  local apt_pid=$!

  # Lecteur du pipe : parse la sortie apt et met à jour les compteurs
  (
    local done_count=0
    while IFS= read -r aptline; do
      printf '%s\n' "$aptline" > "$lastlog_file"
      # Détecter les lignes de progression dpkg :
      # "Unpacking foo …", "Setting up foo …", "Get:N foo …"
      if [[ "$aptline" =~ ^(Unpacking|Setting\ up|Get:|Preparing\ to\ unpack) ]]; then
        (( done_count++ )) || true
        echo "$done_count" > "$done_file"
      fi
    done < "$pipe_out"
    wait "$apt_pid" 2>/dev/null || true
    echo $? > "$apt_exit_file"
  ) &
  local reader_pid=$!

  # Animation : spinner + barre + log défilant
  local fi=0
  local frames=('◉' '◎' '◉' '◌')
  # Estimation : chaque paquet génère ~3 lignes (Get + Unpacking + Setting up)
  local estimated=$(( total_pkgs * 3 ))
  (( estimated < 1 )) && estimated=1

  while kill -0 "$apt_pid" 2>/dev/null; do
    local done_n=0
    [[ -f "$done_file" ]] && done_n=$(cat "$done_file" 2>/dev/null || echo 0)

    local pct=$(( done_n * 95 / estimated ))
    (( pct > 95 )) && pct=95

    # Log défilant
    if [[ -f "$lastlog_file" ]]; then
      local lastline
      lastline=$(cat "$lastlog_file" 2>/dev/null || true)
      [[ -n "$lastline" ]] && _upgrade_draw_log "$lastline"
    fi

    # Spinner sur étape 2
    tput cup "$_upgrade_ROW_STEP2" 0
    tput el 2>/dev/null || printf '\033[2K'
    printf '  %s%s%s  %s' \
      "${FG_CYAN}${BOLD}" "${frames[$fi]}" "${RESET}" "$(msg upgrade_step2)"

    _upgrade_draw_bar "$pct"
    _upgrade_draw_count "$done_n" "$total_pkgs"

    fi=$(( (fi + 1) % 4 ))
    sleep 0.12
  done

  wait "$reader_pid" 2>/dev/null || true

  # Lire le code de sortie
  local apt_exit=0
  [[ -f "$apt_exit_file" ]] && apt_exit=$(cat "$apt_exit_file" 2>/dev/null || echo 1)

  # Vider log défilant
  tput cup "$_upgrade_ROW_LOG" 0
  tput el 2>/dev/null || printf '\033[2K'

  rm -rf "$tmpdir"
  return "$apt_exit"
}

do_select_and_upgrade() {
  with_errexit_disabled do_select_and_upgrade_impl
}

do_select_and_upgrade_impl() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; return
  fi

  # Sélection des paquets (avant sudo — pas besoin de privilèges pour lire)
  if ! get_user_selection "$(msg upgradable_title)" UPGRADABLE UPGRADABLE_TYPES; then
    return
  fi
  if (( ${#SELECTED_IDX[@]} == 0 )); then
    echo "  $(msg no_selected)"; pause; return
  fi

  # Construire la liste des paquets sélectionnés
  local -a pkgs=()
  local -a sel_cur=() sel_new=()
  for idx in "${SELECTED_IDX[@]}"; do
    pkgs+=("${UPGRADABLE[$idx]}")
    sel_cur+=("${UPGRADABLE_VERSIONS_CUR[$idx]:-?}")
    sel_new+=("${UPGRADABLE_VERSIONS_NEW[$idx]:-?}")
  done

  # ── Écran de confirmation ─────────────────────────────────────────────
  _check_resize
  tput clear 2>/dev/null || clear
  _header
  echo "  ${BOLD}$(msg will_update):${RESET}"
  echo ""
  for (( i=0; i<${#pkgs[@]}; i++ )); do
    local sec_badge=""
    local pkg_type="${UPGRADABLE_TYPES[${SELECTED_IDX[$i]}]:-normal}"
    [[ "$pkg_type" == "security" ]] && sec_badge="  ${FG_RED}${BOLD}[sec]${RESET}"
    printf '  %s·%s  %-32s %s%s%s → %s%s%s%s\n' \
      "${FG_GREEN}${BOLD}" "${RESET}" \
      "${pkgs[$i]}" \
      "${DIM}" "${sel_cur[$i]}" "${RESET}" \
      "${FG_GREEN}${BOLD}" "${sel_new[$i]}" "${RESET}" \
      "$sec_badge"
  done
  echo ""
  show_size_info "${pkgs[@]}"
  echo ""

  if [[ "$DRY_RUN_ONLY" -eq 1 ]]; then
    echo "  ${FG_YELLOW}$(msg dryrun_disabled)${RESET}"
    pause; return
  fi

  # Confirmation avec timeout
  if ! confirm_timeout "  $(msg proceed_prompt)" 30; then
    echo "  $(msg canceled)"; pause; return
  fi

  # ── Sudo juste avant l'opération apt ────────────────────────────────
  # On invalide le cache pour forcer une saisie fraîche — l'utilisateur
  # doit confirmer explicitement qu'il autorise l'écriture sur le système.
  sudo -k
  if ! ensure_sudo; then pause; return; fi

  # ── Écran d'upgrade animé ────────────────────────────────────────────
  _upgrade_draw_frame "upgrade_title"
  _upgrade_draw_step "$_upgrade_ROW_STEP1" 2 "$(msg upgrade_step1)"
  _upgrade_draw_step "$_upgrade_ROW_STEP2" 1 "$(msg upgrade_step2)"
  _upgrade_draw_bar 0

  if ! _upgrade_run_apt "real" "${pkgs[@]}"; then
    _upgrade_draw_step "$_upgrade_ROW_STEP2" 3 "$(msg upgrade_step2)"
    _upgrade_draw_bar 0
    tput cup $(( _upgrade_ROW_STATUS + 2 )) 0
    echo ""
    echo "  ${FG_RED}$(msg update_failed)${RESET}"
    log ERROR "Échec mise à jour : ${pkgs[*]}"
    tput cnorm 2>/dev/null || true
    pause; return
  fi

  _upgrade_draw_step "$_upgrade_ROW_STEP2" 2 "$(msg upgrade_step2)"
  _upgrade_draw_step "$_upgrade_ROW_STEP3" 1 "$(msg upgrade_step3)"
  _upgrade_draw_bar 98

  # Étape 3 : nettoyage de la liste locale
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

  _upgrade_draw_step "$_upgrade_ROW_STEP3" 2 "$(msg upgrade_step3)"
  _upgrade_draw_bar 100
  _upgrade_draw_count "${#pkgs[@]}" "${#pkgs[@]}"

  tput cup $(( _upgrade_ROW_BAR + 2 )) 0
  printf '  %s✓ %s%s\n' "${FG_GREEN}${BOLD}" "$(msg upgrade_ok)" "${RESET}"

  tput cup "$_upgrade_ROW_STATUS" 0
  _statusbar "$(msg refresh_done_hint)"

  log INFO "Paquets mis à jour : ${pkgs[*]}"
  tput cnorm 2>/dev/null || true
  pause
}

# ─────────────────────────────────────────────
#  DRY-RUN — UI ANIMÉE
# ─────────────────────────────────────────────
do_dry_run() {
  with_errexit_disabled do_dry_run_impl
}

do_dry_run_impl() {
  if (( ${#UPGRADABLE[@]} == 0 )); then
    echo "  ${FG_YELLOW}$(msg no_list_loaded)${RESET}"; pause; return
  fi

  if ! get_user_selection "$(msg upgradable_title) (Dry-Run)" UPGRADABLE UPGRADABLE_TYPES; then
    return
  fi
  if (( ${#SELECTED_IDX[@]} == 0 )); then
    echo "  $(msg no_selected)"; pause; return
  fi

  local -a pkgs=()
  for idx in "${SELECTED_IDX[@]}"; do pkgs+=("${UPGRADABLE[$idx]}"); done

  # Sudo juste avant l'opération — même règle que pour le vrai upgrade
  sudo -k
  if ! ensure_sudo; then pause; return; fi

  _upgrade_draw_frame "dryrun_title"
  _upgrade_draw_step "$_upgrade_ROW_STEP1" 2 "$(msg upgrade_step1)"
  _upgrade_draw_step "$_upgrade_ROW_STEP2" 1 "$(msg upgrade_step2)"
  _upgrade_draw_bar 0

  if ! _upgrade_run_apt "dry" "${pkgs[@]}"; then
    _upgrade_draw_step "$_upgrade_ROW_STEP2" 3 "$(msg upgrade_step2)"
    _upgrade_draw_bar 0
    tput cup $(( _upgrade_ROW_STATUS + 2 )) 0
    echo ""
    echo "  ${FG_RED}$(msg dryrun_failed)${RESET}"
    log ERROR "Échec dry-run : ${pkgs[*]}"
    tput cnorm 2>/dev/null || true
    pause; return
  fi

  _upgrade_draw_step "$_upgrade_ROW_STEP2" 2 "$(msg upgrade_step2)"
  _upgrade_draw_step "$_upgrade_ROW_STEP3" 2 "$(msg upgrade_step3)"
  _upgrade_draw_bar 100
  _upgrade_draw_count "${#pkgs[@]}" "${#pkgs[@]}"

  tput cup $(( _upgrade_ROW_BAR + 2 )) 0
  printf '  %s✓ %s%s\n' "${FG_GREEN}${BOLD}" "$(msg dryrun_ok)" "${RESET}"

  tput cup "$_upgrade_ROW_STATUS" 0
  _statusbar "$(msg refresh_done_hint)"

  log INFO "Dry-run terminé : ${pkgs[*]}"
  tput cnorm 2>/dev/null || true
  pause
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
    # FIX: message passé par msg()
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
      l) do_show_logs ;;
      L) select_language ;;
      q) exit 0 ;;
    esac
  done
}

main_menu