# INXI

- **inxi** est un puissant outil en ligne de commande utilisé sous Linux pour afficher des informations détaillées sur le matériel et le logiciel de votre système. 
-  Il est très utile pour le dépannage, le partage d'informations sur votre système sur des forums de support et la vérification des spécifications de votre machine.

## Utilisation génerale de inxi

- Installer inxi 
- Dans terminal, executez la commande: `inxi`

## Fonctionnalités

- Info sur la machine et la carte mère: `inxi -M`
- Info sur les numéros de séries de la machine et CM: `sudo inxi -M`
- Info sur le processeur: `inxi -C`
- Info sur la mémoire RAM: `inxi -m`
- Info sur le swap: `inxi -j`
- Info sur les périphériques USB: `inxi -J`
- Info stockage: `inxi -D`
- Info sur le volume logique (LVM): `sudo inxi -L`
- Info sur les partitions: `inxi -P`
- Info sur la batterie: `inxi -B`
- Info audio: `inxi -A`
- Info graphique: `inxi -G`
- Configuration réseau: `inxi -i`
- Info bluetoth: `inxi --bluetooth`
- Top 5 des processus le plus gourmand: `inxi -t`
- Info sur le système: `inxi -S`
- Info sur les dépôts actifs: `inxi -r`
- Info temp: `inxi --sensors`
- Info sur plusieurs choses mais en résumé: `inxi -Fè



## Remarque

- Vous pouvez utiliser plusieurs options en parallèle
