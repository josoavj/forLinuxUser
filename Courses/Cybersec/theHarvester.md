# theHarvester : Outil de reconnaissance OSINT

**`theHarvester`** est un outil en ligne de commande open-source et très populaire, conçu pour la phase de **reconnaissance passive** lors d'un test d'intrusion ou d'une évaluation de sécurité. 
Il est spécialisé dans la collecte d'informations publiques (Open Source Intelligence - **OSINT**) sur une organisation ou un domaine cible, en cherchant à identifier la "surface d'attaque" externe.

**Remarque :** il a été développé en Python

-----

## Son fonctionnement

`theHarvester` n'est pas un outil d'exploitation de vulnérabilités. Il n'attaque pas la cible directement. Au lieu de cela, il agit comme un **agrégateur d'informations**, collectant des données à partir de diverses sources publiques sur Internet. Il automatise ce qui serait autrement une tâche manuelle longue et fastidieuse de recherche d'informations.

Il interroge des moteurs de recherche, des bases de données publiques, des serveurs de clés PGP, des plateformes de médias sociaux (comme LinkedIn dans certaines versions), et d'autres sources passives pour glaner des détails sur le domaine ou l'organisation cible.

-----

## Les informations collectées via theHarvester

`theHarvester` est capable de collecter une variété d'informations précieuses, notamment :

  * **Sous-domaines :** Des adresses web liées au domaine principal (ex: `dev.example.com`, `mail.example.com`). La découverte de sous-domaines est cruciale car ils peuvent héberger des applications moins sécurisées ou exposer plus de services.
  * **Adresses e-mail :** Des adresses e-mail d'employés ou de l'organisation (ex: `john.doe@example.com`). Ces adresses sont souvent utilisées pour des attaques d'ingénierie sociale (phishing, spear-phishing).
  * **Noms d'employés :** Des noms d'utilisateurs ou d'employés associés au domaine.
  * **Adresses IP :** Les adresses IP associées aux domaines et sous-domaines découverts. Cela permet de cartographier l'infrastructure réseau de la cible.
  * **Hôtes virtuels (Virtual Hosts) :** Des noms de domaines qui partagent la même adresse IP avec d'autres domaines sur un même serveur web.
  * **Bannières / Informations sur les ports ouverts :** Dans certains cas, il peut identifier des services exposés et leurs versions via des recherches sur des moteurs comme Shodan.
  * **URLs :** Des URL pertinentes trouvées dans les résultats de recherche.

-----

## theHarvester dans les Étapes de Hacking (Cyber Kill Chain / Phases de Pentesting)

`theHarvester` se positionne dans la première phase de la "Cyber Kill Chain" ou des méthodologies de pentesting : la **Reconnaissance** (également appelée **Information Gathering** ou **Footprinting**).

| Phase de Hacking | Rôle de `theHarvester`                                                                                                                                                                                                                                                                                                                                                                                                                        |
| :---------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1. Reconnaissance (Information Gathering)** | C'est ici que `theHarvester` excelle. Il est utilisé pour la **reconnaissance passive**, c'est-à-dire la collecte d'informations sans interaction directe avec la cible (donc sans laisser de traces sur ses systèmes). \<br\>\<br\> Les données recueillies (sous-domaines, e-mails, noms d'employés, IPs) sont fondamentales pour construire un profil détaillé de l'organisation cible. Elles aident à : \<br\> - **Cartographier la surface d'attaque** visible publiquement. \<br\> - **Identifier des cibles potentielles** (employés pour le phishing, sous-domaines pour des vulnérabilités web). \<br\> - **Comprendre l'infrastructure** (plages d'IP, technologies utilisées). |
| 2. Scanne (Scanning) | Les informations obtenues via `theHarvester` (notamment les sous-domaines et les adresses IP) sont ensuite utilisées comme **input** pour la phase de scan. Par exemple, les adresses IP découvertes seront scannées avec des outils comme `Nmap` pour identifier les ports ouverts et les services exécutés.                                                                                                                                                              |
| 3. Énumération | Les e-mails ou noms d'utilisateurs collectés peuvent être utilisés pour tenter d'énumérer des comptes utilisateurs valides sur des systèmes (ex: via des formulaires de connexion ou des serveurs SMTP).                                                                                                                                                                                                                                        |
| 4. Accès Initial (Initial Access) | Les adresses e-mail sont des cibles primaires pour les campagnes de **phishing** ou de **spear-phishing**, qui visent à obtenir un accès initial via l'ingénierie sociale. La connaissance des sous-domaines et des technologies peut aussi révéler des vulnérabilités web spécifiques pour cet accès.                                                                                                                                             |
| 5. Maintien de l'Accès / Élévation de Privilèges / Mouvement Latéral / Exfiltration / Couverture des Traces | `theHarvester` n'est pas directement utilisé dans ces phases. Cependant, les informations qu'il a permis de découvrir peuvent indirectement influencer ces étapes, par exemple en fournissant des noms d'utilisateurs qui pourraient être ciblés pour des attaques par force brute ou en donnant une meilleure compréhension de l'architecture pour un mouvement latéral. |

-----

## Utilisation de Base et Options Clés

`theHarvester` est un outil en ligne de commande et est généralement simple à utiliser.

**Syntaxe de base :**

```bash
theharvester -d <domaine_cible> -b <source_de_données> [options]
```

  * `-d <domaine_cible>` : Spécifie le domaine ou l'organisation à rechercher (obligatoire).
  * `-b <source_de_données>` : Définit la source à utiliser pour la recherche. C'est une option très importante.

**Exemples de sources (`-b`) :**

  * `google` : Utilise le moteur de recherche Google.
  * `bing` : Utilise le moteur de recherche Bing.
  * `linkedin` : Recherche des profils LinkedIn liés au domaine (peut nécessiter une API Key et être moins efficace en raison des restrictions).
  * `shodan` : Recherche des informations sur les ports ouverts et les bannières via Shodan (nécessite une clé API Shodan configurée).
  * `crtsh` : Utilise le service crt.sh pour trouver des sous-domaines via les certificats SSL/TLS.
  * `dnsdumpster` : Utilise le service DNSDumpster pour la reconnaissance DNS.
  * `all` : Utilise toutes les sources disponibles (peut prendre du temps et être verbeux).

**Autres options importantes :**

  * `-l <nombre>` : Limite le nombre de résultats à récupérer pour chaque source.
  * `-f <fichier.html/xml/json>` : Enregistre les résultats dans un fichier (HTML, XML ou JSON).
  * `--active` : Active les modules de reconnaissance active (comme la résolution DNS inverse ou le brute force DNS) qui peuvent laisser des traces. À utiliser avec prudence.
  * `--api-keys` : Permet de spécifier des fichiers de clés API pour des sources comme Shodan, Hunter.io, etc., pour des résultats plus complets.

**Exemple d'utilisation :**

```bash
theharvester -d example.com -b google,linkedin,crtsh -l 500 -f example_recon.html
```

Cette commande recherchera des informations sur `example.com` en utilisant Google, LinkedIn et crt.sh, limitera les résultats à 500 par source, et sauvegardera le tout dans un fichier HTML nommé `example_recon.html`.


