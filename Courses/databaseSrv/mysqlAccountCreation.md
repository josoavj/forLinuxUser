## Pour la création d'un compte mysql

- Connecter à mysql via root: `sudo mysql -u root -p`
- Ensuite vérifier la liste des utilisateurs: `SELECT User, Host FROM mysql.user;`
- Si le compte n'existe pas, créer un: `CREATE USER 'username'@'localhost' IDENTIFIED BY 'votre_mot_de_passe';`
- Ensuite attribuer les permission pour le compte: `GRANT ALL PRIVILEGES ON nom_de_la_base.* TO 'username'@'localhost';` 
                                                   `FLUSH PRIVILEGES;`

- Au cas où vous voulez lui donner la permission pour toutes les bases de données: 
  - `GRANT ALL PRIVILEGES ON *.* TO 'username'@'localhost';
    FLUSH PRIVILEGES;`
- Ensuite vérifier si les permissions ont été accordées: `SHOW GRANTS FOR 'username'@'localhost';`
- Déconnecter vous de votre instance actuelle et reconnecter avec le compte créé: `mysql -u username -p`
- Si la connexion se fait sans encombre alors votre compte est présent.
- Mais vous pouvez aussis initier une connexion via **TCP/IP** via: `mysql -u username -p -h 127.0.0.1`


