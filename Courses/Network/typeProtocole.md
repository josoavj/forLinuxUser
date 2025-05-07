# Types de protocole

- En réseau, un protocole est un ensemble normalisé de règles régissant le formatage et le traitement de données permettant aux ordinateurs de communiquer entre eux.

## Les types de protocoles existant

| Abréviation | Nom Complet                               | Description                                                                                                |
| ----------- | ------------------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ARP         | Address Resolution Protocol              | Protocole utilisé pour résoudre les adresses IP en adresses MAC sur un réseau local.                         |
| BGP         | Border Gateway Protocol            | Protocole de routage inter-domaines utilisé sur Internet.                   |
| DHCP        | Dynamic Host Configuration Protocol | Protocole pour l'attribution automatique d'adresses IP et d'autres configurations réseau. |
| DNS         | Domain Name System                         | Système hiérarchique et distribué pour traduire les noms de domaine en adresses IP.                           |
| Ethernet    | Ethernet                             | Standard pour les réseaux locaux (LAN) filaires.                             |
| FTP         | File Transfer Protocol             | Protocole standard pour le transfert de fichiers entre un client et un serveur. |
| HTTP        | Hypertext Transfer Protocol              | Protocole de base du World Wide Web pour transférer des pages web et d'autres contenus.                      |
| HTTPS       | HTTP Secure                                | Version sécurisée de HTTP qui utilise le chiffrement TLS/SSL pour sécuriser les communications web.           |
| ICMP        | Internet Control Message Protocol    | Protocole utilisé pour envoyer des messages d'erreur et de contrôle IP.    |
| IMAP        | Internet Message Access Protocol           | Protocole utilisé par les clients de messagerie pour accéder aux e-mails stockés sur un serveur de messagerie. |
| IPSec       | Internet Protocol Security               | Suite de protocoles pour sécuriser les communications IP en authentifiant et en chiffrant chaque paquet IP.     |
| L2TP        | Layer Two Tunneling Protocol             | Protocole de tunneling utilisé pour prendre en charge les réseaux privés virtuels (VPN).                      |
| NTP         | Network Time Protocol                    | Protocole utilisé pour synchroniser l'horloge des systèmes informatiques sur un réseau.                     |
| OSPF        | Open Shortest Path First                 | Protocole de routage interne (Interior Gateway Protocol) utilisé dans les réseaux IP.                         |
| POP         | Post Office Protocol               | Protocole pour la récupération d'e-mails depuis un serveur.                  |
| PPPoE       | Point-to-Point Protocol over Ethernet    | Protocole réseau pour encapsuler les trames PPP dans des trames Ethernet, couramment utilisé pour les connexions DSL. |
| QUIC        | Quick UDP Internet Connections           | Protocole de transport de nouvelle génération qui vise à améliorer la performance et la sécurité des connexions web. |
| RDP         | Remote Desktop Protocol            | Protocole pour l'accès à distance au bureau d'un ordinateur Windows.        |
| RIP         | Routing Information Protocol             | Ancien protocole de routage à vecteur de distance.                                                          |
| Samba       | Protocole Samba                      | Protocole de partage de fichiers et d'imprimantes utilisé principalement avec Windows. |
| SFTP        | SSH File Transfer Protocol         | Protocole pour le transfert de fichiers sécurisé via SSH.                  |
| SMTP        | Simple Mail Transfer Protocol        | Protocole standard pour l'envoi d'e-mails.                                |
| SNMP        | Simple Network Management Protocol   | Protocole pour la gestion et la surveillance des périphériques réseau.     |
| SNMPv3      | Simple Network Management Protocol version 3 | Version sécurisée du protocole SNMP qui ajoute des fonctionnalités d'authentification et de chiffrement.     |
| SSH         | Secure Shell                               | Protocole réseau qui permet d'établir une connexion sécurisée en ligne de commande avec un serveur distant.    |
| SSL         | Secure Sockets Layer                       | Protocole cryptographique qui assure la sécurité des communications sur Internet (souvent remplacé par TLS). |
| TACACS+     | Terminal Access Controller Access-Control System Plus | Protocole d'authentification, d'autorisation et de comptabilité centralisé, souvent utilisé dans les réseaux Cisco. |
| TCP         | Transmission Control Protocol      | Protocole de transport fiable et orienté connexion.                         |
| Telnet      | Telnet                               | Protocole pour établir une session de terminal à distance.                   |
| TLS         | Transport Layer Security           | Protocole de chiffrement pour sécuriser les communications sur un réseau.   |
| UDP         | User Datagram Protocol             | Protocole de transport non fiable et sans connexion.                         |

