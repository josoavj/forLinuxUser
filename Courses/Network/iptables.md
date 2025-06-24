iptables est un outil de ligne de commande puissant et polyvalent pour configurer le pare-feu netfilter dans le noyau Linux. Il permet de filtrer les paquets, de modifier leur en-tête et de les rediriger. C'est un composant essentiel pour la sécurité des systèmes Linux.

Ce document couvrira les bases d'iptables, sa syntaxe, ses concepts clés, des exemples pratiques et des considérations avancées.

-----

### **Table des Matières**

1.  **Introduction à iptables et Netfilter**
      * Qu'est-ce que Netfilter ?
      * Le rôle d'iptables
      * Philosophie de fonctionnement
2.  **Concepts Fondamentaux d'iptables**
      * **Tables:** `filter`, `nat`, `mangle`, `raw`, `security`
      * **Chaînes (Chains):**
          * Chaînes par défaut: `INPUT`, `OUTPUT`, `FORWARD`, `PREROUTING`, `POSTROUTING`
          * Chaînes personnalisées
      * **Cibles (Targets):**
          * Actions de base: `ACCEPT`, `DROP`, `REJECT`, `LOG`
          * Actions avancées: `SNAT`, `DNAT`, `MASQUERADE`, `REDIRECT`
          * Cibles pour les chaînes personnalisées: `RETURN`, `JUMP`
      * **Critères de correspondance (Matches):**
          * Critères généraux: `-p` (protocol), `-s` (source IP), `-d` (destination IP), `--sport` (source port), `--dport` (destination port), `-i` (input interface), `-o` (output interface)
          * Modules de correspondance: `state`, `mac`, `limit`, `owner`, `time`, etc.
3.  **Syntaxe Générale d'iptables**
      * `iptables -t <table_name> -A <chain_name> <match_criteria> -j <target>`
      * Principales options: `-A` (append), `-I` (insert), `-D` (delete), `-R` (replace), `-L` (list), `-F` (flush), `-Z` (zero counters), `-N` (new chain), `-X` (delete chain), `-P` (set policy)
4.  **La Table `filter` (Filtrage de Paquets)**
      * **Chaîne `INPUT`:** Trafic destiné à la machine locale
      * **Chaîne `OUTPUT`:** Trafic généré par la machine locale
      * **Chaîne `FORWARD`:** Trafic traversant la machine (routage)
      * Exemples pratiques de filtrage:
          * Bloquer/autoriser des adresses IP
          * Bloquer/autoriser des ports
          * Protéger le serveur SSH
          * Gérer les connexions établies (`state` module)
          * Limiter les connexions (anti-DDoS basique)
5.  **La Table `nat` (Network Address Translation)**
      * **Chaîne `PREROUTING`:** Modifier les paquets avant le routage (DNAT, REDIRECT)
      * **Chaîne `POSTROUTING`:** Modifier les paquets après le routage (SNAT, MASQUERADE)
      * Exemples pratiques de NAT:
          * Partage de connexion internet (MASQUERADE)
          * Redirection de ports (DNAT)
          * Source NAT (SNAT)
6.  **Les Tables `mangle` et `raw`**
      * **`mangle`:** Modification des en-têtes IP et TCP/UDP (TTL, TOS)
      * **`raw`:** Traitement des paquets avant le suivi de connexion (connection tracking)
      * Cas d'utilisation avancés
7.  **Gestion et Persistance des Règles iptables**
      * Sauvegarder les règles: `iptables-save`
      * Restaurer les règles: `iptables-restore`
      * Méthodes de persistance:
          * Scripts de démarrage
          * `netfilter-persistent` (Debian/Ubuntu)
          * `iptables-services` (CentOS/RHEL)
8.  **Dépannage et Bonnes Pratiques**
      * Ordre des règles
      * Importance de la politique par défaut
      * Utilisation de `LOG` pour le débogage
      * Tester les règles prudemment
      * Documenter ses règles
9.  \*\* iptables vs nftables\*\*
      * Brève comparaison avec nftables, le successeur moderne d'iptables.

