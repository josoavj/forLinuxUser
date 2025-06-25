# nmap (Network Mapper)

### **Table des Matières**

1.  **Introduction à Nmap**
      * Qu'est-ce que Nmap ?
      * À quoi sert Nmap ?
      * Historique et philosophie
      * L'éthique d'utilisation de Nmap
2.  **Installation de Nmap**
      * Sur Linux (Debian/Ubuntu, CentOS/RHEL, Arch Linux)
      * Sur Windows
      * Sur macOS
3.  **Les Bases de Nmap : Premiers Scans**
      * Syntaxe générale
      * Scan d'hôte simple
      * Scan de plage d'adresses IP
      * Scan de sous-réseau
      * Scan de plusieurs hôtes à partir d'un fichier
      * Exclure des hôtes du scan
4.  **Techniques de Scan de Ports**
      * **Scan TCP SYN (Stealth Scan) : `-sS`**
          * Comment ça marche ?
          * Avantages et inconvénients
      * **Scan TCP Connect : `-sT`**
          * Comment ça marche ?
          * Avantages et inconvénients
      * **Scan UDP : `-sU`**
          * Comment ça marche ?
          * Défis du scan UDP
      * **Scan FIN, Xmas, Null : `-sF`, `-sX`, `-sN`**
          * Comment ça marche ?
          * Contournement des pare-feu simples
      * **Scan ACK : `-sA`**
          * Comment ça marche ?
          * Détermination de l'état du pare-feu
      * **Scan des ports les plus courants : `-F`**
      * **Scan de tous les ports : `-p-` ou `-p 1-65535`**
      * **Scan de ports spécifiques : `-p 22,80,443`**
5.  **Détection de Services et de Versions : `-sV`**
      * Comment Nmap détecte-t-il les services et leurs versions ?
      * La base de données `nmap-service-probes`
      * Intensité de détection : `--version-intensity`
      * Détection des services légers : `--version-light`
      * Force brute de détection : `--version-all`
6.  **Détection du Système d'Exploitation (OS Detection) : `-O`**
      * Comment Nmap identifie-t-il l'OS ?
      * Fiabilité de la détection
      * Options avancées : `--osscan-limit`, `--osscan-guess`
7.  **Le Nmap Scripting Engine (NSE)**
      * Qu'est-ce que le NSE ?
      * Comment utiliser les scripts NSE : `--script`
      * Catégories de scripts NSE (auth, vuln, exploit, discovery, etc.)
      * Exemples de scripts utiles :
          * Détection de vulnérabilités (ex: `smb-vuln-ms17-010`)
          * Énumération (ex: `smb-enum-shares`, `http-enum`)
          * Force brute (ex: `ftp-brute`)
          * Information (ex: `whois`)
8.  **Optimisation des Scans (Performance)**
      * Gestion du temps d'exécution : `-T<0-5>`
      * `--min-rate`, `--max-rate`
      * `--min-hostgroup`, `--max-hostgroup`
      * `--host-timeout`
      * `--scan-delay`, `--max-retries`
9.  **Gestion des Sorties de Nmap**
      * Sortie normale : par défaut
      * Sortie XML : `-oX` (pour l'intégration avec d'autres outils)
      * Sortie Grepable : `-oG` (pour le traitement par script)
      * Sortie de tous les formats : `-oA`
      * Mode verbeux : `-v`, `-vv`
      * Afficher les paquets envoyés/reçus : `--packet-trace`
10. **Contournement des Pare-feu et IDS/IPS**
      * Fragmentation de paquets : `-f`
      * Spécification d'un MTU : `--mtu`
      * Utilisation de proxys/chaînes de proxys : `--proxy`
      * Utilisation d'adresses MAC aléatoires : `--spoof-mac`
      * Décoys : `-D`
      * Spécification d'une source IP : `-S`
      * Pause entre les probes : `--scan-delay`
