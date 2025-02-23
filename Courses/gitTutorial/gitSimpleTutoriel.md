LEARN GIT: Bases et choses à savoir sur Git
-> Installation de Git sur Linux: apt install git (Pas valable pour tous)
Remarque: Git est préinstallé sur Garuda Linux.

>>> **** INIT ****
-> Utilisation de Git dans un dossier: Initialisation du versionning de git: git init

>>> **** GLOBAL CONFIG ****
- Une fois l'initialisation du versionning fait, on passe à la suite:
-> Git config: Executez la commande git help config pour définir la configuration. De base, on utilise deux choses: "user.email" et "user.name". Pour cela:
  -> git  config --global user.email "Your email" > Pour votre email
  -> git config --global user.name "Your_name" > Pour présenter votre nom.
  -> git config --global color.ui true/false > Pour définir la couleur dans votre outil de commange git.
> Pour vérifier la liste des configurations définis: git config list

-> Vérifier l'état de votre dossier/projet: git status
> Vous pouvez y voir les fichiers modifiés - changées - ajoutées

>>> **** ADD ****
-> Ajout de fichier:
  -> Pour ajouter tous les fichiers dans le dossier: git add . ou git add --all
  -> Pour ajouter tous les fichiers ayant un type d'extension spécifique:
     git add "*.nom_de_extension"
  -> Pour ajouter un fichier ou dossier spécifique: git add (votre_fichier/dossier)
- Avant d'ajouter des fichiers: vérifier avec git add

>>> **** COMMIT ****
-> Pour afficher le/les changement(s) effectué(s): executez git commit
-> Publication (commit) du changement: git commit -m "Information ou commentaire sur le changement à publier"
-> Pour publier directement les changements effectués dans un fichier sans passer à git add, éxecutez juste la commande: git commit -a -m "commentaire"

>>> **** IGNORE ****
-> Ignorer des fichiers: dans le fichier .gitignore
   -> Ajouter sur chaque ligne de ce fichier tous les fichiers ou dossiers à ignorer

>>> **** VERIFICATION - LOGS ****
-> Pour vérifier ou vois le nombre de commit effectué:
  -> git log > Afficher tous les commits effectués
  -> git log -n nombre_de_commit_afficher > Préciser le nombre de commit à afficher
  -> git log --oneline > Pour afficher en une seule ligne tous les informations nécessaires à chaque commit: l'ID et le commentaire.
  -> git log -p chemin_afficher: Pour afficher les changements apportés et publiés à propos d'un chemin de fichier > Afficher le chemin de changement.

-> Pour différencier ou comparer le changement effectué dans un fichier avant de le publier une nouvelle version: git diff

- Pour revenir et voir les anciens commits:
> Revenir simplement en arrière:
  -> git log --online pour voir l'ID des commits.
  -> git checkout (ID du commit): cela nous fera revenir en arrière (A l'etat du commit concerné). > Fonctionne juste au cas où vous voulez revenir en arrière, sans sauvegarder l'etat ouvert par la commande.


>>> **** CHECKOUT ****
> Revenir en arrière et utiliser l'etat du fichier avant ou juste supprimer/annuler le changement effectué:
  -> git checkout ID
  -> git checkout ID file_name > Au cas où vous voulez annuler les changements effectués sur un fichier spécifique.
  -> Ensuite, vous n'avez qu'à faire un commit à cet état là:
     git commit "Suppression/Commentaire"

> Au cas où vous voulez juste voir les états antérieurs du repertoire ou même du fichier:
  -> git checkout ID file_name/directory > Pour voir l'etat anterieur
  -> git checkout master file_name/directory > Pour revenir au dernier état final

>>> **** REVERT ****
> Revert: défaire un commit (n'importe quel commit)::
  -> git revert ID (Revenir en arrière sur le commit ayant cet ID)

>>> **** RESET ****
> Reset: modifie l'historique, supprime des choses:: à ne pas confondre avec git revert::
  -> git reset HEAD file_name (Supprimer un commit et tout ce qui est changé dedans/avec)
  -> On a la possibilité d'utiliser différent mode:
    -> git reset HEAD^^ (Reviens en arrière en fonction du nombre de chapeau, soit deuc fois ou trois fois en arrière)
    -> git reset --hard:: hard reset pour revenir au dernier commit


>>> **** GIT COMMIT **** 
> Type de commit pour git:
  - git commit -m "type: Commentaire"
  - Il existe 9 types de commit disponibles:
    -> build: changements qui affectent le système de build ou des dépendances externes
    -> ci: changements concernant les fichiers et scripts d’intégration ou de configuration
    -> feat: ajout d’une nouvelle fonctionnalité
    -> fix: correction d’un bug
    -> perf: amélioration des performances
    -> refactor: modification qui n’apporte ni nouvelle fonctionalité ni d’amélioration de performances
    -> style: changement qui n’apporte aucune alteration fonctionnelle ou sémantique
    -> docs: rédaction ou mise à jour de documentation
    -> test: ajout ou modification de tests
