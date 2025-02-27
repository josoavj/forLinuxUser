# Commandes utiles pour Garuda Linux (Arch Based)

- Garuda utilise Pacman 

## Mise à jour et installation de paquet

- Mettre à jour garuda: `sudo pacman -Su`
- Installer un paquet/programme: `sudo pacman -S nom_paquet`

## Copie de fichiers 

- Copier un fichier simplement: `cp file_name /repertoire_destination`
- Copier un répertoire: `cp -r /repertoire_destinaire /repertoire_cible`
  - **-r** signifie qu'on copier récursivement tous les fichiers dans le répértoire vers l'autre
- Autre manière, on ouvre le répertoire de destination directement dans terminal: `cp -r /repertoire_destinaire ./`

## Déplacement de fichiers

- Déplacer un fichier: `mv file_name /repertoire_destination`
- Déplacer un répertoire: mv -r /repertoire_destinaire /repertoire_cible
  - **-r** reste est la même que la copie. Seul cp change en mv


## Suppression d'application

- Suppression d'une application/programme: `sudo pacman -Rns nom_du_programme`
  - **-R :** Supprime le package spécifié.
  - **-n :** Supprime également les packages qui ne sont plus requis.
  - **-s :** Supprime également les dépendances du package.

- Nettoyage des dépendances inutilisées (orphelins): `sudo pacman -Qdtq | sudo pacman -Rns -`
  - **-Qdtq :** Liste les packages orphelins (ceux qui ne sont plus requis comme dépendances).
  - **| :** Passe la liste des packages orphelins à la commande suivante.
  - **sudo pacman -Rns - :** Supprime les packages orphelins.

## Caches

- Suppression des anciens packages dans le cache: `sudo pacman -Sc`
- Suppression des anciens versions dans le package actuels: `sudo paccache -r`
- Suppression des caches de tous les applications: `sudo paccache -rk0`
- Suppressions des anciens caches ou inutilisées: `sudo paccache -ruk0`