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
