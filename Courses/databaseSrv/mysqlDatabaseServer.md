## MYSQL Server - Server Hosting

Rendre la base de données MSQL dans un serveur sous Linux accessible à des clients.
Les clients et le serveur doivent être connectés au même réseau (De préference local)

## Vérifier du service actif

Vérifier d'abord le type de service actif dans votre machine: **mariadb** ou **mysql** 
- **mariadb:** `sudo systemctl status mariabd`
- Si le service est actif alors vous pouvez passer à la configuration:
  - Editer le fichier suivant: `/etc/my.cnf/d/server.cnf`
  - C'est le fichier de configuration pour les serveurs actifs
  - Ajouter ceci dans la section [mysqld] : `bind-address = 0.0.0.0`
- Redémarrer le service MariaDB: `sudo systemctl restart mariadb`

## Création d'un utilisateur distant pour la base de données

- Entrer dans mariabd: `sudo mariadb`
- Executez les commandes suivantes:
  - `~ CREATE USER 'username'@'%' IDENTIFIED BY 'password'`
  - `~ GRANT ALL PRIVILEGES ON Votre_bd.* TO 'username@'%'; FLUST PRIVILEGES;`
  - Cela permet de créer un utilisateur pour la connexion à distance vers le serveur.
  - Vérifier si l'utilisateur est ajouté: `SELECT Host, USER FROM mysql.user;`
  - Vous devez voir une ligne comme `% | username`
  - Et enfin, sortez de là: `EXIT;`

## Ouvrir le port pour la connexion distant

- Veuillez vérifier votre port mysql, ici on utilisera le port par défaut `3306`
- Via **UFW**:
  - `sudo ufw allow 3306/tcp` (Changer 3306 par votre port actuel)
  - `sudo ufw enable`
- Ou via **firewalld**:
  - `sudo firewalld-cmd --permanent --add-port=3306/tcp`
  - `sudo firewall-cm --reload`

## Tester la connexion

- Lancer dans le client: `mysql -h 127.0.0.1 -u username -p`
- Veuillez changer l'adresse IP indiquée par l'adresse IP du serveur.