11. **Scan Avancé et Options Utiles**
      * Ping scan : `-sn` (anciennement `-sP`)
      * Ne pas pinguer : `-Pn` (anciennement `-P0`)
      * Détection de version sans scan de ports : `-sV --version-intensity 0`
      * Récupération de bannières : `—script=banner`
      * Scans IPv6 : `-6`
      * Scans sur des plages non conventionnelles
12. **Zenmap : L'interface Graphique de Nmap**
      * Présentation de Zenmap
      * Fonctionnalités principales
      * Utilisation pour les débutants
13. **Cas d'Utilisation et Scénarios Pratiques**
      * Audit de sécurité
      * Inventaire réseau
      * Dépannage réseau
      * Test de vulnérabilité
14. **Éthique et Législation**
      * L'importance du consentement
      * Cadre légal (selon les pays)
      * Utilisation responsable

-----

### **1. Introduction à Nmap**

#### **Qu'est-ce que Nmap ?**

Nmap (Network Mapper) est un utilitaire open source et gratuit utilisé pour l'exploration de réseau et l'audit de sécurité. Il a été conçu pour scanner rapidement de grands réseaux, mais fonctionne parfaitement contre des hôtes uniques. Nmap est devenu un outil indispensable pour les administrateurs système, les professionnels de la sécurité, les auditeurs et les pentesters.

#### **À quoi sert Nmap ?**

  * **Découverte d'hôtes :** Identifier les appareils actifs sur un réseau.
  * **Détection de ports ouverts :** Découvrir quels services écoutent sur quels ports.
  * **Identification des services et de leurs versions :** Déterminer les applications (Apache, Nginx, OpenSSH, etc.) et leurs versions exactes, ce qui est crucial pour identifier les vulnérabilités connues.
  * **Détection du système d'exploitation (OS) :** Identifier l'OS et parfois même sa version et son type d'appareil.
  * **Recherche de vulnérabilités :** Grâce au Nmap Scripting Engine (NSE), Nmap peut détecter des vulnérabilités, énumérer des informations, ou même exploiter certains problèmes.
  * **Audit de configuration de pare-feu :** Comprendre comment un pare-feu réagit à différents types de paquets.
  * **Inventaire réseau :** Créer une carte détaillée des périphériques connectés, de leurs services et de leurs systèmes d'exploitation.
  * **Dépannage réseau :** Diagnostiquer des problèmes de connectivité ou de service.

#### **Historique et philosophie**

Nmap a été créé par Gordon Lyon (alias Fyodor) en 1997. Il est continuellement développé par une communauté active. Sa philosophie est d'être un outil puissant, flexible et extensible, tout en restant simple d'utilisation pour les tâches courantes.

#### **L'éthique d'utilisation de Nmap**

Nmap est un outil d'audit. **Il est illégal et non éthique de scanner des réseaux ou des systèmes sans l'autorisation explicite du propriétaire.** Utiliser Nmap sur des systèmes non autorisés peut avoir de graves conséquences légales. Utilisez-le uniquement sur vos propres systèmes, sur des réseaux pour lesquels vous avez une permission écrite, ou sur des plateformes d'entraînement légales (comme Hack The Box, TryHackMe, etc.).

-----

### **2. Installation de Nmap**

