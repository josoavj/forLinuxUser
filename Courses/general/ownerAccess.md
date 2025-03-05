# Accès utilisateur sur les distro Linux

Gestion des droits d'accès pour les utilisateurs dans une distribution Linux
 
## 1. Gestion des droits d'accès aux fichiers et répertoires (chmod)

- La commande **chmod (change mode)** est essentielle pour contrôler les permissions de lecture, d'écriture et d'exécution.
  - Syntaxe : `chmod [options] permissions fichier`
- Les permissions peuvent être spécifiées en mode octal (comme dans l'exemple) ou symbolique (par exemple, chmod u+x monfichier pour ajouter l'exécution au propriétaire).

## 2. Gestion des propriétaires et des groupes (chown, chgrp)

- **chown (change owner)** permet de modifier le propriétaire et le groupe d'un fichier ou répertoire.
  - Syntaxe : `chown utilisateur:groupe fichier`

- **chgrp (change group)** modifie uniquement le groupe.
 - Syntaxe : `chgrp groupe fichier`

## 3. Gestion des utilisateurs et des groupes (adduser, usermod, addgroup, gpasswd)

- **adduser** et **addgroup** permettent de créer de nouveaux utilisateurs et groupes.

- **usermod** modifie les propriétés d'un utilisateur existant.

- **gpasswd** permet de gérer les membres d'un groupe.

## 4. Contrôle d'accès basé sur les listes de contrôle d'accès (ACLs)

- Les ACLs offrent un contrôle plus fin des permissions que les permissions de base.
- Les commandes setfacl et getfacl sont utilisées pour gérer les ACLs.

## 5. sudo et les privilèges root

- **sudo** permet d'exécuter des commandes avec les privilèges root.
- Le fichier /etc/sudoers contrôle quels utilisateurs peuvent utiliser sudo et quelles commandes ils peuvent exécuter.