-----

### **1. Introduction à iptables et Netfilter**

#### **Qu'est-ce que Netfilter ?**

Netfilter est le framework de pare-feu intégré au noyau Linux. Il fournit un ensemble de "hooks" (points d'ancrage) dans la pile réseau du noyau où les paquets peuvent être interceptés et traités. C'est à ces points que les règles iptables sont appliquées. Netfilter permet non seulement le filtrage de paquets, mais aussi la translation d'adresses réseau (NAT), la modification de paquets (mangling), et bien d'autres choses.

#### **Le rôle d'iptables**

iptables est l'outil en espace utilisateur qui permet d'interagir avec Netfilter. Il fournit une interface en ligne de commande pour définir, modifier et supprimer les règles de pare-feu. Sans iptables, Netfilter ne serait qu'un framework vide.

#### **Philosophie de fonctionnement**

iptables fonctionne sur le principe de "listes de règles". Chaque règle spécifie des critères de correspondance pour un paquet et une cible (action) à exécuter si le paquet correspond. Lorsque un paquet arrive, il traverse différentes "tables" et "chaînes" où les règles sont évaluées séquentiellement. La première règle qui correspond au paquet détermine l'action à entreprendre. Si aucune règle ne correspond, la politique par défaut de la chaîne est appliquée.

-----

### **2. Concepts Fondamentaux d'iptables**

#### **Tables**

Les tables sont des catégories logiques de règles, chacune dédiée à un type spécifique de traitement de paquets. Un paquet ne passe que par un sous-ensemble des tables, en fonction de son type et de son cheminement.

  * `filter` (par défaut): C'est la table la plus courante. Elle est utilisée pour filtrer les paquets, c'est-à-dire décider s'ils doivent être autorisés à passer (ACCEPT) ou bloqués (DROP/REJECT).
  * `nat`: Utilisée pour la translation d'adresses réseau (Network Address Translation). Permet de modifier l'adresse IP source ou destination des paquets. Essentielle pour le partage de connexion et la redirection de ports.
  * `mangle`: Utilisée pour modifier les en-têtes des paquets (TTL, TOS/DSCP). Moins fréquemment utilisée que `filter` ou `nat`, mais utile pour des scénarios avancés (QoS, routage basé sur les politiques).
  * `raw`: Utilisée pour traiter les paquets avant que le suivi de connexion (connection tracking) ne soit effectué. Principalement utilisée pour exclure certains types de trafic du suivi de connexion.
  * `security`: Utilisée pour l'application de politiques de sécurité basées sur le contexte SELinux ou d'autres mécanismes de sécurité. Moins courante pour les administrateurs généraux.

#### **Chaînes (Chains)**

Les chaînes sont des listes ordonnées de règles. Un paquet traverse les règles d'une chaîne séquentiellement jusqu'à ce qu'une règle corresponde ou que toutes les règles aient été évaluées.

  * **Chaînes par défaut (built-in chains):** Ces chaînes sont prédéfinies par Netfilter et représentent des points spécifiques dans le chemin de traitement d'un paquet.

      * `INPUT`: Pour les paquets *entrant* destinés à la machine locale (votre serveur).
      * `OUTPUT`: Pour les paquets *sortant* générés par la machine locale.
      * `FORWARD`: Pour les paquets qui *traversent* la machine (routage), mais qui ne sont ni destinés à elle, ni générés par elle.
      * `PREROUTING`: (Dans la table `nat` et `raw`) Pour les paquets avant que la décision de routage ne soit prise. Idéal pour le DNAT (redirection de ports).
      * `POSTROUTING`: (Dans la table `nat`) Pour les paquets après que la décision de routage ait été prise et juste avant qu'ils ne quittent la machine. Idéal pour le SNAT/MASQUERADE.

  * **Chaînes personnalisées (user-defined chains):** Vous pouvez créer vos propres chaînes pour organiser vos règles de manière logique, ce qui améliore la lisibilité et la maintenabilité. Par exemple, vous pourriez avoir une chaîne `SERVICES_WEB` qui gère toutes les règles pour le trafic HTTP/HTTPS.

#### **Cibles (Targets)**

Une cible est l'action à entreprendre si un paquet correspond aux critères d'une règle.

  * **Actions de base:**

      * `ACCEPT`: Autorise le paquet à passer. Le paquet quitte la chaîne et continue son chemin.
      * `DROP`: Bloque silencieusement le paquet. Le paquet est rejeté sans aucune notification à l'expéditeur. Du point de vue de l'expéditeur, le paquet est simplement perdu.
      * `REJECT`: Bloque le paquet et envoie un message d'erreur (par ex. "Destination Unreachable" ou "Connection Refused") à l'expéditeur. Plus "poli" que `DROP` pour des raisons de débogage, mais peut révéler l'existence de votre hôte.
      * `LOG`: Enregistre les informations du paquet dans les logs du système (généralement `/var/log/syslog` ou `/var/log/messages`). Utile pour le débogage et le monitoring. Souvent utilisé en combinaison avec `ACCEPT` ou `DROP`.

  * **Actions avancées (spécifiques aux tables `nat` et `mangle`):**

      * `SNAT` (Source Network Address Translation): Modifie l'adresse IP source du paquet. Utilisé pour le partage de connexion avec une IP fixe.
      * `DNAT` (Destination Network Address Translation): Modifie l'adresse IP de destination du paquet. Utilisé pour la redirection de ports.
      * `MASQUERADE`: Similaire à `SNAT`, mais l'adresse IP source est automatiquement déterminée par l'interface de sortie (utile pour les connexions WAN dynamiques).
      * `REDIRECT`: Redirige les paquets vers le système local (souvent utilisé pour les serveurs proxy transparents).

  * **Cibles pour les chaînes personnalisées:**

      * `JUMP` (`-j <chain_name>`): Si une règle correspond, le paquet "saute" vers la chaîne personnalisée spécifiée pour un traitement ultérieur. Si le paquet traverse toutes les règles de la chaîne personnalisée sans correspondance, il revient à la règle suivante dans la chaîne d'origine.
      * `RETURN`: Fait revenir le paquet à la chaîne précédente d'où il a été sauté (si c'était une chaîne personnalisée). Si le paquet est dans une chaîne par défaut, il revient à la politique par défaut.

