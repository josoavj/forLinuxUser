# **** Git Branch ****

- Utilisation et Manipulation de branche Git

## Création

- Création (Simple) d'une branche: `git branch nom_branche`
  - Cette commande crée un pointeur vers le commit actuel, sans changer de branche

- Création d'une nouvelle branche et basculement automatique vers celle-ci: `git checkout -b nom_branche`
  - C'est un raccourci pour `git branch nom_branche` suivi de `git checkout nom_branche`

## Suppression

- Suppression d'une branche spécifique:
  - Seulemment si elle a été fusionnée avec la branche actuelle: `git branch -d nom_branche`
  - Suppression même si elle n'a pas été fusionnée: `git branch -D nom_branche`

## Basculement entre les branches

- Basculement entre les branches: `git checkout nom_branche`
  - Basculement vers main: `git checkout main`

## Fusion de branche

- Merge ou fusion: `git merge nom_branche`

## Visualisation de tous les branches

- Liste toutes le branches locales, la branche actuelle est marquée d'un astérisque(*): `git branch`
- Liste toutes les branches locales et distantes: `git branch -a`
- Affiche un graphique de l'historique des commits avec les branches et les tags: `git log --graph --oneline --decorate --all`

## Pour les branches distantes

- Pousse la branche locale vers le dépôt distant (origin): `git push origin nom_branche`
- Récupère les changements de la branche distante et les fusionne dans la branche locale: `git pulll origin nom_branche`
- Configurer une branche locale pour suivre une branche distante: `git branch --set-upstream-to=origin/nom_branche nom_branche`
