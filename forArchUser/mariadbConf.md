# Mariadb Server on Arch Based Distro

- Configuration de mariadb dans les distributions Linux basés sur Arch 
- **OS utilisé:** Garuda Linux (Kernel : Linux 6.13.5-zen1-1-zen)

## Installation de mariadb

- Vérifier si mariadb est présent sur votre système: `pacman -Qs mariadb`
- Si mariadb est installé, vous pouvez passer à l'étape suivante.
- Si elle n'est pas installée, exécuter la commande suivante: `sudo pacman -S mariadb`

## Configuration de mysql

- Vérifier si le fichier `mysqld.sock` existe dans: `/run/mysqld/`
- Si le dossier ou le fichier est présent, passer à l'étape suivante.
- Si le fichier et dossier sont absent:
  - Aller dans `/run`: `cd /run`
  - Créer le dossier mysqld: `sudo mkdir mysqld`
  - Créer le fichier `mysqld.sock`: sudo touch mysqld.sock
  - Ensuite, attribuez le dossier et son contenu à l'utilisateur mysql et au même groupe:
    - `sudo chown mysql:mysql /run/mysqld`

## Configuration de mariadb

- Activez le service mariadb: `sudo systemctl enable mariadb`
- Ensuite, initialiser la base de données mariabd: 
  - `sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql`
  - `--user=mysql`: Indique l'utilisateur sous lequel le serveur MariaDB s'exécutera.
  - `--basedir=/usr`: Indique le répertoire de base de l'installation de MariaDB.
  - `--datadir=/var/lib/mysql`: Indique le répertoire où les données de MariaDB seront stockées.
- Ensuite, démarrer le service mariadb: `sudo systemctl start mariadb`
- Vérifier si tout fonctionne sans encombre: `sudo systemctl status mariadb`

## Configuration de la sécurité de mariadb

- Exécutez la commande suivante et suivez bien les instructions recommandées:
  - `sudo mariadb-secure-installation`