#### **Critères de correspondance (Matches)**

Les critères de correspondance spécifient les conditions qu'un paquet doit remplir pour qu'une règle soit appliquée.

  * **Critères généraux:**

      * `-p <protocol>`: Spécifie le protocole (ex: `tcp`, `udp`, `icmp`, `all`).
      * `-s <source_ip>`: Spécifie l'adresse IP source (ex: `192.168.1.10`, `192.168.1.0/24`).
      * `-d <destination_ip>`: Spécifie l'adresse IP de destination.
      * `--sport <source_port>`: Spécifie le port source (nécessite `-p tcp` ou `-p udp`).
      * `--dport <destination_port>`: Spécifie le port de destination.
      * `-i <input_interface>`: Spécifie l'interface réseau par laquelle le paquet est arrivé (ex: `eth0`, `lo`).
      * `-o <output_interface>`: Spécifie l'interface réseau par laquelle le paquet va sortir.

  * **Modules de correspondance (extensions):** Ces modules étendent les capacités de correspondance d'iptables. Vous devez souvent les charger explicitement ou iptables les charge automatiquement si le critère est utilisé.

      * `state`: Très important \! Permet de filtrer en fonction de l'état de la connexion (`NEW`, `ESTABLISHED`, `RELATED`, `INVALID`).
      * `mac`: Permet de filtrer par adresse MAC.
      * `limit`: Limite le taux de correspondance d'une règle, utile pour prévenir les attaques par déni de service.
      * `owner`: Permet de filtrer les paquets en fonction de l'utilisateur ou du groupe qui les a générés (pour les paquets `OUTPUT`).
      * `time`: Permet de filtrer en fonction de l'heure ou de la date.
      * `multiport`: Permet de spécifier plusieurs ports dans une seule règle.

