# Codes d'erreurs sous Linux

Sous Linux, les codes d'erreurs sont des nombres entiers qui signalent la raison pour laquelle une opération système ou une commande a échoué. 
Ils sont définis dans le fichier d'en-tête `/usr/include/errno.h` (ou un fichier similaire selon la distribution).
**NB:** La liste des codes suivants sont des codes d'erreurs fréquents
### Catégorie : Opérations sur les fichiers et répertoires

- **EPERM (1):** Opération non permise. L'utilisateur n'a pas les droits nécessaires pour effectuer l'opération sur le fichier ou le répertoire.
- **ENOENT (2):** Aucun fichier ou répertoire de ce type. Le fichier ou le répertoire spécifié dans le chemin n'existe pas.
- **EACCES (13):** Permission refusée. L'utilisateur n'a pas la permission d'accéder au fichier ou au répertoire (lecture, écriture, exécution).
- **ENOTDIR (20):** N'est pas un répertoire. Une composante du chemin spécifié qui aurait dû être un répertoire ne l'est pas.
- **EISDIR (21):** Est un répertoire. Une opération (comme l'écriture) a été tentée sur un répertoire.
- **ENOSPC (28):** Plus d'espace disponible sur le périphérique. Le disque dur ou la partition est plein.
- **EROFS (30):** Système de fichiers en lecture seule. Une tentative de modification a été faite sur un système de fichiers monté en lecture seule.
- **EEXIST (17):** Le fichier existe. Une tentative de création d'un fichier ou d'un répertoire qui existe déjà a été faite.
- **ENOTEMPTY (39):** Le répertoire n'est pas vide. Une tentative de suppression d'un répertoire non vide a été faite.

### Catégorie : Processus

- **ESRCH (3):** Aucun processus de ce type. Le processus spécifié par l'ID n'existe pas.
- **ECHILD (10):** Pas de processus fils. Une opération (comme wait()) a été tentée sur un processus fils inexistant.
- **EAGAIN (11) ou EWOULDBLOCK (11):** Ressource temporairement non disponible. L'opération ne peut pas être complétée immédiatement et devrait être retentée plus tard. Souvent rencontré avec les opérations d'E/S non bloquantes.
- **EINTR (4):** Appel système interrompu. Un signal a interrompu l'exécution d'un appel système.

### Catégorie : Mémoire

- **ENOMEM (12):** Pas assez de mémoire. Le système ne peut pas allouer la mémoire demandée.

### Catégorie : Périphériques et E/S

- **ENODEV (19):** Aucun périphérique de ce type. Le périphérique spécifié n'existe pas.
- **ENXIO (6):** Aucun périphérique ou adresse de ce type. L'adresse spécifiée pour un périphérique n'est pas valide.
- **EBADF (9):** Mauvais descripteur de fichier. Un descripteur de fichier invalide a été utilisé.
- **EIO (5):** Erreur d'entrée/sortie. Une erreur s'est produite lors de la lecture ou de l'écriture sur un périphérique.
- **ENOTTY (25):** Opération ioctl inappropriée pour le périphérique. L'opération ioctl tentée n'est pas supportée par le type de périphérique.
- **EPIPE (32):** Tube brisé. Une tentative d'écriture sur un tube (pipe) qui n'a pas de lecteur a été faite.

### Catégorie : Arguments et syntaxe

- **EINVAL (22):** Argument invalide. Un argument passé à un appel système ou à une commande n'est pas valide.
- **E2BIG (7):** Liste d'arguments trop longue. La liste des arguments passée à une commande est trop longue.
- **ENAMETOOLONG (36):** Nom de fichier trop long. La longueur du nom de fichier spécifié dépasse la limite autorisée.

### Catégorie : Réseau

- **ECONNREFUSED (111):** Connexion refusée. Le serveur cible a refusé la tentative de connexion.
- **ENETUNREACH (101):** Réseau inaccessible. Le réseau cible n'est pas accessible.
- **EADDRINUSE (98):** Adresse déjà utilisée. L'adresse réseau demandée est déjà utilisée.

#### Comment interpréter les codes d'erreurs :

- Dans les programmes C/C++ : Les appels système renvoient généralement -1 en cas d'erreur et la variable globale errno est définie avec le code d'erreur approprié. Vous pouvez utiliser des fonctions comme perror() ou strerror() pour obtenir une description textuelle de l'erreur.
- Dans les scripts shell : Les commandes renvoient un code de sortie (exit status). Un code de sortie de 0 indique généralement le succès, tandis qu'un code non nul indique une erreur. Bien qu'il n'y ait pas une correspondance directe et universelle entre les codes de sortie shell et les codes d'erreurs errno, certaines conventions existent. De plus, de nombreux programmes affichent des messages d'erreur textuels qui peuvent aider à identifier le problème.

#### Notice

Cette liste n'est pas exhaustive, mais elle couvre les codes d'erreurs les plus fréquemment rencontrés sous Linux. Pour une liste complète et spécifique à votre système, vous pouvez consulter le fichier /usr/include/errno.h.