Nmap est multiplateforme et facile à installer.

  * **Sur Linux (Debian/Ubuntu) :**
    ```bash
    sudo apt update
    sudo apt install nmap
    ```
  * **Sur Linux (CentOS/RHEL) :**
    ```bash
    sudo yum install nmap
    # ou pour les versions plus récentes
    sudo dnf install nmap
    ```
  * **Sur Linux (Arch Linux) :**
    ```bash
    sudo pacman -S nmap
    ```
  * **Sur Windows :**
    Téléchargez l'installeur `.exe` depuis le site officiel de Nmap : [https://nmap.org/download.html](https://nmap.org/download.html). L'installeur inclut Nmap, Zenmap (l'interface graphique), Npcap (un pilote de capture de paquets) et dmap.
  * **Sur macOS :**
    Téléchargez le paquet `.dmg` depuis le site officiel de Nmap ou utilisez Homebrew :
    ```bash
    brew install nmap
    ```

-----

### **3. Les Bases de Nmap : Premiers Scans**

La syntaxe de base de Nmap est simple : `nmap [options] <cible(s)>`.

#### **Scan d'hôte simple**

```bash
nmap 192.168.1.1 # Scanne un hôte spécifique
nmap example.com # Scanne un nom de domaine
```

*Le résultat affichera les ports ouverts par défaut, leur service présumé et leur état.*

#### **Scan de plage d'adresses IP**

```bash
nmap 192.168.1.1-100 # Scanne de .1 à .100
nmap 192.168.1.1,5,10 # Scanne des hôtes spécifiques dans une liste
```

#### **Scan de sous-réseau (CIDR)**

```bash
nmap 192.168.1.0/24 # Scanne tout un sous-réseau (256 adresses)
```

#### **Scan de plusieurs hôtes à partir d'un fichier**

Créez un fichier texte (ex: `hosts.txt`) avec une cible par ligne.

```
192.168.1.1
192.168.1.5
google.com
```

Puis, scannez :

```bash
nmap -iL hosts.txt
```

#### **Exclure des hôtes du scan**

```bash
nmap 192.168.1.0/24 --exclude 192.168.1.10,192.168.1.20 # Exclut des adresses spécifiques
nmap 192.168.1.0/24 --excludefile exclude.txt # Exclut des hôtes listés dans un fichier
```

-----

### **4. Techniques de Scan de Ports**

Nmap offre de nombreuses techniques de scan pour s'adapter à différentes situations (détection par pare-feu, rapidité, précision).

#### **Scan TCP SYN (Stealth Scan) : `-sS`**

  * **Comment ça marche ?** Nmap envoie un paquet SYN au port cible. Si le port est ouvert, il reçoit un paquet SYN/ACK (réponse positive). Nmap envoie alors un paquet RST (Reset) pour fermer la connexion sans jamais établir une session complète. Si le port est fermé, il reçoit un paquet RST.
  * **Avantages :** C'est le scan par défaut et le plus populaire. Il est "furtif" car il ne termine pas la poignée de main TCP complète, ce qui le rend moins susceptible d'être journalisé par les applications sur le port cible. Il est rapide et efficace.
  * **Inconvénients :** Nécessite des privilèges `root` (ou administrateur sur Windows) pour construire des paquets RAW.

#### **Scan TCP Connect : `-sT`**

  * **Comment ça marche ?** Nmap initie une poignée de main TCP complète (SYN, SYN/ACK, ACK) pour chaque port. Si la poignée de main réussit, le port est ouvert. Si un RST est reçu, le port est fermé.
  * **Avantages :** Ne nécessite pas de privilèges `root`, car il utilise la fonction `connect()` du système d'exploitation.
  * **Inconvénients :** Plus lent et plus "bruyant" que le scan SYN car il établit des connexions complètes, ce qui est plus facilement détectable et journalisable.

#### **Scan UDP : `-sU`**

  * **Comment ça marche ?** Nmap envoie des paquets UDP aux ports cibles. S'il ne reçoit aucune réponse, le port est potentiellement ouvert ou filtré. Si un message "ICMP port unreachable" est reçu, le port est fermé.
  * **Défis :** Le scan UDP est beaucoup plus lent et moins fiable que les scans TCP. Un port UDP ouvert n'envoie généralement pas de réponse par défaut, ce qui rend difficile de distinguer un port ouvert d'un port filtré. Nmap peut envoyer des "probes" spécifiques pour tenter de déclencher une réponse de certains services UDP connus (DNS, DHCP, SNMP).

#### **Scan FIN, Xmas, Null : `-sF`, `-sX`, `-sN`**

Ces scans exploitent la manière dont certains systèmes d'exploitation (notamment Linux/Unix) gèrent les paquets TCP non conventionnels. Ils sont conçus pour contourner les pare-feu simples qui ne filtrent que les paquets SYN. Ils ne fonctionnent généralement pas sur Windows.

  * **Scan FIN (`-sF`) :** Envoie un paquet avec le flag FIN.

  * **Scan Xmas (`-sX`) :** Envoie un paquet avec les flags FIN, URG, PSH (toutes les lumières de l'arbre de Noël s'allument).

  * **Scan Null (`-sN`) :** Envoie un paquet sans aucun flag TCP.

  * **Comment ça marche ?**

      * **Port ouvert :** Si le port est ouvert, un système conforme au RFC 793 n'enverra aucune réponse.
      * **Port fermé :** Si le port est fermé, il enverra un paquet RST.

  * **Avantages :** Plus furtif que les scans SYN/Connect, peut passer inaperçu devant certains pare-feu simples.

  * **Inconvénients :** Ne fonctionne pas sur tous les systèmes, plus lent.

#### **Scan ACK : `-sA`**

  * **Comment ça marche ?** Nmap envoie des paquets ACK avec un numéro de séquence aléatoire.
  * **Utilité :** Ce scan ne peut pas déterminer si un port est ouvert ou fermé. Il est utilisé pour déterminer si un pare-feu est présent et comment il se comporte.
      * Si un paquet RST est reçu, le port est "unfiltered" (non filtré par état, mais peut être fermé).
      * Si aucune réponse n'est reçue, le port est "filtered" (filtré par un pare-feu avec état).
  * **Avantages :** Excellent pour cartographier les règles de pare-feu.

#### **Scan des ports les plus courants : `-F` (Fast Scan)**

  * Scanne les 100 ports les plus courants. Plus rapide qu'un scan complet.

#### **Scan de tous les ports : `-p-` ou `-p 1-65535`**

  * Scanne tous les 65535 ports TCP (ou UDP si utilisé avec `-sU`).
    ```bash
    nmap -p- 192.168.1.1
    nmap -p 1-65535 192.168.1.1
    ```

#### **Scan de ports spécifiques : `-p 22,80,443`**

  * Scanne uniquement les ports spécifiés.
    ```bash
    nmap -p 22,80,443,3389 192.168.1.1
    ```
  * Vous pouvez spécifier des plages : `-p 1-1000`
  * Vous pouvez spécifier des protocoles : `-p T:22,80, U:53` (TCP 22, 80 et UDP 53)

-----

### **5. Détection de Services et de Versions : `-sV`**

L'option `-sV` est essentielle pour obtenir des informations détaillées sur les services.

  * **Comment Nmap détecte-t-il les services et leurs versions ?**
    Lorsqu'un port est identifié comme ouvert, Nmap ne se contente pas de deviner le service basé sur le port (ex: 80 est souvent HTTP). Il envoie une série de "probes" (sondes) au service et analyse les réponses (appelées "bannières"). Ces probes sont des requêtes spécifiques que Nmap sait que certains services répondent de manière prévisible (ex: une requête HTTP GET, une salutation SSH).

  * **La base de données `nmap-service-probes` :**
    Nmap utilise une vaste base de données (située généralement dans `/usr/share/nmap/nmap-service-probes`) qui contient des milliers de probes pour différents services et des expressions régulières pour analyser leurs réponses et identifier le service, la version, le produit, et parfois même le système d'exploitation sous-jacent.

  * **Intensité de détection : `--version-intensity <0-9>`**
    Contrôle l'agressivité de la détection de version. `9` est le plus agressif (et le plus lent), `0` est le plus léger. Par défaut, c'est `7`.

  * **Détection des services légers : `--version-light`**
    Équivalent à `--version-intensity 2`. Moins précis mais plus rapide.

  * **Force brute de détection : `--version-all`**
    Équivalent à `--version-intensity 9`. Nmap essaiera toutes les probes possibles.

**Exemple :**

```bash
nmap -sS -sV 192.168.1.1
```

Ceci effectuera un scan SYN et tentera de déterminer les services et leurs versions sur les ports ouverts.

-----

### **6. Détection du Système d'Exploitation (OS Detection) : `-O`**

L'option `-O` tente d'identifier le système d'exploitation de la cible.

  * **Comment Nmap identifie-t-il l'OS ?**
    Nmap envoie une série de paquets TCP et UDP au système cible et analyse finement les réponses. Il examine des caractéristiques spécifiques de l'implémentation de la pile réseau (TCP/IP) du système d'exploitation, telles que :

      * Taille de la fenêtre TCP initiale
      * Options TCP prises en charge
      * Ordre des options TCP
      * Traitement des flags TCP non conventionnels
      * Numéros de séquence initiaux (ISN)
      * Réponses ICMP
      * Comportement des paquets UDP spécifiques
        Ces informations sont comparées à une base de données d'empreintes digitales (`nmap-os-db`).

  * **Fiabilité de la détection :**
    La détection d'OS est généralement très précise, surtout pour les systèmes d'exploitation courants. Cependant, elle peut être moins fiable si le système est derrière un pare-feu restrictif ou si Nmap ne reçoit pas suffisamment de réponses distinctes.

  * **Options avancées :**

      * `--osscan-limit` : Ne tente la détection d'OS que sur les hôtes ayant au moins un port ouvert et un port fermé. Ceci permet d'éviter de scanner des hôtes potentiellement inactifs ou protégés par un pare-feu, ce qui ralentirait le processus.
      * `--osscan-guess` : Nmap sera plus agressif dans sa tentative de deviner l'OS si la correspondance n'est pas parfaite.

**Exemple :**

```bash
nmap -sS -O 192.168.1.1
nmap -sS -sV -O 192.168.1.1 # Combine la détection de service et d'OS
```

-----

### **7. Le Nmap Scripting Engine (NSE)**

Le NSE est l'une des fonctionnalités les plus puissantes et les plus flexibles de Nmap. Il permet aux utilisateurs (et aux développeurs Nmap) d'écrire des scripts en langage Lua pour automatiser un large éventail de tâches de découverte, d'audit et d'exploitation.

#### **Qu'est-ce que le NSE ?**

C'est un moteur qui permet d'exécuter des scripts Nmap. Ces scripts sont situés dans le répertoire `nmap/scripts` (par exemple, `/usr/share/nmap/scripts/`).

#### **Comment utiliser les scripts NSE : `--script`**

  * **Exécuter un script spécifique :**
    ```bash
    nmap --script http-enum 192.168.1.100
    ```
  * **Exécuter plusieurs scripts :**
    ```bash
    nmap --script http-enum,ssl-enum-ciphers 192.168.1.100
    ```
  * **Exécuter une catégorie de scripts :**
    ```bash
    nmap --script vuln 192.168.1.100 # Exécute tous les scripts de la catégorie 'vuln'
    ```
  * **Exécuter plusieurs catégories :**
    ```bash
    nmap --script default,discovery 192.168.1.100
    ```
  * **Exécuter tous les scripts :**
    ```bash
    nmap --script all 192.168.1.100 # Peut être très lent et bruyant !
    ```
  * **Passer des arguments aux scripts :**
    ```bash
    nmap --script http-brute --script-args userdb=users.txt,passdb=passwords.txt 192.168.1.100
    ```
  * **Mettre à jour les scripts (si vous utilisez une version Git ou installez des scripts manuellement) :**
    ```bash
    sudo nmap --script-updatedb
    ```

#### **Catégories de scripts NSE**

Voici quelques-unes des catégories les plus courantes :

  * `auth`: Scripts liés à l'authentification.
  * `brute`: Scripts de force brute de mots de passe.
  * `default`: Scripts exécutés par défaut avec `-sC`.
  * `discovery`: Scripts de découverte de services et d'informations.
  * `dos`: Scripts de déni de service (à utiliser avec extrême prudence et autorisation \!).
  * `exploit`: Scripts d'exploitation (également à utiliser avec extrême prudence).
  * `fuzzer`: Scripts de fuzzing pour trouver des bogues.
  * `intrusive`: Scripts qui peuvent être considérés comme intrusifs ou bruyants.
  * `malware`: Scripts pour détecter des logiciels malveillants ou des backdoors.
  * `safe`: Scripts considérés comme sûrs et non destructifs.
  * `vuln`: Scripts pour détecter des vulnérabilités connues.

#### **Exemples de scripts utiles :**

  * **`nmap --script http-enum <cible>` :** Énumère les répertoires et fichiers courants sur un serveur web.
  * **`nmap --script smb-enum-shares <cible>` :** Énumère les partages SMB sur un serveur Windows.
  * **`nmap --script ssl-enum-ciphers <cible>` :** Vérifie les chiffrements SSL/TLS supportés par un serveur, identifie les faiblesses.
  * **`nmap --script vuln <cible>` :** Exécute une série de scripts de détection de vulnérabilités. (Peut être lent et bruyant)
  * **`nmap --script dns-brute <cible>` :** Tente de découvrir des sous-domaines via la force brute DNS.
  * **`nmap --script ftp-anon <cible>` :** Vérifie si un serveur FTP autorise la connexion anonyme.

-----

### **8. Optimisation des Scans (Performance)**

Pour des scans de grands réseaux ou pour s'adapter à des environnements lents, l'optimisation est clé.

  * **Gestion du temps d'exécution : `-T<0-5>` (Timing Templates)**
    Ces options prédéfinissent un ensemble de paramètres de temporisation.

      * `-T0` (Paranoid) : Très lent, furtif, pour IDS.
      * `-T1` (Sneaky) : Très lent, furtif.
      * `-T2` (Polite) : Ralentit pour éviter de surcharger le réseau, moins d'erreurs.
      * `-T3` (Normal) : Par défaut. Équilibré.
      * `-T4` (Aggressive) : Plus rapide, suppose un réseau rapide et fiable.
      * `-T5` (Insane) : Le plus rapide, peut provoquer des erreurs sur des réseaux lents.

  * **Contrôle des taux de paquets : `--min-rate`, `--max-rate`**

      * `--min-rate <nombre>` : Envoie des paquets à au moins `nombre` par seconde. Utile pour accélérer un scan lent.
      * `--max-rate <nombre>` : N'envoie pas plus de `nombre` paquets par seconde. Utile pour ne pas surcharger la cible ou le réseau.

  * **Contrôle des groupes d'hôtes : `--min-hostgroup`, `--max-hostgroup`**
    Permet de traiter plusieurs hôtes en parallèle.

  * **Délai d'attente pour les hôtes : `--host-timeout <temps>`**
    Abandonne un hôte après un certain temps (ex: `10m` pour 10 minutes). Utile pour éviter qu'un hôte mort ne bloque le scan.

  * **Délai entre les probes : `--scan-delay <temps>`**
    Délai minimum entre l'envoi de chaque probe. Utile pour contourner les protections basées sur le taux de paquets. (ex: `--scan-delay 1s`).

  * **Nombre maximum de tentatives : `--max-retries <nombre>`**
    Nombre maximum de fois que Nmap essaiera de recontacter un hôte ou un port qui ne répond pas.

-----

### **9. Gestion des Sorties de Nmap**

Nmap offre plusieurs formats de sortie pour s'adapter à différents besoins.

  * **Sortie normale (par défaut) :** Affichée sur la console. Lisible par l'humain.

    ```bash
    nmap 192.168.1.1
    ```

  * **Sortie XML : `-oX <fichier.xml>`**
    Format XML, idéal pour le traitement automatique par d'autres outils, l'intégration dans des scripts ou des bases de données.

    ```bash
    nmap -sV -O -oX results.xml 192.168.1.0/24
    ```

  * **Sortie Grepable : `-oG <fichier.txt>`**
    Format simple, une ligne par hôte, facile à parser avec des outils comme `grep`, `awk`, `cut`.

    ```bash
    nmap -oG hosts_open_ports.txt 192.168.1.0/24
    ```

    Exemple d'utilisation : `cat hosts_open_ports.txt | grep "80/open"`

  * **Sortie de tous les formats : `-oA <prefixe>`**
    Crée trois fichiers : `.nmap` (normale), `.xml` (XML), `.gnmap` (grepable) avec le préfixe donné.

    ```bash
    nmap -sV -O -oA my_scan_results 192.168.1.0/24
    # Crée my_scan_results.nmap, my_scan_results.xml, my_scan_results.gnmap
    ```

  * **Mode verbeux : `-v`, `-vv`**
    Affiche plus d'informations pendant le scan, utile pour le débogage ou pour suivre la progression. `-vv` est encore plus verbeux.

    ```bash
    nmap -v 192.168.1.1
    ```

  * **Afficher les paquets envoyés/reçus : `--packet-trace`**
    Affiche chaque paquet envoyé et reçu, utile pour le débogage avancé ou pour comprendre le fonctionnement de Nmap.

    ```bash
    nmap --packet-trace 192.168.1.1
    ```

-----

### **10. Contournement des Pare-feu et IDS/IPS**

Nmap propose des options pour rendre le scan plus discret et tenter de contourner les systèmes de détection d'intrusion.

  * **Fragmentation de paquets : `-f` (Fragment packets)**
    Divise les paquets TCP en petits morceaux, rendant l'analyse plus difficile pour certains pare-feu ou IDS/IPS.
    ```bash
    nmap -sS -f 192.168.1.1
    ```
  * **Spécification d'un MTU : `--mtu <taille>`**
    Définit la taille maximale de l'unité de transmission. Utile pour la fragmentation manuelle. Doit être un multiple de 8.
    ```bash
    nmap -sS --mtu 24 192.168.1.1
    ```
  * **Utilisation de proxys/chaînes de proxys : `--proxy <proxy_url>`**
    Permet de router le trafic Nmap à travers un proxy HTTP/SOCKS.
    ```bash
    nmap --proxy socks4://127.0.0.1:9050 target.com # Pour utiliser Tor SOCKS proxy
    ```
  * **Utilisation d'adresses MAC aléatoires : `--spoof-mac <mac_address | prefix | random>`**
    Modifie l'adresse MAC source des paquets. Peut être utile pour éviter d'être repéré sur un réseau local.
    ```bash
    nmap --spoof-mac 00:11:22:33:44:55 192.168.1.1
    nmap --spoof-mac 0 192.168.1.1 # Adresse MAC aléatoire
    ```
  * **Décoys : `-D <decoy1,decoy2,...>`**
    Envoie des paquets de scan en utilisant des adresses IP fictives (leurres) en plus de votre propre IP. Le pare-feu ou l'IDS/IPS verra des scans provenant de plusieurs sources, ce qui peut masquer votre véritable adresse.
    ```bash
    nmap -sS -D 192.168.1.254,ME,192.168.1.253 target.com
    # 'ME' est remplacé par votre propre IP.
    ```
  * **Spécification d'une source IP : `-S <source_ip>`**
    Spécifie l'adresse IP source que Nmap doit utiliser. Utile pour l'usurpation d'identité (spoofing), mais les réponses ne reviendront pas à votre machine si l'IP n'est pas routable vers vous.
    ```bash
    nmap -sS -S 10.0.0.1 target.com
    ```
  * **Pause entre les probes : `--scan-delay <temps>`**
    Déjà mentionné, mais crucial pour la furtivité.

-----

### **11. Scan Avancé et Options Utiles**

  * **Ping scan : `-sn` (anciennement `-sP`)**
    Ne fait que de la découverte d'hôtes (ping). Ne scanne pas les ports. Utile pour simplement lister les hôtes actifs sur un réseau.
    ```bash
    nmap -sn 192.168.1.0/24
    ```
  * **Ne pas pinguer : `-Pn` (anciennement `-P0`)**
    Nmap ne tentera pas de pinguer l'hôte avant de le scanner. Utile si l'hôte ne répond pas aux requêtes ICMP (ping bloqué par un pare-feu) mais est pourtant actif. Nmap supposera que l'hôte est en ligne.
    ```bash
    nmap -Pn -sS 192.168.1.1 # Scanne même si le ping est bloqué
    ```
  * **Détection de version sans scan de ports : `-sV --version-intensity 0`**
    Si vous savez que certains ports sont ouverts et souhaitez simplement la détection de version sans le scan de ports complet.
    ```bash
    nmap -p 80,443 -sV --version-intensity 0 192.168.1.1
    ```
  * **Récupération de bannières : `--script=banner`**
    Force Nmap à récupérer la bannière de chaque service ouvert, ce qui peut révéler des informations de version directes.
    ```bash
    nmap --script=banner 192.168.1.1
    ```
  * **Scans IPv6 : `-6`**
    Indique à Nmap d'utiliser IPv6.
    ```bash
    nmap -6 fe80::1
    ```
  * **Scans sur des plages non conventionnelles**
    Nmap supporte différentes notations pour les cibles :
      * CIDR : `192.168.1.0/24`
      * Plages : `192.168.1.1-10`
      * Listes : `192.168.1.1,5,10`
      * Wildcard : `192.168.1.*`

-----

### **12. Zenmap : L'interface Graphique de Nmap (Gemini) **

Zenmap est l'interface graphique officielle de Nmap. Elle est particulièrement utile pour les débutants ou pour visualiser facilement les résultats de scans complexes.

  * **Présentation de Zenmap :**
    Fournit une interface utilisateur conviviale pour toutes les options de Nmap, affiche les résultats sous forme graphique et textuelle, permet de sauvegarder les scans, de comparer les résultats et d'avoir des profils de scan prédéfinis.

  * **Fonctionnalités principales :**

      * **Barre de commande :** Permet de taper directement les commandes Nmap.
      * **Profils de scan :** Des commandes Nmap prédéfinies pour des scans courants (par ex., "Intense scan", "Quick scan").
      * **Affichage graphique des topologies :** Essaye de dessiner une carte du réseau.
      * **Onglets des résultats :** Affiche les ports/hôtes, topologie, détails de l'hôte, sortie Nmap brute.
      * **Comparaison de scans :** Utile pour voir les changements sur un réseau.

  * **Utilisation pour les débutants :**
    Zenmap simplifie l'apprentissage de Nmap en rendant les options plus accessibles et en fournissant une visualisation claire des résultats. C'est un excellent point de départ avant de se plonger dans la ligne de commande.

-----

### **13. Cas d'Utilisation et Scénarios Pratiques**

  * **Audit de sécurité :**

      * Identifier les services exposés sur Internet.
      * Vérifier les versions des logiciels pour les vulnérabilités connues.
      * Tester les règles de pare-feu.
      * Rechercher des configurations par défaut ou des services non sécurisés (ex: FTP anonyme).

  * **Inventaire réseau :**

      * Cartographier tous les appareils actifs sur un réseau.
      * Identifier les systèmes d'exploitation utilisés.
      * Détecter les services non autorisés ou "shadow IT".

  * **Dépannage réseau :**

      * Vérifier si un service écoute bien sur un port spécifique.
      * Déterminer si un pare-feu bloque le trafic.
      * Confirmer la connectivité entre deux points.

  * **Test de vulnérabilité :**

      * Combiner Nmap avec le NSE pour une détection automatisée des vulnérabilités.
      * Utiliser Nmap comme première étape d'une chaîne d'outils plus complexes (ex: avec Metasploit).

-----

### **14. Éthique et Législation (Gemini) **

  * **L'importance du consentement :**
    Répétons-le : **Obtenez toujours une autorisation écrite et explicite avant de scanner un réseau ou un système qui ne vous appartient pas.** Le non-respect de cette règle peut entraîner de lourdes sanctions pénales et civiles.

  * **Cadre légal (selon les pays) :**
    Les lois varient considérablement. Dans de nombreux pays, un scan de port non autorisé peut être considéré comme une tentative d'accès non autorisé, une infraction pénale passible de peines de prison et d'amendes.

  * **Utilisation responsable :**

      * Utilisez Nmap dans un cadre légal et éthique (votre propre lab, des plateformes légales, avec permission).
      * Comprenez l'impact de vos scans sur le réseau cible (un scan agressif peut provoquer un déni de service temporaire).
      * Tenez-vous informé des lois locales concernant la cybersécurité.