-----

### **3. Syntaxe Générale d'iptables**

La syntaxe de base d'une commande `iptables` est la suivante:

```bash
iptables -t <table_name> <command> <chain_name> <match_criteria> -j <target>
```

  * `iptables`: La commande principale.

  * `-t <table_name>`: Spécifie la table à utiliser (`filter`, `nat`, `mangle`, `raw`, `security`). Si omise, `filter` est utilisée par défaut.

  * `<command>`: L'action à effectuer sur les règles/chaînes.

      * `-A <chain_name>`: **A**joute une règle à la fin de la chaîne spécifiée.
      * `-I <chain_name> [rule_number]`: **I**nsère une règle au début de la chaîne ou à un numéro de règle spécifique.
      * `-D <chain_name> <rule_spec | rule_number>`: **D**étruit une règle (par spécification ou numéro).
      * `-R <chain_name> <rule_number> <rule_spec>`: **R**emplace une règle existante.
      * `-L [<chain_name>]`: **L**iste les règles d'une chaîne ou de toutes les chaînes. Ajoutez `-n` pour des adresses IP numériques et `-v` pour plus de détails (compteurs). Ajoutez `--line-numbers` pour afficher les numéros de ligne.
      * `-F [<chain_name>]`: **F**lush (vide) toutes les règles d'une chaîne ou de toutes les chaînes.
      * `-Z [<chain_name>]`: **Z**ero les compteurs de paquets et d'octets pour une chaîne ou toutes les chaînes.
      * `-N <chain_name>`: Crée une **N**ouvelle chaîne personnalisée.
      * `-X [<chain_name>]`: Supprime une chaîne e**X**istante (elle doit être vide et non référencée).
      * `-P <chain_name> <target>`: Définit la **P**olitique par défaut (ACCEPT, DROP, REJECT) pour une chaîne. Cette politique est appliquée si aucun paquet ne correspond à aucune règle de la chaîne.

  * `<chain_name>`: La chaîne sur laquelle la commande doit opérer.

  * `<match_criteria>`: Les conditions que le paquet doit remplir.

  * `-j <target>`: La cible (action) à exécuter si le paquet correspond.

-----

### **4. La Table `filter` (Filtrage de Paquets)**

La table `filter` est la plus utilisée et est responsable de la décision d'autoriser, de bloquer ou de rejeter les paquets.

#### **Chaîne `INPUT`**

Traite les paquets destinés à la machine locale.

**Exemples :**

  * **Autoriser les connexions SSH entrantes (port 22) depuis n'importe où :**
    ```bash
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    ```
  * **Bloquer toutes les connexions SSH entrantes sauf depuis une IP spécifique :**
    ```bash
    sudo iptables -A INPUT -p tcp --dport 22 -s 192.168.1.100 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 22 -j DROP
    ```
    *Note: L'ordre est crucial. La règle d'acceptation doit être avant la règle de blocage.*
  * **Autoriser le trafic de bouclage (localhost) :** Essentiel pour de nombreuses applications.
    ```bash
    sudo iptables -A INPUT -i lo -j ACCEPT
    ```
  * **Autoriser les connexions établies et liées :** Très important pour que les connexions sortantes (par exemple, navigation web) puissent recevoir des réponses.
    ```bash
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ```
    *Explication: Le module `state` est utilisé. `ESTABLISHED` signifie que le paquet fait partie d'une connexion déjà établie. `RELATED` signifie qu'il est lié à une connexion existante (par exemple, un transfert de données FTP qui utilise un port différent pour la connexion de données).*
  * **Bloquer le trafic ICMP (ping) :**
    ```bash
    sudo iptables -A INPUT -p icmp -j DROP
    ```
  * **Journaliser les paquets bloqués non désirés :**
    ```bash
    sudo iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTABLES BLOCKED: " --log-level info
    sudo iptables -A INPUT -j DROP
    ```
    *Note: Le module `limit` est utilisé pour éviter d'inonder les logs.*

