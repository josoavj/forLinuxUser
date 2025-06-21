# nslookup : L'outil pour interroger le DNS

`nslookup` (name server lookup) est un utilitaire en ligne de commande utilisé pour interroger les serveurs DNS (Domain Name System) afin d'obtenir des informations sur les noms de domaine, les adresses IP et d'autres enregistrements DNS. C'est un outil fondamental pour le dépannage réseau et la vérification de la configuration DNS.

Bien que d'autres outils comme `dig` soient souvent préférés par les administrateurs système pour leur flexibilité et leurs informations plus détaillées, `nslookup` reste simple et largement disponible sur la plupart des systèmes d'exploitation (Windows, Linux, macOS).

---

# nslookup : Modes de Fonctionnement et Interprétation Basique

`nslookup` (name server lookup) est un outil en ligne de commande essentiel pour interroger le **DNS** (Domain Name System). Il permet de résoudre des noms de domaine en adresses IP et inversement. Il fonctionne principalement selon deux modes.

---

## 1. Mode Interactif

Ce mode est utile pour effectuer plusieurs requêtes successives ou pour modifier les paramètres de recherche (comme le type d'enregistrement) sans avoir à relancer l'outil à chaque fois.

### Lancement

Pour démarrer le mode interactif, ouvrez votre terminal ou invite de commande et tapez simplement :

```bash
  nslookup
```

Vous verrez alors une invite de commande `>` indiquant que vous êtes en mode interactif.

#### Utilisation de base

Une fois dans l'invite `>`, vous pouvez taper un nom de domaine ou une adresse IP pour effectuer une résolution. Pour changer le type de requête (par exemple, pour chercher des serveurs de messagerie), vous utilisez la commande `set type=`. Pour quitter, tapez `exit`.

#### Exemples de syntaxes en mode interactif :

- **Pour un nom de domaine :**
```
> [nom_de_domaine]
(Exemple : > google.com)
```
Pour une adresse IP :
```
> [adresse_IP]
(Exemple : > 142.250.186.78)
```
Pour changer le type de requête :
```
> set type=[type_enregistrement]
(Exemple : > set type=MX)
```
Pour interroger un serveur DNS spécifique :
```
> server [adresse_serveur_dns]
(Exemple: > server 8.8.8.8)
```

#### Les résultats possibles en mode interactif (Sur mes tests)

Après chaque commande, nslookup affiche des informations.
- **Lignes `Server:` et `Address:`** : Indiquent le serveur DNS que nslookup a utilisé pour votre requête (souvent votre résolveur DNS local ou celui de votre FAI).
- `Non-authoritative answer:` : Signifie que la réponse provient du cache du serveur DNS interrogé ou d'un autre serveur que celui qui fait autorité pour le domaine. C'est le résultat le plus courant.
- `Authoritative answer:` : Signifie que la réponse vient directement du serveur DNS officiel responsable du domaine demandé.
- `Name:` et `Addresses:` (ou Address:) : Affichent le nom de domaine demandé et l'adresse IP(s) correspondante(s) (IPv4 ou IPv6).
- **Messages d'erreur :** Si le domaine n'est pas trouvé, vous pourriez voir des messages comme `"Non-existent domain", "Can't find [nom_de_domaine]: Non-existent domain"`, ou des erreurs de timeout si le serveur DNS ne répond pas.

## Mode Non-Interactif (Ligne de Commande)

Ce mode est parfait pour des requêtes rapides et uniques, ou pour intégrer nslookup dans des scripts. La requête est effectuée directement sur la ligne de commande et l'outil se ferme après avoir affiché le résultat.

### Syntaxe générale

La syntaxe générale pour l'utilisation de nslookup est le suivant: 
```Bash
  nslookup [options] [nom_domaine_ou_ip] [serveur_dns_a_interroger]
```

- **[options] :** Permettent de spécifier le type de requête (-type=), le mode de débogage (-debug), etc.
- **[nom_domaine_ou_ip] :** Le nom de domaine (ex: example.com) ou l'adresse IP (ex: 192.0.2.1) à interroger.
- **[serveur_dns_a_interroger] :** (Optionnel) L'adresse IP d'un serveur DNS spécifique que vous souhaitez utiliser pour la requête, au lieu de celui configuré par défaut sur votre système.

Les options de `nslookup` vous permettent de contrôler le comportement de l'outil et de spécifier le type d'informations DNS que vous souhaitez récupérer.

### Options Fréquemment Utilisées

Voici une liste des options les plus courantes et leur explication :

| Option (Mode non-interactif) | Option (Mode interactif) | Description                                                                                                                                                                                                                                                                                                                        |
| :--------------------------- | :----------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-type=<type_enregistrement>` | `set type=<type_enregistrement>` | Spécifie le **type d'enregistrement DNS** à rechercher. C'est l'option la plus utilisée pour obtenir des informations spécifiques au-delà des simples adresses IP (A/AAAA). <br><br> **Types courants :** <br> - `A` : Adresse IPv4. <br> - `AAAA` : Adresse IPv6. <br> - `MX` : Enregistrements de serveurs de messagerie (Mail Exchange). <br> - `NS` : Enregistrements de serveurs de noms (Name Server). <br> - `TXT` : Enregistrements texte (souvent utilisés pour SPF, DKIM, vérification de domaine). <br> - `CNAME` : Nom canonique (alias). <br> - `PTR` : Pointeur (pour les recherches DNS inversées, IP vers nom). <br> - `SOA` : Start of Authority (informations sur la zone DNS). <br> - `SRV` : Service (pour des services spécifiques comme la VoIP). <br> - `ANY` : Retourne tous les types d'enregistrements disponibles (peut être très verbeux). |
| `[aucun]` / `[serveur_ip]` | `server [serveur_ip]`    | **Spécifie le serveur DNS à interroger.** Si aucune adresse IP n'est fournie, `nslookup` utilise le serveur DNS par défaut configuré sur votre système (généralement celui de votre FAI ou de votre réseau local). Si une adresse IP est donnée, `nslookup` interrogera ce serveur spécifique.                                                                                 |
| `-debug`                     | `set debug`              | **Active le mode de débogage.** Cela affiche des informations beaucoup plus détaillées sur le processus de requête DNS, y compris les paquets envoyés et reçus, les délais, et les réponses intermédiaires. Très utile pour diagnostiquer des problèmes complexes.                                                                                                                                    |
| `-timeout=<secondes>`        | `set timeout=<secondes>` | **Définit la durée maximale (en secondes) pendant laquelle `nslookup` attendra une réponse du serveur DNS** avant de considérer la requête comme échouée. Utile si vous avez des problèmes de latence ou des serveurs lents.                                                                                                                                     |
| `-retry=<nombre>`            | `set retry=<nombre>`     | **Spécifie le nombre de tentatives** que `nslookup` effectuera si le serveur DNS ne répond pas dans le délai imparti.                                                                                                                                                                                                                                        |
| `-vc`                        | `set vc`                 | **Force l'utilisation d'une connexion TCP (Virtual Circuit)** au lieu d'UDP pour la requête DNS. Par défaut, `nslookup` utilise UDP pour les requêtes standard, mais passe au TCP pour les réponses de grande taille. Forcer le TCP peut être utile pour le dépannage de problèmes de fragmentation UDP ou de grandes réponses DNS (ex: de nombreux enregistrements TXT). |
| `-port=<num_port>`           | `set port=<num_port>`    | **Spécifie un port UDP/TCP différent de 53** pour envoyer les requêtes DNS. Le port 53 est le port standard pour le DNS. Cette option est rarement utilisée, sauf dans des configurations réseau très spécifiques ou pour tester des services DNS sur des ports non-standards.                                                                                                      |
| `-nodefsearch`               | `set nodefsearch`        | **Désactive la recherche de nom de domaine par défaut.** Normalement, si vous entrez un nom de domaine sans point (ex: `serveur`), `nslookup` tentera d'ajouter votre suffixe DNS par défaut (ex: `serveur.mondomaine.local`). Cette option empêche ce comportement. Utile lorsque vous voulez interroger des noms exacts sans suffixe.                                 |
| `-norecurse`                 | `set norecurse`          | **Demande au serveur DNS de ne pas effectuer de résolution récursive.** Le serveur interrogé ne cherchera pas la réponse auprès d'autres serveurs s'il ne la possède pas directement. Il ne donnera qu'une réponse qu'il connaît déjà (en cache ou autoritaire) ou un renvoi vers un autre serveur (délégation). Utile pour tester des serveurs DNS spécifiques. |
| `-domain=<nom_domaine>`      | `set domain=<nom_domaine>` | **Définit le domaine par défaut** qui sera ajouté aux requêtes si le nom n'est pas un nom de domaine pleinement qualifié (FQDN). Similaire à la liste de recherche de domaine.                                                                                                                                                                             |

---

### Interprétation des résultats obtenus

```bash
  > nslookup website.com
  Server:		192.168.1.1 (Adresse IP de votre routeur)
  Address:	192.168.1.1#53 (53: Port d'accès du DNS où on a obtenu cela)

  Non-authoritative answer:
  Name:	website.com (Domaine)
  Address: 193.46.243.185 (Adresse IP du domaine)
```

#### 1. La Section "Serveur"

C'est la première partie de la sortie et elle identifie le serveur DNS que `nslookup` a utilisé pour effectuer la requête.
* **`Server:`** : C'est le nom d'hôte (si disponible) du serveur DNS qui a traité votre requête. Il s'agit souvent de votre routeur local, du serveur DNS de votre Fournisseur d'Accès Internet (FAI), ou d'un serveur DNS public (comme Google DNS 8.8.8.8 si vous l'avez configuré).
* **`Address:`** : C'est l'adresse IP de ce même serveur DNS, suivie du port UDP utilisé pour les requêtes DNS (le port 53 par défaut, d'où le `#53`).
- **NB :** Vous pouvez vérifier l'adresse de votre routeur avec `route` ou aussi `netstat -nr`.

#### 2. La Section "Réponse"

C'est la partie la plus importante, car elle contient les informations DNS que vous avez demandées.

##### Types de Réponses

En général, les réponses se présentent souvent en deux types (souvent indiqués par un message) :

* **`Non-authoritative answer:` (Réponse non-autoritaire) :**
    * **Signification :** Cela signifie que le serveur DNS qui vous a fourni la réponse n'est **pas** le serveur officiel (autoritaire) pour le domaine que vous avez interrogé. Le serveur a trouvé l'information dans son **cache** (une copie temporaire des réponses précédentes) ou l'a obtenue d'un autre serveur DNS qui, lui, était autoritaire.
    * **Qu'en penser ?** C'est la réponse la plus courante et souvent suffisante. Elle indique que l'information est valide, mais elle pourrait être légèrement obsolète si le cache n'a pas encore expiré et que l'enregistrement a été mis à jour récemment sur les serveurs autoritaires.

* **`Authoritative answer:` (Réponse autoritaire) :**
    * **Signification :** Cette réponse provient directement du serveur DNS qui est désigné comme l'autorité pour le domaine en question. Cela signifie que l'information est la plus à jour et la plus fiable disponible.
    * **Quand l'obtient-on ?** Vous l'obtenez généralement lorsque vous interrogez directement l'un des serveurs de noms (NS) autoritaires pour un domaine, ou si votre résolveur récursif a obtenu l'information directement de ce serveur autoritaire et n'avait pas d'information en cache.
