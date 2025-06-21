# Armitage : L'Interface Graphique pour Metasploit

**Armitage** est une interface graphique (GUI) gratuite et open-source pour le framework **Metasploit**, l'un des outils d'exploitation de vulnérabilités les plus puissants et les plus utilisés dans le monde de la cybersécurité. Développé en Java, Armitage vise à rendre l'utilisation de Metasploit plus accessible, notamment pour les utilisateurs moins familiarisés avec la ligne de commande ou ceux qui préfèrent une approche visuelle de leurs opérations de test d'intrusion.

Il transforme la puissance brute de Metasploit en une expérience plus intuitive, en visualisant les cibles, les exploitations et les sessions actives sur une interface de type "carte réseau".

-----

## Mode de fonctionnement

Armitage agit comme un "chef d'orchestre" graphique pour le framework Metasploit. Il se connecte au service `msfconsole` (l'interface en ligne de commande de Metasploit) et fournit une représentation visuelle des opérations.

Voici les grandes lignes de son fonctionnement :

1.  **Connexion à Metasploit :** Armitage démarre en se connectant à une instance de la base de données PostgreSQL de Metasploit et au service `msfrpcd` (le daemon RPC de Metasploit).
2.  **Découverte d'hôtes :** Il peut scanner un réseau pour découvrir les hôtes actifs, les ports ouverts et identifier les systèmes d'exploitation.
3.  **Analyse de Vulnérabilités :** Bien qu'il n'intègre pas un scanner de vulnérabilités complet, il peut importer les résultats de scanners tiers (comme Nmap) et les utiliser pour suggérer des exploits.
4.  **Visualisation :** Il affiche les hôtes découverts sous forme d'icônes, et lorsqu'une vulnérabilité est identifiée, il peut représenter les vecteurs d'attaque possibles.
5.  **Automatisation de l'Exploitation :** Il simplifie le processus de sélection et de configuration des exploits Metasploit, permettant aux utilisateurs de lancer des attaques par glisser-déposer ou via des menus contextuels.
6.  **Gestion des Sessions :** Une fois qu'une exploitation réussit, Armitage fournit une interface claire pour gérer les sessions (par exemple, des shells Metasploit ou des sessions Meterpreter), permettant l'exécution de commandes post-exploitation.
7.  **Pivoting :** Il facilite le concept de "pivoting", où une machine compromise est utilisée comme point de départ pour attaquer d'autres machines sur des réseaux internes inaccessibles depuis l'extérieur.

-----

## Utilisation

Armitage met à portée de main un ensemble de capacités offensives, rendant certaines tâches complexes de Metasploit accessibles :

  * **Scan de Réseau :** Découvre les hôtes, les ports ouverts et les services en utilisant des modules de Metasploit (basés sur Nmap).
  * **Recherche et Sélection d'Exploits :** Permet de rechercher des exploits par type, plateforme ou mot-clé. Il peut également suggérer des exploits basés sur les systèmes d'exploitation et services détectés sur les hôtes cibles.
  * **Lancement d'Exploits :** Facilite le lancement d'exploits contre des cibles spécifiques avec une configuration minimale.
  * **Attaques de Force Brute :** Intègre des modules pour des attaques par force brute contre des services courants.
  * **Gestion des Payloads :** Aide à choisir et configurer les payloads (les charges utiles qui s'exécutent sur la cible après une exploitation réussie), y compris Meterpreter, un payload avancé avec de nombreuses fonctionnalités post-exploitation.
  * **Post-Exploitation :** Une fois qu'une session Meterpreter est établie, Armitage offre des options graphiques pour :
      * Naviguer dans le système de fichiers de la cible.
      * Télécharger/téléverser des fichiers.
      * Capturer des captures d'écran.
      * Élever des privilèges.
      * Effectuer de la persistance.
      * Pivoter vers d'autres machines.
  * **Génération de Rapports :** Permet de générer des rapports de base sur les machines compromises et les exploits réussis.
  * **Collaboration (Team Server) :** Une fonctionnalité unique d'Armitage est son "Team Server", qui permet à plusieurs attaquants de travailler simultanément sur la même opération de test d'intrusion en partageant la base de données et les sessions.

-----

## Place de Armitage dans les Étapes de Hacking (Cyber Kill Chain / Phases de Pentesting)

Armitage est principalement utilisé dans les phases d'**exploitation** et de **post-exploitation**, bien qu'il ait aussi des capacités en matière de scan.

| Phase de Hacking | Rôle de `Armitage`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| :---------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Reconnaissance (Information Gathering)** | Armitage a des capacités limitées en reconnaissance passive par rapport à des outils comme `theHarvester` ou `WHOIS`. Cependant, il peut importer les résultats de scanners externes comme Nmap, qui sont eux-mêmes le fruit de la reconnaissance active.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| **2. Scanne (Scanning)** | Armitage peut lancer des scans Nmap directement depuis son interface pour découvrir les hôtes actifs, les ports ouverts et les versions des services. Ces informations sont cruciales pour identifier les vulnérabilités exploitables.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| **3. Accès Initial (Exploitation)** | C'est la phase où Armitage brille. Une fois les vulnérabilités identifiées par le scan, Armitage propose des exploits correspondants à partir de la base de données de Metasploit. Son interface simplifie grandement la configuration et le lancement de ces exploits pour obtenir un accès initial au système cible (par exemple, un shell ou une session Meterpreter). |
| **4. Maintien de l'Accès / Élévation de Privilèges / Mouvement Latéral / Exfiltration / Couverture des Traces (Post-Exploitation)** | Une fois la session initiale obtenue, Armitage devient un tableau de bord graphique pour les actions de post-exploitation. Il visualise la session compromise et offre des menus contextuels pour : \<br\> - **Élever les privilèges :** Tenter de passer de droits utilisateurs limités à des droits administrateur/root. \<br\> - **Mouvement latéral :** Utiliser la machine compromise comme pivot pour accéder et attaquer d'autres machines sur le réseau interne. \<br\> - **Collecte d'informations :** Explorer le système de fichiers, extraire des mots de passe, etc. \<br\> - **Persistance :** Installer des backdoors pour maintenir l'accès. \<br\> - **Nettoyage :** Effacer les traces (bien que cela soit généralement fait manuellement ou via des scripts).                                                                                                                                                                                                                                                                               |
