# Intérpeteur de commande ou SHELL sur les distributions Linux

- Configuration et changement de votre shell par défaut pour les distributions basés sous Linux
- Un shell est un **interpréteur de commandes** qui sert d'interface textuelle entre l'utilisateur et le noyau du système d'exploitation.

## Installation  

- Vérifier si le shell que vous souhaitez installer est disponible et fonctionnel pour votre distribution
- Installer votre shell via le terminal ou un gestionnaire d'application (En fonction de votre Distro) 

## Changer le shell par défaut

- Trouver son dossier bin source (Géneralement situé dans **/usr/share/votre_shell**)
- pwd (Pour voir le chemin absolu)
- Copiez le chemin absolu indiqué par la commande précedent
- Voir dans `../etc/shells` (`cat /etc/shells`)
- **Remarque:** Le fichier /etc/shells sur un système Linux est un fichier texte simple qui contient une liste des chemins absolus des shells de connexion valides sur le système.
- Si le chemin de votre shell est absent, ajoutez le dans le fichier shells: `sudo nano shells`
- Ensuite executer: `chsh -s /path/to/bin/terminal username`
  - **chsh:** abréviation de *change shell*, cette commande permet à l'utilisateur de modifier leur shell de connexion (default)
  - **-s:** spécifie le chemin absolu vers le nouveau shell
  - **username:** l'utilisateur auquel le changement de shell est valide

## NB

- Voici un terminal que je recommande beaucoup pour son interface et sa maniabilité: Warp 
- Site officiel du Warp: [Warp Terminal](https://www.warp.dev)
- Vouz pouvez télecharger le fichier d'installation en fonction de votre OS
- Il intègre une IA qui sert d'office de rechercher pour les services du OS

