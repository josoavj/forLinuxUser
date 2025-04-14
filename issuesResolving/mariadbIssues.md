# Problèmes rencontrés sous mariadb 
## Cible: Distribution Linux


### Problème d'accès à des dossier et problèmes de permissions

Au cas où vous rencontrez des problèmes d'accès aux dossiers suivants:
- `/var/lib/mysql`
- `/var/log/mysql`
- Vérifier vos journaux par la commande `sudo systemctl status mariadb`.
- Si le service ne se démarre pas et qu'il indique une code d'erreur 
- Le service de mariadb est éteinte car il ne peut ni écrire ni accéder à ces répertoires

