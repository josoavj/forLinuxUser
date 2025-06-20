# Le DNS (Domain Name System) 

Le **DNS** est bien plus qu'un simple annuaire téléphonique ; c'est une base de données distribuée et hiérarchisée, essentielle à l'infrastructure d'Internet. Sans lui, naviguer sur le web tel que nous le connaissons serait pratiquement impossible, car il faudrait se souvenir d'une suite de chiffres pour chaque site visité.

### Comment Fonctionne la Résolution DNS ?

La résolution DNS est un processus en plusieurs étapes qui se déroule très rapidement, généralement en quelques millisecondes :

1.  **La requête de l'utilisateur :** Lorsque vous tapez `www.exemple.com` dans votre navigateur, votre système d'exploitation vérifie d'abord son **cache DNS local**. C'est une petite base de données sur votre ordinateur qui stocke les résolutions DNS récentes. Si l'information est trouvée ici, le processus s'arrête et le navigateur se connecte directement.

2.  **Interrogation du résolveur DNS :** Si l'information n'est pas dans le cache local, votre ordinateur envoie une requête à un **serveur DNS récursif** (souvent fourni par votre FAI - Fournisseur d'Accès Internet, ou un service public comme Google DNS 8.8.8.8). Ce résolveur est le premier point de contact qui va chercher la réponse pour vous.

3.  **Contact avec les serveurs racine :** Le résolveur DNS ne connaît pas l'adresse IP de `www.exemple.com` directement. Il va d'abord interroger l'un des **serveurs racine**. Les serveurs racine ne savent pas non plus où se trouve `www.exemple.com`, mais ils savent où trouver les serveurs de noms pour les domaines de premier niveau (TLD), comme `.com`, `.org`, `.fr`, etc. Ils répondent en indiquant au résolveur l'adresse du serveur TLD pour `.com`.

4.  **Contact avec les serveurs TLD :** Le résolveur DNS interroge ensuite le **serveur TLD** pour `.com`. Le serveur TLD ne connaît pas non plus l'adresse IP exacte de `www.exemple.com`, mais il sait quels **serveurs de noms autoritaires** sont responsables du domaine `exemple.com`. Il répond en fournissant l'adresse de ces serveurs autoritaires.

5.  **Contact avec les serveurs autoritaires :** Enfin, le résolveur DNS contacte le **serveur de noms autoritaire** pour `exemple.com`. C'est ce serveur qui détient les enregistrements DNS spécifiques pour `exemple.com`, y compris l'adresse IP de `www.exemple.com`. Le serveur autoritaire renvoie l'adresse IP au résolveur.

6.  **Réponse au client :** Le résolveur DNS renvoie l'adresse IP de `www.exemple.com` à votre ordinateur. Il met également cette information en **cache** pour une durée déterminée (TTL - Time To Live) afin d'accélérer les futures requêtes pour le même domaine.

7.  **Connexion directe :** Votre navigateur reçoit l'adresse IP et peut désormais établir une connexion directe avec le serveur web hébergeant `www.exemple.com`.

### Types d'Enregistrements DNS

Le DNS ne stocke pas seulement les adresses IP. Il gère différents types d'enregistrements, chacun ayant un rôle spécifique :

* **A (Address) :** Le type d'enregistrement le plus courant. Il mappe un nom de domaine à une adresse IPv4 (par exemple, `www.exemple.com` vers `93.184.216.34`).
* **AAAA (Quad-A) :** Similaire à l'enregistrement A, mais il mappe un nom de domaine à une adresse IPv6.
* **CNAME (Canonical Name) :** Crée un alias d'un nom de domaine à un autre nom de domaine. Par exemple, `blog.exemple.com` pourrait être un CNAME pour `exemple.blogspot.com`.
* **MX (Mail Exchange) :** Indique quel serveur de messagerie est responsable de la réception des e-mails pour un domaine (par exemple, où envoyer les e-mails destinés à `utilisateur@exemple.com`).
* **NS (Name Server) :** Spécifie les serveurs de noms autoritaires pour un domaine ou un sous-domaine. C'est ainsi que la hiérarchie DNS est construite.
* **PTR (Pointer) :** Utilisé pour la résolution DNS inversée, mappant une adresse IP à un nom de domaine. Utile pour la vérification de la réputation des serveurs de messagerie.
* **TXT (Text) :** Permet d'ajouter du texte arbitraire associé à un nom de domaine. Souvent utilisé pour des vérifications de propriété de domaine, les enregistrements SPF (Sender Policy Framework) pour la prévention du spam, ou les enregistrements DKIM (DomainKeys Identified Mail) pour l'authentification des e-mails.
* **SRV (Service) :** Spécifie l'emplacement (nom d'hôte et numéro de port) de serveurs pour des services spécifiques, comme la téléphonie VoIP ou la messagerie instantanée.