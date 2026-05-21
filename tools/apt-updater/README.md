# apt-updater

Small interactive CLI to upgrade selected apt packages that are currently upgradable.

## Usage

```bash
./apt-updater.sh
```

## How it works

- Runs `apt-get update`.
- Lists packages from `apt list --upgradable`.
- Lets you select indices or ranges (e.g., `1 3 5-7`, `a` for all).
- Runs `apt-get install --only-upgrade` for the selected packages.

## Notes

- Uses `sudo` if you are not root.
- Dependencies required by selected packages are upgraded as needed by apt.

---

# apt-updater (FR)

Petit outil CLI interactif pour mettre a jour des paquets apt precis parmi ceux qui sont upgradables.

## Utilisation

```bash
./apt-updater.sh
```

## Comment ca marche

- Lance `apt-get update`.
- Liste les paquets via `apt list --upgradable`.
- Permet de selectionner des indices ou des plages (ex: `1 3 5-7`, `a` pour tout).
- Lance `apt-get install --only-upgrade` pour les paquets choisis.

## Notes

- Utilise `sudo` si vous n'etes pas root.
- Les dependances necessaires aux paquets choisis sont mises a jour par apt.
