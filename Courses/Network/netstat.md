# NETSTAT

J'explore de nouveaux outils pour la surveillance des connexions réseaux et je suis tombé sur netstat.
Parlons un peu de cet utilitaire en ligne de commande, pratique pour explorer et surveiller les connexions réseaux sur un système Linux.

## Quelques notions

- **netstat** est une abréviation du **network statistics**
- À ma compréhension, netstat permet de surveiller les ports réseaux: il montre les ports ouverts, les paquets entrants et sortants dans votre machine et aussi la destination des données transitant par les ports.
- Il affiche des informations sur les **connexions réseau**, **les tables de routage**, **les statistiques d'interface** (Ethernet, Wi-Fi, etc.), les **connexions de protocole réseau** (TCP, UDP, ICMP, etc.) et les **sockets réseau**.

## Utilisation

- Pour le tester, tu tapes `netstat` sur ton terminal. Ensuite le système d'exploitation va collecter les informations sur l'état actuel du réseau et les afficher sous forme de tableau. Ces informations sont stockées dans des zones spéciales de la mémoire du noyau de Linux.
- Les principales utilités de netstat [Source: Google] :
  1. **Surveillance des connexions réseau actives :** C'est l'utilisation la plus courante. Tu peux voir toutes les connexions TCP/IP établies entre ton ordinateur et d'autres machines (serveurs web, autres ordinateurs, etc.). Cela peut t'aider à identifier si des connexions suspectes sont en cours.
  2. **Identification des ports ouverts :** netstat te montre les ports sur lesquels ton ordinateur écoute activement les connexions entrantes. C'est crucial pour comprendre quels services réseau (comme un serveur web ou SSH) sont en cours d'exécution.
  3. **Affichage des statistiques d'interface :** Tu peux obtenir des informations sur le trafic réseau de tes différentes interfaces (par exemple, le nombre de paquets envoyés et reçus via ton Wi-Fi ou ton câble Ethernet). C'est utile pour diagnostiquer des problèmes de réseau.
  4. **Consultation de la table de routage :** netstat peut afficher la table de routage de ton système, qui indique par quel chemin les paquets de données sont envoyés vers différentes destinations.
  5. **Détection des processus associés aux connexions :** En combinant netstat avec d'autres outils (comme grep), tu peux identifier quel programme est responsable d'une connexion réseau spécifique.

## Quelques commandes de bases pour netstat

- `netstat (ou netstat -a)` : Affiche toutes les connexions réseau actives et les ports d'écoute. La sortie peut être longue, alors sois patient !
- `netstat -t` : Affiche uniquement les connexions TCP.
- `netstat -u` : Affiche uniquement les connexions UDP.
- `netstat -l` : Affiche uniquement les ports d'écoute. C'est très utile pour voir quels services sont en attente de connexions entrantes.
- `netstat -p` : Affiche le PID (Process ID) et le nom du programme associé à chaque connexion. Tu auras peut-être besoin d'utiliser sudo devant la commande pour voir ces informations pour tous les processus. 
   - Exemple : `sudo netstat -ap`. 
- `netstat -n` : Affiche les adresses et les ports sous forme numérique, au lieu d'essayer de les résoudre en noms d'hôtes. C'est plus rapide et peut être utile pour éviter des problèmes de résolution DNS.
- `netstat -r` : Affiche la table de routage du noyau. Ceci possède le même fonctionnement de base que la commande `route`
- `netstat -i`: Affiche les statistiques d'interface réseau.

## Notice: pour les curieux 

- Tu peux consulter le manuel de netstat via la commande `man netstat`
- Tu peux aussi le combiner avec d'autres outils comme grep pour filtrer la sortie de netstat. 
  - Par exemple, `netstat -an | grep ESTABLISHED` affichera uniquement les connexions TCP établies.
- Utilise la commande `watch netstat` pour voir les informations se mettre à jour en temps réel. C'est utile pour observer l'établissement et la fermeture de connexions.