## Les ports

- C'est le bout d'un protocole pour avoir accès à un réseau. 
- **Précis:** ce sont les points de communications virtuels qui permettent aux ordinateurs de distinguer les différents types de trafic réseau.
- Voici une liste des ports utilisés fréquemment:

|    Port     |  Protocole (TCP/UDP)  | Service / Description             |
|:-----------:|:---------------------:| --------------------------------- |
|     80      |          TCP          | HTTP (Hypertext Transfer Protocol) |
|     443     |          TCP          | HTTPS (HTTP Secure)               |
|     22      |          TCP          | SSH (Secure Shell)                |
|     21      |          TCP          | FTP - Commande                    |
|     20      |          TCP          | FTP - Données                     |
|     25      |          TCP          | SMTP (Simple Mail Transfer Protocol) |
|     110     |          TCP          | POP3 (Post Office Protocol v3)    |
|     143     |          TCP          | IMAP (Internet Message Access Protocol) |
|     53      |       UDP & TCP       | DNS (Domain Name System)          |
|    3389     |          TCP          | RDP (Remote Desktop Protocol)     |

- Services correspondants à chaque port mentionnés dans le tableau :
  - **Navigation web sécurisée :** HTTPS (Port 443)
  - **Navigation web non sécurisée :** HTTP (Port 80)
  - **Administration de serveurs à distance, transfert de fichiers sécurisé, tunnels sécurisés :** SSH (Port 22)
  - **Transfert de fichiers :** FTP (Ports 20 et 21)
  - **Envoi d'e-mails :** SMTP (Port 25)
  - **Réception d'e-mails :** POP3 (Port 110), IMAP (Port 143)
  - **Résolution de noms de domaine :** DNS (Port 53)
  - **Bureau à distance Windows :** RDP (Port 3389)

## Passerelle (Gateway)

- Nom génerique d'un dispositif permettant de relier deux réseaux informatiques de type différent

### Types de passerelle (Global)

| Type de Passerelle        | Fonction Principale                                                                 | Exemples Courants                                                                 |
| ------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Passerelle Réseau** | Connecte des réseaux différents (protocoles potentiellement différents).              | Routeur connectant un LAN à Internet.                                               |
| **Passerelle Protocole** | Convertit les protocoles de communication entre des réseaux différents.              | Passerelle TCP/IP vers SNA.                                                         |
| **Passerelle Application**| Fonctionne au niveau applicatif, effectue des traductions et de la sécurité spécifique. | Pare-feu applicatif (WAF), proxy.                                                   |
| **Passerelle Messagerie** | Sécurise et gère le trafic de courrier électronique (spam, malware, politiques).   | Serveur de messagerie avec fonctions de filtrage et de sécurité.                    |
| **Passerelle VoIP** | Connecte les réseaux téléphoniques traditionnels (PSTN) aux réseaux VoIP.             | Boîtier ATA (Analog Telephone Adapter), équipements VoIP d'entreprise.               |
| **Passerelle IoT** | Traduit les protocoles IoT vers IP pour connecter les appareils IoT au cloud.       | Hubs IoT, concentrateurs de données IoT.                                            |
| **Passerelle Cloud Storage**| Facilite le transfert de données entre réseaux locaux et stockage cloud.            | Logiciels de synchronisation cloud avec accès réseau local.                         |
| **Passerelle Base de Données**| Permet la communication entre différentes bases de données (SGBD différents).        | Logiciels d'intégration de données, pilotes ODBC/JDBC avec fonctionnalités de passerelle. |
| **Passerelle Sécurité** | Terme générique pour les passerelles axées sur la sécurité du réseau.             | Pare-feu, passerelle VPN, passerelle de contenu web.                               |
| **Passerelle Cellulaire** | Connecte des réseaux locaux aux réseaux de données cellulaires (4G/5G).              | Routeurs cellulaires, modems cellulaires.                                          |
| **Passerelle Unidirectionnelle** | Permet le flux de données dans une seule direction (sécurité, archivage).         | Systèmes de transfert de données sécurisés pour environnements critiques.            |
| **Passerelle Bidirectionnelle** | Permet le flux de données dans les deux directions (communication interactive). | La majorité des passerelles réseau et d'application.                               |

## Passerelle réseau

| Dispositif Réseau  |  Niveau OSI  | Terme du Niveau OSI  | Passerelle de Niveau  |
|:-------------------|:------------:|:---------------------|:----------------------|
| Répéteur           |      1       | Physique             | Niveau 1              |
| Pont               |      2       | Liaison de données   | Niveau 2              |
| Routeur/Relais     |      3       | Réseau               | Niveau 3              |