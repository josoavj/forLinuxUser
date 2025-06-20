# nslookup : L'outil pour interroger le DNS

`nslookup` (name server lookup) est un utilitaire en ligne de commande utilisé pour interroger les serveurs DNS (Domain Name System) afin d'obtenir des informations sur les noms de domaine, les adresses IP et d'autres enregistrements DNS. C'est un outil fondamental pour le dépannage réseau et la vérification de la configuration DNS.

Bien que d'autres outils comme `dig` soient souvent préférés par les administrateurs système pour leur flexibilité et leurs informations plus détaillées, `nslookup` reste simple et largement disponible sur la plupart des systèmes d'exploitation (Windows, Linux, macOS).

---

# Pour voir des informations sur un domaine

nslookup website.com
Server:		192.168.1.1 (Adresse IP de votre routeur)
Address:	192.168.1.1#53 (53: Port d'accès du DNS où on a obtenu cela)

Non-authoritative answer:
Name:	website.com (Domaine)
Address: 193.46.243.185 (Adresse IP du domaine)

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

```Bash
    nslookup [options] [nom_domaine_ou_ip] [serveur_dns_a_interroger]
```
- **[options] :** Permettent de spécifier le type de requête (-type=), le mode de débogage (-debug), etc.
- **[nom_domaine_ou_ip] :** Le nom de domaine (ex: example.com) ou l'adresse IP (ex: 192.0.2.1) à interroger.
- **[serveur_dns_a_interroger] :** (Optionnel) L'adresse IP d'un serveur DNS spécifique que vous souhaitez utiliser pour la requête, au lieu de celui configuré par défaut sur votre système.