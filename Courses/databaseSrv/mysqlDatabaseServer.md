## MYSQL Server - Server Hosting

Rendre la base de données MySQL dans un serveur sous Linux accessible à des clients.
Les clients et le serveur doivent être connectés au même réseau (de préférence en local)

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
  - `~ GRANT ALL PRIVILEGES ON Votre_bd.* TO 'username'@'%'; FLUSH PRIVILEGES;`
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
  - `sudo firewall-cmd --reload`
## Tester la connexion

- Lancer dans le client: `mysql -h 127.0.0.1 -u username -p`
- Veuillez changer l'adresse IP indiquée par l'adresse IP du serveur.

## Utilisation dans votre projet

- Vous pouvez lier votre base de données partagée avec vos projets, l'initiation de la connexion mentionnera l'adresse IP de l'hote au lieu de localhost.
- Exemple:
  ```
       host= "192.168.1.10",                            # Adresse IP du serveur 
       port= 3306,                                      # Port pour la connexion, 3306 est le port par défaut
       user= "Votre nom d'utilisateur",                 
       password= "Mot de passe",
       db= "Votre base de données",
       autocommit=True
  ```
- **NB:** Il est recommandé de ne pas stocker les informations sensibles dans votre code source.
- Voici un exemple concret avec **Python**:
  ```
  # Utilisation de aiomysql et asyncio
    host = input("Hôte de la base de données (par défaut : localhost) : ")
    if not host:
        host = "localhost"

    port_str = input("Port de la base de données (par défaut : 3306) : ")
    if port_str:
        try:
            port = int(port_str)
        except ValueError:
            print("Port invalide. Utilisation du port par défaut 3306.")
            port = 3306
    else:
        port = 3306

    user = input("Nom d'utilisateur : ")
    password = input("Mot de passe : ")
    database = input("Nom de la base de données : ")

    try:
        # Créer le pool de connexions
        pool = await aiomysql.create_pool(
            host=host,
            port=port,
            user=user,
            password=password,
            db=database,
            autocommit=True
        )

    finally:
        if pool:
            pool.close()
            await pool.wait_closed()
  ```
