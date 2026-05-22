# apt-updater

> **v3.5** — Gestionnaire de mises à jour apt interactif avec interface animée / Interactive apt upgrade manager with animated UI

Un outil en ligne de commande pour mettre à jour précisément les paquets apt upgradables, avec une interface structurée, des animations en temps réel et une gestion complète depuis le terminal.

An interactive CLI to selectively upgrade apt packages, with a structured real-time animated interface and full terminal management.

---

## Utilisation / Usage

```bash
chmod +x apt-updater.sh
./apt-updater.sh [options]
```

| Option | Description |
|---|---|
| `--no-color` | Désactive les couleurs ANSI / Disable ANSI colors |
| `--dry-run-only` | Désactive l'upgrade réel, simulation uniquement / Disable real upgrades, simulation only |
| `--lang=en\|fr` | Force la langue (défaut : auto-détection via `$LANG`) / Force language (default: auto-detect) |
| `-h`, `--help` | Affiche l'aide / Show help |

---

## Menu principal / Main menu

| Touche | Action |
|---|---|
| `r` | Refresh — synchronise les sources apt et recharge la liste |
| `v` | Voir la liste des paquets upgradables |
| `u` | Sélectionner et mettre à jour |
| `d` | Dry-run — simulation sans écriture |
| `h` | Gestionnaire de holds (figer / libérer des paquets) |
| `l` | Historique des logs |
| `L` | Changer la langue (EN / FR) |
| `q` | Quitter |

---

## Fonctionnement / How it works

### Refresh

Lance `apt-get update` en arrière-plan via un pipe nommé (`mkfifo`). La sortie n'est jamais affichée brute : chaque ligne `Get:`, `Hit:`, `Ign:` est parsée en temps réel pour alimenter une barre de progression `█░` et une zone de log défilant. L'écran est structuré en trois étapes animées :

1. **Synchronisation des sources apt** — `apt-get update` avec spinner et barre live
2. **Lecture de la liste upgradable** — `apt list --upgradable` parsé de façon robuste
3. **Résumé** — nombre de paquets trouvés, dont le nombre de mises à jour de sécurité

Runs `apt-get update` in the background via a named pipe. Output is never shown raw: each `Get:`, `Hit:`, `Ign:` line is parsed in real time to drive a `█░` progress bar and a scrolling log line. Three animated steps are displayed.

### Sélection

La saisie accepte des indices individuels, des plages et des combinaisons : `1 3 5-9`. Les doublons sont automatiquement dédupliqués. Les paquets de sécurité sont marqués `[sec]` en rouge dans la liste et dans l'écran de confirmation.

Input accepts individual indices, ranges, and combinations: `1 3 5-9`. Duplicates are automatically deduplicated. Security packages are flagged `[sec]` in red.

### Upgrade / Dry-run

Après confirmation (prompt avec timeout de 30 s), `sudo` est invalidé puis re-demandé immédiatement avant l'opération apt — l'autorisation est toujours fraîche au moment de l'écriture sur le système. L'upgrade tourne lui aussi en arrière-plan avec la même UI animée : barre verte, compteur d'opérations `N / total`, log défilant. En cas d'échec, l'étape concernée passe en rouge `✗` avec un message explicite.

After confirmation (30 s timeout), `sudo` is explicitly invalidated then re-prompted immediately before the apt operation — authorization is always fresh at write time. The upgrade also runs in the background with the same animated UI. On failure, the relevant step turns red `✗` with an explicit message.

### Hold manager

Permet de figer (`apt-mark hold`) ou libérer (`apt-mark unhold`) des paquets via la même interface de sélection par indices. Affiche la liste des paquets actuellement figés.

Lets you hold or unhold packages via the same index-selection interface.

---

## Logs

Toutes les opérations sont enregistrées dans `~/.cache/apt-updater/history.log` avec horodatage et niveau (`INFO` / `ERROR`). Les 20 dernières entrées sont consultables depuis le menu (`l`).

All operations are logged to `~/.cache/apt-updater/history.log` with timestamp and level. The last 20 entries are viewable from the menu.

---

## Dépendances / Dependencies

Bash ≥ 4.3 · `apt` · `sudo` · `tput` · `mkfifo` · `sed` · `tail`

Toutes présentes par défaut sur Debian/Ubuntu. / All present by default on Debian/Ubuntu.

---

## Notes

- Aucun fichier de configuration externe — tout est dans le script. / No external config file — everything is embedded in the script.
- `sudo` est utilisé automatiquement si vous n'êtes pas root, et re-demandé avant chaque opération apt. / `sudo` is used automatically if not root, and re-prompted before every apt operation.
- Le terminal est redimensionnable en cours d'utilisation (gestion `SIGWINCH` non-bloquante). / Terminal can be resized at any time (non-blocking `SIGWINCH` handling).
- Compatible `--no-color` pour les environnements sans support ANSI (logs, CI). / `--no-color` compatible for ANSI-less environments.