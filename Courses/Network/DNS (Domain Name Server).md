# Les Serveurs DNS (DNSServers)

Les **Serveurs DNS** sont les piliers sur lesquels repose le système DNS. Ils travaillent pour s'assurer que chaque requête de nom de domaine trouve sa bonne adresse IP.

### Les Différents Rôles des Serveurs DNS

La collaboration entre les différents types de serveurs est ce qui rend le DNS si robuste et évolutif :

1.  **Serveur DNS Récursif (ou Résolveur DNS) :**
    * **Rôle :** C'est la porte d'entrée du DNS pour l'utilisateur. Il ne contient pas d'enregistrements de zone, mais son travail est de "résoudre" la requête en interrogeant d'autres serveurs DNS de manière récursive.
    * **Fonctionnement :** Il gère la complexité de la recherche pour le client. Il commence par interroger un serveur racine, puis un serveur TLD, puis un serveur autoritaire, jusqu'à obtenir la réponse. Il met aussi en cache les réponses pour accélérer les requêtes futures.
    * **Exemples :** Les serveurs DNS de votre FAI, Google Public DNS (8.8.8.8, 8.8.4.4), Cloudflare DNS (1.1.1.1).

2.  **Serveurs de Noms Racine (Root Name Servers) :**
    * **Rôle :** Au sommet de la hiérarchie DNS, ils connaissent l'adresse de tous les serveurs TLD. Ils sont cruciaux pour démarrer le processus de résolution.
    * **Fonctionnement :** Il existe 13 adresses IP de serveurs racine (gérées par 12 organisations différentes, mais avec de nombreuses instances physiques réparties mondialement via Anycast pour la redondance et la performance). Ils ne répondent qu'avec l'adresse des serveurs TLD pertinents.
    * **Exemple :** Le serveur "A.ROOT-SERVERS.NET", "B.ROOT-SERVERS.NET", etc.

3.  **Serveurs de Noms de Domaine de Premier Niveau (TLD Name Servers) :**
    * **Rôle :** Ils gèrent les informations pour les domaines de premier niveau (.com, .org, .net, .fr, .io, etc.).
    * **Fonctionnement :** Lorsqu'un résolveur leur pose une question sur un domaine spécifique (par exemple, `exemple.com`), ils répondent en indiquant quel serveur de noms autoritaire est responsable de `exemple.com`.
    * **Exemples :** Les serveurs qui gèrent `.com` (Verisign), `.org` (PIR), `.fr` (AFNIC), etc.

4.  **Serveurs de Noms Autoritaires (Authoritative Name Servers) :**
    * **Rôle :** Ce sont les serveurs qui détiennent les enregistrements DNS officiels et finaux pour un domaine donné. C'est ici que sont configurés les enregistrements A, CNAME, MX, etc., pour votre site web ou votre service.
    * **Fonctionnement :** Ils répondent directement avec l'adresse IP ou l'enregistrement demandé pour le domaine dont ils sont autoritaires. Sans ces serveurs, votre domaine ne serait pas trouvable sur Internet.
    * **Exemple :** Les serveurs de noms fournis par votre hébergeur web (ex: `ns1.votrehebergeur.com`, `ns2.votrehebergeur.com`).

### Importance de la Redondance et du Cache DNS

* **Redondance :** Le DNS est conçu pour être extrêmement résilient. Chaque niveau de serveurs DNS a de multiples instances géographiquement dispersées (souvent via la technologie Anycast) pour assurer que même si un serveur tombe en panne, le service continue sans interruption.
* **Cache DNS :** Le caching est vital pour la performance du DNS. Chaque résolveur DNS et même votre propre ordinateur garde en mémoire les réponses aux requêtes récentes. Cela réduit considérablement le nombre de requêtes qui doivent parcourir toute la chaîne hiérarchique, rendant la navigation beaucoup plus rapide. Le **TTL** (Time To Live) associé à chaque enregistrement DNS détermine la durée pendant laquelle cette information peut être mise en cache avant qu'une nouvelle requête ne soit nécessaire.
