# Archives dans Linux

- Les archives les plus fréquentes sous linux portent l'extension . tar (format UNIX), ou . zip

## Utilisation de tar 

- **tar:** Tape Archive
- **Fonctionnalités:**
  - Archiver des fichiers/dossiers 
  - Extraction d'archive
  - Gérer des achives
  - Compression et décompression

- **Syntaxe:** `tar [options] [commande] file/folder`
- Créer une archive: `tar -cvf archive_name.tar my_folder/`
- Extraire une archive: `tar -xvf nom_archive.tar`
- Afficher le contenu d'une archive: `tar -tvf nom_archive.tar`
- Extraction dans un dossier spécifique: `tar -x [options] -C <dossier_cible> archive.tar`
  - **-C** indique le dossier cible où extraire les fichiers
- Exemple d'utilisation: `tar -xzf nom_archive.tar`

### Options pour tar

- **Options courantes:**
  - **c :** Création d'une archive
  - **v :** Affichage des informations pendant l'opération
  - **f :** Spécification du nom du fichier archive
  - **x :** Extraction d'une archive
  - **t :** Affichage du contenu d'une archive
  - **z :** Compression avec gzip (nécessite gzip installé)
  - **j :** Compression avec bzip2 (nécessite bzip2 installé)


## Utilisation de unzip

- **Fonctionnalités:** 
  - Décompression d'archive zip
  - Gestion des archives zip

- **Syntaxe:** `unzip [options] nom_archive.zip` {Options: Définissent les paramètres de décompression}
- Décompression dans une archive spécifique: `unzip archive.zip destination/`
- Affichage du contenu d'une archive: `unzip -l archive.zip`
- Extraction d'un fichier spécifique dans une archive: `unzip -p archive.zip fichier/à/extraire`

### Options pour unzip

- Options courantes:
  - **l :** Affiche le contenu d'une archive
  - **p :** Extrait un fichier spécifique vers la sortie standard
  - **n :** Ne crée pas de répertoire lors de l'extraction
  - **o :** Conserve les permissions et les horodatages des fichiers originaux
  - **q :** Fonctionnement silencieux 
