---
title: "Mysql Socket Missing"
section: "troubleshooting"
category: "troubleshooting"
distro: null
usage: "troubleshooting"
---

# Comprendre et résoudre les erreurs liées au fichier Unix Socket `mysqld.sock` sous Linux

---

## Qu’est-ce que le fichier `mysqld.sock` ?

Le fichier `mysqld.sock` est un **socket Unix**, un fichier spécial utilisé pour la communication locale entre le client MySQL/MariaDB et le serveur.
Contrairement à une connexion réseau classique (TCP/IP), ce socket permet une communication **rapide et sécurisée** entre les processus sur la même machine.

---

## Pourquoi une erreur peut survenir ?

* **Le fichier socket n’existe pas** ou a été supprimé (ex: après un redémarrage ou crash du serveur).
* **Permissions incorrectes** empêchant l’utilisateur ou le groupe MariaDB d’accéder au fichier socket.
* **Chemin de socket mal configuré** dans la configuration MariaDB ou dans le client.

---

## Étapes détaillées pour résoudre l’erreur

---

### 1️⃣ Vérifier que le service MariaDB est lancé

```bash
sudo systemctl status mariadb
```

* Le service doit être **`active (running)`**.
* Sinon, démarrez-le :

```bash
sudo systemctl start mariadb
```

* Le serveur MySQL/MariaDB crée généralement le socket à son démarrage.

---

### 2️⃣ Vérifier la présence du socket

```bash
ls -l /run/mysqld/mysqld.sock
```

* Le fichier doit exister et être un **socket** (type `s` dans la colonne des permissions).
* Exemple de sortie attendue :

```
srwxrwxrwx 1 mysql mysql 0 août 10 20:00 /run/mysqld/mysqld.sock
```

* Si absent, créez le fichier (étape suivante).

---

### 3️⃣ (Re)Créer le fichier socket (si nécessaire)

```bash
sudo touch /run/mysqld/mysqld.sock
```

* Cette commande crée un fichier vide, mais **le socket sera normalement recréé automatiquement** au lancement du serveur MariaDB.
* **Important :** ce fichier est un placeholder ; le serveur doit être en mesure de le remplacer par un socket réel.

---

### 4️⃣ Vérifier ou créer le dossier `/run/mysqld`

```bash
sudo mkdir -p /run/mysqld
sudo chown mysql:mysql /run/mysqld
```

* Le dossier doit appartenir à l’utilisateur `mysql` et au groupe `mysql`.
* Sinon, MariaDB ne pourra pas créer le socket dans ce répertoire.

---

### 5️⃣ Corriger les permissions du socket

```bash
sudo chown mysql:mysql /run/mysqld/mysqld.sock
sudo chmod 770 /run/mysqld/mysqld.sock
```

* Cela permet à l’utilisateur et groupe `mysql` d’accéder au socket.
* Les autres utilisateurs n’ont pas besoin d’y accéder pour des raisons de sécurité.

---

### 6️⃣ Redémarrer MariaDB pour appliquer les changements

```bash
sudo systemctl restart mariadb
```

* Le service va recréer le socket avec les bonnes permissions.

---

### 7️⃣ Vérifier que tout est en ordre

* Vérifiez le statut :

```bash
sudo systemctl status mariadb
```

* Vérifiez le socket et ses permissions :

```bash
ls -l /run/mysqld/mysqld.sock
```

* Vérifiez les logs en cas de problème :

```bash
sudo journalctl -u mariadb
```

---

## 💡 Informations complémentaires

* Le chemin du socket est défini dans la config MariaDB (exemple `/etc/mysql/my.cnf`, `/etc/mysql/mariadb.conf.d/`), sous la section `[mysqld]` et `[client]` :

```ini
[mysqld]
socket=/run/mysqld/mysqld.sock

[client]
socket=/run/mysqld/mysqld.sock
```

* Assurez-vous que le client utilise le même chemin que le serveur, sinon la connexion échouera.

---

## Résumé en schéma simple

| Problème possible           | Solution rapide                                   |
| --------------------------- | ------------------------------------------------- |
| Socket absent               | Créer le dossier et redémarrer MariaDB            |
| Permissions incorrectes     | Changer propriétaire et permissions du socket     |
| MariaDB non lancé           | Démarrer le service MariaDB                       |
| Chemin socket mal configuré | Vérifier et synchroniser le chemin dans la config |

