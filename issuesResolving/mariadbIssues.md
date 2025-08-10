# Problèmes courants sous MariaDB

### Cible : Distribution Linux

---

### ⚠️ Problème d’accès aux dossiers et permissions

Si vous rencontrez des difficultés pour accéder aux dossiers suivants :

* `/var/lib/mysql` (données des bases)
* `/var/log/mysql` (logs du serveur)

---

### Symptômes typiques

* MariaDB ne démarre pas.
* La commande suivante affiche un statut **inactive** ou **failed** :

```bash
sudo systemctl status mariadb
```

* Dans les logs, vous pouvez voir des erreurs liées à des permissions ou à l’impossibilité d’écrire/accéder à certains fichiers.

---

### Causes probables

* Permissions incorrectes sur les dossiers ou fichiers essentiels.
* Propriétaire et groupe incorrects (devraient être `mysql:mysql`).
* Le système empêche MariaDB d’accéder ou d’écrire dans ces répertoires (ex: SELinux, AppArmor, systèmes de fichiers montés en lecture seule).

---

### Étapes pour résoudre ce problème

1. **Vérifier les permissions et propriétaires**

```bash
sudo ls -ld /var/lib/mysql /var/log/mysql
```

* Le propriétaire et groupe doivent être `mysql:mysql`.
* Les permissions doivent permettre à MariaDB d’écrire et de lire.

2. **Réparer les permissions et le propriétaire**

```bash
sudo chown -R mysql:mysql /var/lib/mysql /var/log/mysql
sudo chmod -R 750 /var/lib/mysql /var/log/mysql
```

* `-R` agit récursivement sur tous les fichiers et sous-dossiers.

3. **Vérifier que MariaDB est bien arrêté avant ces modifications**

```bash
sudo systemctl stop mariadb
```

4. **Redémarrer MariaDB**

```bash
sudo systemctl start mariadb
```

5. **Vérifier le statut**

```bash
sudo systemctl status mariadb
```

---

### 🔍 En cas de persistance du problème

* Vérifiez les logs détaillés :

```bash
sudo journalctl -u mariadb
```

* Vérifiez si un système de sécurité (ex: SELinux, AppArmor) bloque l’accès aux dossiers :

  * Pour SELinux :

    ```bash
    sudo getenforce
    ```

    * Si `Enforcing`, temporairement désactivez pour tester :

    ```bash
    sudo setenforce 0
    ```
  * Pour AppArmor : consultez les profils et désactivez temporairement.

* Vérifiez que le système de fichiers n’est pas monté en lecture seule :

```bash
mount | grep -E '(/var/lib/mysql|/var/log/mysql)'
```

---

### 💡 Bonnes pratiques

* Toujours vérifier les permissions avant de modifier.
* Faire une sauvegarde des données importantes avant toute opération.
* Surveillez les logs en continu pendant le dépannage :

```bash
sudo tail -f /var/log/mysql/error.log
```

* Sur certains systèmes, les logs peuvent se trouver ailleurs, vérifiez la config MariaDB (`my.cnf`).