#### **Chaîne `OUTPUT`**

Traite les paquets générés par la machine locale.

**Exemples :**

  * **Autoriser toutes les connexions sortantes (par défaut très permissif) :**
    ```bash
    sudo iptables -A OUTPUT -j ACCEPT
    ```
  * **Bloquer les requêtes DNS sortantes (port 53) :**
    ```bash
    sudo iptables -A OUTPUT -p udp --dport 53 -j REJECT
    ```
  * **Autoriser seulement les connexions HTTP et HTTPS sortantes :**
    ```bash
    sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
    sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # Pour les réponses entrantes
    sudo iptables -A OUTPUT -j DROP
    ```

#### **Chaîne `FORWARD`**

Traite les paquets qui traversent la machine (lorsqu'elle agit comme un routeur).

**Exemples :**

  * **Permettre le routage de trafic entre deux interfaces (ex: entre un réseau interne et Internet) :**
      * Assurez-vous que le routage IP est activé dans le noyau :
        ```bash
        echo 1 > /proc/sys/net/ipv4/ip_forward
        # Ou modifier /etc/sysctl.conf : net.ipv4.ip_forward = 1 et exécuter sysctl -p
        ```
      * Règles de `FORWARD` pour autoriser le trafic du réseau interne vers Internet et vice-versa pour les connexions établies :
        ```bash
        sudo iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT # eth0 = interne, eth1 = externe
        sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
        ```
  * **Bloquer le trafic de la zone démilitarisée (DMZ) vers le réseau interne :**
    ```bash
    sudo iptables -A FORWARD -i eth2 -o eth0 -j DROP # eth2 = DMZ, eth0 = interne
    ```

#### **Politiques par défaut (Default Policies)**

C'est une bonne pratique de définir la politique par défaut des chaînes `INPUT`, `OUTPUT` et `FORWARD` sur `DROP` après avoir autorisé explicitement le trafic nécessaire. Cela assure que tout ce qui n'est pas explicitement autorisé est bloqué.

```bash
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
sudo iptables -P FORWARD DROP
```

*Attention: Faites cela avec précaution \! Assurez-vous d'avoir des règles d'ACCEPT pour le SSH ou votre accès de gestion avant de définir la politique sur DROP, sinon vous pourriez vous retrouver bloqué.*

-----

### **5. La Table `nat` (Network Address Translation)**

La table `nat` est utilisée pour réécrire les adresses IP et/ou les ports des paquets. Elle est cruciale pour le partage de connexion (NAT) et la redirection de ports.

#### **Chaîne `PREROUTING`**

Les règles de cette chaîne sont appliquées aux paquets *avant* que le noyau ne prenne une décision de routage. Idéale pour le DNAT.

**Exemples :**

  * **Redirection de ports (DNAT - Destination NAT) :**
    Rediriger tout le trafic entrant sur le port 80 de l'interface `eth0` vers le port 8080 d'un serveur web interne (ex: 192.168.1.100).

    ```bash
    sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080
    ```

    *Important : N'oubliez pas d'autoriser le trafic `FORWARD` si le serveur interne est sur un sous-réseau différent.*

  * **Redirection de trafic vers un proxy transparent (REDIRECT) :**
    Rediriger tout le trafic HTTP sortant vers un proxy local écoutant sur le port 3128.

    ```bash
    sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3128
    ```

#### **Chaîne `POSTROUTING`**

Les règles de cette chaîne sont appliquées aux paquets *après* que le noyau ait pris une décision de routage et juste avant que le paquet ne quitte l'interface de sortie. Idéale pour le SNAT/MASQUERADE.

**Exemples :**

  * **Partage de connexion internet (MASQUERADE) :**
    Permet aux machines d'un réseau interne d'accéder à Internet via votre machine Linux qui a une seule adresse IP publique dynamique.

    ```bash
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    ```

    *Explication: `eth0` est l'interface connectée à Internet. Tous les paquets sortant par `eth0` verront leur adresse IP source remplacée par l'adresse IP de `eth0`. Lors du retour des réponses, iptables "démasque" les paquets et les renvoie à la machine interne appropriée.*

  * **Source NAT (SNAT) :**
    Similaire à `MASQUERADE`, mais utilisé lorsque l'adresse IP publique de l'interface sortante est fixe.

    ```bash
    sudo iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source <your_public_ip>
    ```

-----

### **6. Les Tables `mangle` et `raw`**

Ces tables sont utilisées pour des cas d'utilisation plus avancés et ne sont généralement pas nécessaires pour la plupart des configurations de pare-feu de base.

#### **Table `mangle`**

Utilisée pour modifier les en-têtes des paquets IP (TTL, TOS/DSCP) et TCP/UDP.

**Exemples :**

  * **Modifier le TTL (Time To Live) :** Utile pour masquer qu'une machine agit comme un routeur ou pour contourner certaines restrictions FAI.
    ```bash
    sudo iptables -t mangle -A PREROUTING -i eth0 -j TTL --ttl-set 64
    ```
  * **Marquer les paquets pour la qualité de service (QoS) :**
    ```bash
    sudo iptables -t mangle -A PREROUTING -p tcp --dport 80 -j MARK --set-mark 10
    ```
    Ces marques peuvent ensuite être utilisées par d'autres outils (comme `tc` - traffic control) pour prioriser ou limiter le trafic.

#### **Table `raw`**

Utilisée pour traiter les paquets avant que le suivi de connexion (`connection tracking`) ne soit effectué. Principalement utilisée pour exclure certains types de trafic du suivi de connexion si cela pose problème (par exemple, pour des performances extrêmes ou pour éviter des conflits avec des applications personnalisées de gestion de connexion).

**Exemples :**

  * **Ne pas suivre la connexion pour un trafic spécifique :**
    ```bash
    sudo iptables -t raw -A PREROUTING -p udp --dport 53 -j NOTRACK
    ```

-----

### **7. Gestion et Persistance des Règles iptables**

Les règles iptables sont volatiles. Elles sont stockées en mémoire et seront perdues au redémarrage du système à moins qu'elles ne soient explicitement sauvegardées et restaurées.

#### **Sauvegarder les règles : `iptables-save`**

`iptables-save` affiche les règles actuelles dans un format que `iptables-restore` peut comprendre.

```bash
sudo iptables-save > /etc/iptables/rules.v4 # Pour IPv4
sudo ip6tables-save > /etc/iptables/rules.v6 # Pour IPv6
```

*Il est courant de créer un répertoire `/etc/iptables` si non existant.*

#### **Restaurer les règles : `iptables-restore`**

`iptables-restore` lit les règles depuis un fichier et les applique.

```bash
sudo iptables-restore < /etc/iptables/rules.v4
sudo ip6tables-restore < /etc/iptables/rules.v6
```

#### **Méthodes de persistance**

  * **Scripts de démarrage personnalisés :** Vous pouvez créer un script shell qui exécute `iptables-restore` au démarrage du système et le placer dans `/etc/rc.local` (si disponible et activé) ou le configurer comme un service Systemd.

  * **`netfilter-persistent` (Debian/Ubuntu) :**
    Ce paquet facilite la persistance.

    ```bash
    sudo apt install netfilter-persistent iptables-persistent
    ```

    Lors de l'installation, il vous demandera si vous souhaitez sauvegarder les règles actuelles. Ensuite, pour sauvegarder à tout moment :

    ```bash
    sudo netfilter-persistent save
    ```

    Les règles sont stockées dans `/etc/iptables/rules.v4` et `/etc/iptables/rules.v6`. Elles sont automatiquement restaurées au démarrage.

  * **`iptables-services` (CentOS/RHEL) :**
    Sur les systèmes basés sur Red Hat (CentOS, Fedora, RHEL), le paquet `iptables-services` fournit des services Systemd pour gérer la persistance.

    ```bash
    sudo yum install iptables-services
    sudo systemctl enable iptables # Pour démarrer au boot
    sudo systemctl enable ip6tables
    sudo systemctl start iptables # Pour démarrer maintenant
    sudo systemctl start ip6tables
    sudo iptables-save > /etc/sysconfig/iptables # Sauvegarder les règles
    sudo ip6tables-save > /etc/sysconfig/ip6tables
    # Ou pour sauvegarder après avoir modifié les règles :
    sudo service iptables save
    ```

-----

### **8. Dépannage et Bonnes Pratiques**

  * **Ordre des règles :** L'ordre des règles est crucial. Une fois qu'un paquet correspond à une règle et qu'une cible est appliquée (sauf `LOG`), le traitement des règles pour ce paquet s'arrête dans cette chaîne. Mettez les règles les plus spécifiques ou les plus restrictives en premier.
  * **Politique par défaut :** Toujours commencer par une politique par défaut permissive (ACCEPT) pendant que vous construisez et testez vos règles. Une fois que vous êtes sûr, changez-la en `DROP`.
    ```bash
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P OUTPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    # ... ajoutez vos règles de ACCEPT ...
    # ... à la fin, après les tests réussis ...
    sudo iptables -P INPUT DROP
    sudo iptables -P OUTPUT DROP
    sudo iptables -P FORWARD DROP
    ```
  * **Utilisation de `LOG` pour le débogage :** La cible `LOG` est votre meilleure amie pour comprendre ce qui se passe. Placez des règles `LOG` stratégiquement pour voir quels paquets correspondent à quelles règles ou quels paquets sont bloqués.
    ```bash
    sudo iptables -A INPUT -j LOG --log-prefix "DEBUG_INPUT: "
    ```
  * **Tester les règles prudemment :** Lorsque vous modifiez des règles critiques (comme celles qui affectent votre connexion SSH), ouvrez une deuxième session SSH avant de les appliquer, de sorte que si vous vous bloquez, vous pouvez utiliser la première session pour annuler les modifications.
  * **Documenter ses règles :** Les configurations iptables peuvent devenir complexes. Ajoutez des commentaires dans vos scripts de sauvegarde ou utilisez des noms de chaînes personnalisées significatifs.
  * **Évitez les règles génériques :** Soyez aussi spécifique que possible. Plutôt que de bloquer tout le trafic UDP, bloquez seulement les ports UDP non nécessaires.
  * **Vider les règles et les compteurs :**
      * `sudo iptables -F`: Vide toutes les règles de la table `filter`.
      * `sudo iptables -X`: Supprime toutes les chaînes personnalisées (après les avoir vidées).
      * `sudo iptables -Z`: Remet à zéro les compteurs de paquets/octets. Utile pour voir le trafic après une modification de règle.
  * **Afficher les règles :**
      * `sudo iptables -L -n -v --line-numbers`: Affiche les règles avec les numéros de ligne, les détails (octets/paquets) et les adresses numériques (sans résolution DNS). Très utile.

-----

### **9. iptables vs nftables**

nftables est le successeur moderne d'iptables, conçu pour être plus flexible, plus performant et plus facile à utiliser pour des configurations complexes. Il remplace `iptables`, `ip6tables`, `arptables` et `ebtables` par une interface de ligne de commande unifiée et un langage de règles plus expressif.

  * **Similitudes :** Les concepts de base (tables, chaînes, cibles, critères) sont toujours présents.
  * **Différences :**
      * **Syntaxe :** La syntaxe de `nftables` est différente et plus proche d'un langage de programmation.
      * **Unified interface :** Gère IPv4, IPv6, ARP, et pontage Ethernet avec une seule commande.
      * **Atomic updates :** Les modifications peuvent être appliquées de manière atomique, réduisant les risques d'erreurs transitoires.
      * **Plus de flexibilité :** Permet des cartes, des ensembles, des boucles, etc.
  * **Migration :** De nombreuses distributions Linux modernes migrent vers `nftables` par défaut. Il existe un outil `iptables-nft` qui fournit une compatibilité en utilisant le backend `nftables` pour les commandes `iptables`.

