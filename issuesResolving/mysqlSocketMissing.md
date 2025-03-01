### Si une erreur indique que vous ne pouvez pas toucher ni faire des actions sur le fichier mysqld.sock
### Sur Linux uniquement

- Vérifier si mariadb est lancée: `sudo systemctl status mariadb` 
- Cela devrait afficher active et aussi running
- Vérifier si le fichier est présent dans le répertoire indiqué: `ls /run/mysqld/mysqld.sock`
- Si le fichier est absent, créer le: `sudo touch /run/mysqld/mysqld.sock`
- Ensuite changer les permissions comme pour l'utilisateur mysql et le groupe mysql: `sudo chown mysql:mysql /run/mysqld/mysqld.sock`
- Et ensuite, redémarrer le service mariadb: `sudo systemctl restart mariadb`
