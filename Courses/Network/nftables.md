# nftables

### **Table des Matières**

1.  **Pourquoi nftables ? Limitations d'iptables**
2.  **Architecture et Concepts Clés de nftables**
      * Familles d'adresses
      * Tables
      * Chaînes (Hooks, Types, Priorités)
      * Sets (Ensembles)
      * Maps (Cartes)
      * Concatenations
      * Cibles (Statements/Actions)
      * Expressions
3.  **Syntaxe Générale de `nft`**
      * Créer/détruire tables/chaînes
      * Ajouter/insérer/supprimer règles
      * Lister les règles
      * Flush (vider)
      * Spécifier la politique
4.  **Exemples Pratiques avec nftables**
      * Filtrage de base (INPUT, OUTPUT, FORWARD)
      * Gestion des états de connexion
      * Redirection de ports (DNAT)
      * Partage de connexion (MASQUERADE)
      * Utilisation des Sets (IP, ports)
      * Utilisation des Maps (NAT conditionnel)
      * Création de chaînes personnalisées
      * Règles basées sur le temps
5.  **Gestion et Persistance des Règles nftables**
      * Sauvegarder et restaurer
      * Fichier de configuration par défaut (`/etc/nftables.conf`)
      * Activation du service `nftables`
6.  **Dépannage et Bonnes Pratiques**
      * Affichage des règles (`nft list ruleset`)
      * Journalisation (`log`)
      * Ordre des règles et priorité des chaînes
      * Tester prudemment
      * Comparaison avec iptables (rappel)

-----

### **1. Pourquoi nftables ? Limitations d'iptables**

Bien qu'iptables soit robuste, il présentait plusieurs limitations qui ont conduit au développement de nftables :

  * **Multiplicité des outils :** iptables ne gère que IPv4. Pour IPv6, il fallait `ip6tables`. Pour le pontage, `ebtables`. Pour l'ARP, `arptables`. Cela rendait la gestion complexe.
  * **Architecture non unifiée :** Chaque "table" (filter, nat, mangle) dans iptables est implémentée de manière légèrement différente dans le noyau, avec des points de traitement distincts et des limitations.
  * **Performance :** Pour un grand nombre de règles, iptables pouvait devenir moins performant.
  * **Atomicity :** Les modifications de règles dans iptables n'étaient pas atomiques. Cela signifie qu'il pouvait y avoir de brèves périodes d'instabilité ou d'insécurité lors de l'application d'un grand ensemble de règles.
  * **Complexité pour des tâches simples :** Certaines tâches (comme bloquer une liste d'IPs) nécessitaient beaucoup de règles individuelles dans iptables.
  * **Pas de langage de script intégré :** Pas de boucles, de variables, de fonctions pour des règles dynamiques.

**nftables** résout ces problèmes en fournissant un seul framework unifié dans le noyau, piloté par un seul outil en espace utilisateur (`nft`).

-----

### **2. Architecture et Concepts Clés de nftables**

nftables s'appuie sur une machine virtuelle de paquets dans le noyau, permettant une grande flexibilité.

#### **Familles d'adresses (Address Families)**

Contrairement à iptables où vous deviez choisir `iptables` ou `ip6tables`, `nft` permet de spécifier la famille d'adresses pour chaque table, ou d'utiliser une table générique pour plusieurs familles.

  * `ip`: IPv4
  * `ip6`: IPv6
  * `inet`: Indépendant de la version IP (IPv4 et IPv6 combinés) - *Très utile \!*
  * `arp`: ARP
  * `bridge`: Pontage Ethernet
  * `netdev`: Trafic sur une interface réseau spécifique (avant le routage)

#### **Tables**

Les tables sont les conteneurs de niveau supérieur pour les chaînes. Elles sont créées pour des familles d'adresses spécifiques. Vous pouvez nommer vos tables comme vous le souhaitez.

```bash
# Créer une table pour IPv4
sudo nft add table ip my_filter_table

# Créer une table pour IPv6
sudo nft add table ip6 my_filter_table_v6

# Créer une table pour IPv4 et IPv6
sudo nft add table inet my_unified_table
```

#### **Chaînes (Chains)**

Les chaînes sont les listes ordonnées de règles, tout comme dans iptables. Cependant, dans nftables, elles ont des propriétés supplémentaires :

  * **Type (Type of Chain):**
      * `filter`: Pour le filtrage de paquets.
      * `nat`: Pour la translation d'adresses.
      * `route`: Pour modifier les paquets liés au routage.
  * **Hook (Point d'accroche):** L'équivalent des chaînes par défaut d'iptables (`INPUT`, `OUTPUT`, `FORWARD`, `PREROUTING`, `POSTROUTING`). C'est l'endroit dans le chemin de traitement du paquet où la chaîne est attachée.
      * `prerouting`: Avant le routage (similaire à iptables `PREROUTING`).
      * `input`: Paquets destinés à la machine locale (similaire à iptables `INPUT`).
      * `forward`: Paquets traversant la machine (similaire à iptables `FORWARD`).
      * `output`: Paquets générés par la machine locale (similaire à iptables `OUTPUT`).
      * `postrouting`: Après le routage (similaire à iptables `POSTROUTING`).
  * **Priority (Priorité):** Définit l'ordre dans lequel les chaînes de même hook sont évaluées. Une priorité plus basse signifie une évaluation plus tôt. Utile pour les architectures complexes où plusieurs composants peuvent injecter des règles.
      * `-100`: `raw` (très tôt)
      * `-50`: `mangle`
      * `0`: `filter` (par défaut)
      * `100`: `nat` (tard)
  * **Policy (Politique) :** L'action par défaut si aucune règle ne correspond dans la chaîne. `accept` ou `drop`.

**Exemple de création de chaîne hook :**

```bash
sudo nft add chain inet my_unified_table input { type filter hook input priority 0 \; policy drop \; }
sudo nft add chain inet my_unified_table forward { type filter hook forward priority 0 \; policy drop \; }
sudo nft add chain inet my_unified_table output { type filter hook output priority 0 \; policy accept \; }
```

**Chaînes régulières (User-defined chains) :** Vous pouvez créer des chaînes sans type ni hook, et les appeler depuis d'autres chaînes (similaire au `JUMP` d'iptables).

```bash
sudo nft add chain inet my_unified_table my_ssh_chain
```

#### **Sets (Ensembles)**

Les sets sont des listes d'éléments (adresses IP, ports, interfaces, etc.) qui peuvent être utilisés dans les règles. Ils améliorent la performance et la lisibilité en remplaçant de nombreuses règles individuelles par une seule règle faisant référence à un ensemble.

```bash
# Créer un set d'adresses IP pour les sources autorisées
sudo nft add set inet my_unified_table trusted_ips { type ipv4_addr \; }
sudo nft add element inet my_unified_table trusted_ips { 192.168.1.100, 10.0.0.5 }

# Créer un set de ports autorisés pour les services web
sudo nft add set inet my_unified_table web_ports { type inet_service \; }
sudo nft add element inet my_unified_table web_ports { 80, 443 }

# Utiliser un set dans une règle
sudo nft add rule inet my_unified_table input ip saddr @trusted_ips tcp dport @web_ports accept
```

#### **Maps (Cartes)**

Les maps permettent de mapper une valeur d'entrée à une valeur de sortie. Elles sont extrêmement puissantes pour la NAT conditionnelle ou la modification dynamique de paquets.

```bash
# Créer une map pour rediriger le trafic HTTP/HTTPS vers différents serveurs
sudo nft add map inet my_unified_table web_servers { type inet_service : ipv4_addr \; }
sudo nft add element inet my_unified_table web_servers { 80 : 192.168.1.10, 443 : 192.168.1.20 }

# Utiliser la map pour DNAT
sudo nft add rule inet my_unified_table prerouting tcp dport { 80, 443 } dnat to tcp dport map @web_servers
```

#### **Concatenations**

Permet de faire correspondre des combinaisons de champs (par ex., adresse IP source et port source) pour créer des mappings ou des ensembles plus complexes.

#### **Cibles (Statements/Actions)**

Ce sont les actions à exécuter lorsqu'une règle correspond. Similaires aux cibles d'iptables, mais avec une syntaxe plus uniforme.

  * `accept`: Accepter le paquet.
  * `drop`: Supprimer le paquet silencieusement.
  * `reject`: Supprimer le paquet et envoyer un message d'erreur.
  * `log`: Enregistrer les informations du paquet.
  * `jump <chain_name>`: Sauter vers une autre chaîne.
  * `goto <chain_name>`: Sauter vers une autre chaîne (mais le traitement ne revient pas à la chaîne appelante).
  * `snat`: Source NAT.
  * `dnat`: Destination NAT.
  * `masquerade`: Masquage d'adresse IP source.
  * `counter`: Incrémente un compteur (intégré à chaque règle par défaut, affiché avec `list ruleset`).
  * `limit`: Limite le taux de correspondance.

#### **Expressions**

nftables utilise des expressions pour définir les critères de correspondance et les actions. C'est un langage plus structuré et lisible.

  * `ip saddr`: Adresse IP source IPv4.
  * `ip daddr`: Adresse IP destination IPv4.
  * `tcp dport`: Port destination TCP.
  * `meta iif`: Interface d'entrée.
  * `ct state`: État de la connexion (`new`, `established`, `related`, `invalid`).
  * `limit rate`: Limiter le débit.

-----

### **3. Syntaxe Générale de `nft`**

La commande principale est `nft`.

```bash
nft <command> <object_type> <object_name> [parameters]
```

  * `nft`: La commande principale.
  * `<command>`: L'action à effectuer.
      * `add`: Ajouter un objet (table, chaîne, règle, set, element).
      * `delete`: Supprimer un objet.
      * `flush`: Vider les règles/éléments d'un objet.
      * `list`: Lister les objets (tables, chaînes, ruleset, sets).
      * `insert`: Insérer une règle à un index spécifique.
      * `replace`: Remplacer une règle existante.
      * `define`: Définir une variable (pour les scripts).
  * `<object_type>`: Le type d'objet (table, chain, rule, set, element).
  * `<object_name>`: Le nom de l'objet.

**Exemples de commandes de base :**

  * **Lister toutes les règles :**
    ```bash
    sudo nft list ruleset
    ```
  * **Vider toutes les règles :**
    ```bash
    sudo nft flush ruleset
    ```
  * **Créer une table :**
    ```bash
    sudo nft add table inet my_filter
    ```
  * **Créer une chaîne hook :**
    ```bash
    sudo nft add chain inet my_filter input { type filter hook input priority 0 \; policy drop \; }
    ```
  * **Créer une chaîne régulière :**
    ```bash
    sudo nft add chain inet my_filter my_custom_chain
    ```
  * **Ajouter une règle (à la fin) :**
    ```bash
    sudo nft add rule inet my_filter input ip saddr 192.168.1.100 accept
    ```
  * **Insérer une règle (au début) :**
    ```bash
    sudo nft insert rule inet my_filter input ip saddr 192.168.1.100 accept
    ```
  * **Supprimer une règle (par numéro de handle ou spécification) :**
    ```bash
    # Lister avec les handles
    sudo nft -a list ruleset
    # Supprimer par handle
    sudo nft delete rule inet my_filter input handle <handle_number>
    # Supprimer par spécification (si unique)
    sudo nft delete rule inet my_filter input ip saddr 192.168.1.100 accept
    ```
  * **Définir la politique d'une chaîne :**
    ```bash
    sudo nft chain inet my_filter input { policy drop \; }
    ```

-----

### **4. Exemples Pratiques avec nftables**

Nous allons recréer des scénarios courants avec nftables.

#### **Configuration de base (équivalent du "skeleton" iptables)**

```bash
# 1. Vider toutes les règles existantes (TRÈS IMPORTANT pour commencer propre)
sudo nft flush ruleset

# 2. Créer une table 'inet' pour gérer IPv4 et IPv6 de manière unifiée
sudo nft add table inet filter

# 3. Définir les chaînes principales avec leurs hooks et politiques par défaut
# INPUT: Trafic vers le serveur (par défaut DROP)
sudo nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
# FORWARD: Trafic traversant le serveur (par défaut DROP)
sudo nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop \; }
# OUTPUT: Trafic depuis le serveur (par défaut ACCEPT pour ne pas se bloquer au début)
sudo nft add chain inet filter output { type filter hook output priority 0 \; policy accept \; }

# 4. Autoriser le trafic de bouclage (localhost)
sudo nft add rule inet filter input iif lo accept
sudo nft add rule inet filter output oif lo accept

# 5. Autoriser les connexions établies et liées (crucial pour que les réponses reviennent)
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter forward ct state established,related accept
sudo nft add rule inet filter output ct state established,related accept
```

#### **Filtrage de base (INPUT)**

  * **Autoriser SSH (port 22) depuis tout le monde :**
    ```bash
    sudo nft add rule inet filter input tcp dport 22 accept
    ```
  * **Autoriser SSH seulement depuis une IP spécifique :**
    ```bash
    sudo nft add rule inet filter input ip saddr 192.168.1.100 tcp dport 22 accept
    ```
  * **Bloquer le ping (ICMP) :**
    ```bash
    sudo nft add rule inet filter input icmp type echo-request drop
    ```
  * **Autoriser HTTP/HTTPS :**
    ```bash
    sudo nft add rule inet filter input tcp dport { 80, 443 } accept
    ```

#### **Redirection de ports (DNAT - Table `nat`)**

  * **Créer la table nat :**
    ```bash
    sudo nft add table ip nat
    ```
  * **Créer la chaîne PREROUTING dans la table `nat` :**
    ```bash
    sudo nft add chain ip nat prerouting { type nat hook prerouting priority 0 \; }
    ```
  * **Rediriger le port 80 externe vers 192.168.1.100:8080 en interne :**
    ```bash
    sudo nft add rule ip nat prerouting iifname "eth0" tcp dport 80 dnat to 192.168.1.100:8080
    ```
    *N'oubliez pas d'activer le routage IP (`net.ipv4.ip_forward = 1`) et d'autoriser le `FORWARD` dans la table `filter`.*

#### **Partage de connexion (MASQUERADE - Table `nat`)**

  * **Créer la chaîne POSTROUTING dans la table `nat` :**
    ```bash
    sudo nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; } # Priority 100 est standard pour POSTROUTING NAT
    ```
  * **Masquer le trafic sortant sur `eth0` :**
    ```bash
    sudo nft add rule ip nat postrouting oifname "eth0" masquerade
    ```
    *Assurez-vous que le routage IP est activé (`net.ipv4.ip_forward = 1`).*

#### **Utilisation des Sets (IP, ports)**

```bash
# Créer un set pour les IPs de confiance
sudo nft add set inet filter trusted_ips { type ipv4_addr \; comment "Adresses IP de confiance pour l'administration" \; }
sudo nft add element inet filter trusted_ips { 192.168.1.10, 10.0.0.5 }

# Créer un set pour les ports HTTP/HTTPS
sudo nft add set inet filter web_services { type inet_service \; comment "Ports pour les services web" \; }
sudo nft add element inet filter web_services { 80, 443 }

# Appliquer les règles en utilisant les sets
sudo nft add rule inet filter input ip saddr @trusted_ips tcp dport 22 accept
sudo nft add rule inet filter input tcp dport @web_services accept
```

#### **Utilisation des Maps (NAT conditionnel)**

```bash
# Créer une map pour rediriger différents ports vers différentes IPs
sudo nft add map ip nat dport_to_ip { type inet_service : ipv4_addr \; }
sudo nft add element ip nat dport_to_ip { 80 : 192.168.1.10, 443 : 192.168.1.20 }

# Règle DNAT utilisant la map
sudo nft add rule ip nat prerouting tcp dport { 80, 443 } dnat to ip dport_to_ip
```

#### **Création et utilisation de chaînes personnalisées**

```bash
# Créer une chaîne personnalisée pour les règles SSH
sudo nft add chain inet filter ssh_rules

# Ajouter des règles à la chaîne personnalisée
sudo nft add rule inet filter ssh_rules ip saddr 192.168.1.0/24 accept
sudo nft add rule inet filter ssh_rules counter log prefix "SSH_BLOCKED: " drop

# Faire "sauter" le trafic SSH vers cette chaîne
sudo nft add rule inet filter input tcp dport 22 jump ssh_rules
```

#### **Règles basées sur le temps**

```bash
# Autoriser SSH uniquement pendant les heures de bureau (Lundi-Vendredi, 9h-17h)
sudo nft add rule inet filter input tcp dport 22 meta time period "09:00:00-17:00:00" weekday "Mon-Fri" accept
# Tout autre trafic SSH est drop
sudo nft add rule inet filter input tcp dport 22 drop
```

-----

### **5. Gestion et Persistance des Règles nftables**

La méthode préférée pour gérer et rendre persistantes les règles nftables est via le fichier de configuration principal et le service Systemd.

#### **Fichier de configuration par défaut : `/etc/nftables.conf`**

C'est le fichier principal où vous devriez écrire vos règles de manière déclarative.

**Exemple de `/etc/nftables.conf` :**

```nft
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        # Allow loopback interface
        iif lo accept

        # Allow established and related connections
        ct state established,related accept

        # Allow SSH from specific IP (change this to your admin IP)
        ip saddr 192.168.1.100 tcp dport 22 accept

        # Allow HTTP/HTTPS
        tcp dport { 80, 443 } accept

        # Log and drop anything else
        log prefix "NFT_DROP_INPUT: "
        drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow established and related forwarded connections
        ct state established,related accept

        # Example: Allow traffic from internal network to external (requires NAT)
        # iifname "eth1" oifname "eth0" accept # eth1 internal, eth0 external
    }

    chain output {
        type filter hook output priority 0; policy accept;

        # Block outgoing HTTP/HTTPS to specific destination (example)
        # ip daddr 203.0.113.1 tcp dport { 80, 443 } drop
    }
}

table ip nat {
    chain prerouting {
        type nat hook prerouting priority 0;

        # DNAT HTTP to internal web server
        # iifname "eth0" tcp dport 80 dnat to 192.168.1.10:80
    }

    chain postrouting {
        type nat hook postrouting priority 100;

        # MASQUERADE for outgoing internet traffic
        # oifname "eth0" masquerade
    }
}
```

#### **Activation du service `nftables`**

Sur les systèmes Systemd (la plupart des distributions Linux modernes) :

1.  **Écrivez vos règles** dans `/etc/nftables.conf`.
2.  **Vérifiez la syntaxe** (avant de recharger) :
    ```bash
    sudo nft -c -f /etc/nftables.conf
    ```
    Si cela ne renvoie rien, la syntaxe est correcte.
3.  **Activez le service au démarrage :**
    ```bash
    sudo systemctl enable nftables
    ```
4.  **Démarrez/Redémarrez le service :**
    ```bash
    sudo systemctl start nftables
    # Ou pour recharger les règles après une modification du fichier :
    sudo systemctl restart nftables
    ```
5.  **Vérifiez le statut :**
    ```bash
    sudo systemctl status nftables
    ```

-----

### **6. Dépannage et Bonnes Pratiques**

  * **Toujours commencer par `flush ruleset` :** C'est une bonne pratique dans vos scripts ou fichiers de configuration pour éviter les règles dupliquées ou conflictuelles des sessions précédentes.
  * **Utilisez `inet` pour la plupart des tables :** Sauf si vous avez des besoins très spécifiques à IPv4 ou IPv6. `inet` simplifie grandement la gestion.
  * **Testez vos règles avant de les rendre persistantes :** Appliquez les règles en ligne de commande. Si tout fonctionne, alors seulement mettez-les dans `/etc/nftables.conf` et redémarrez le service.
  * **Utilisez `nft -a list ruleset` :** Le drapeau `-a` affiche les "handles" (identifiants uniques) des règles, ce qui est très utile pour supprimer ou remplacer des règles spécifiques.
  * **Utilisez `log` pour le débogage :** Ajoutez `log prefix "MyRuleDebug: "` aux règles pour voir si les paquets les atteignent et comment ils sont traités. Vérifiez `/var/log/syslog` ou `journalctl -f`.
  * **Comprendre le flux des paquets :** Mémorisez l'ordre des hooks (`prerouting` -\> `input`/`forward` -\> `output` -\> `postrouting`) et comment les tables interagissent (par exemple, `nat` avant `filter` pour `DNAT`).
  * **Politiques par défaut :** Définissez toujours les politiques de vos chaînes `input` et `forward` sur `drop` après avoir établi les règles d'acceptation nécessaires. Laissez `output` sur `accept` au début, puis affinez si nécessaire.
  * **Nommage :** Donnez des noms descriptifs à vos tables, chaînes, sets et maps pour améliorer la lisibilité.
  * **Commentaires :** Utilisez des commentaires (`#`) dans votre fichier `/etc/nftables.conf` pour expliquer la logique de vos règles.
  * **Connaissance du système :** Assurez-vous que le routage IP (`net.ipv4.ip_forward`) est activé si vous comptez faire du `FORWARD` ou du `NAT`.

**Comparaison rapide `nftables` vs `iptables`:**

**NB:** Cette comparaison ne m'appartient pas. (De même pour 6)

| Caractéristique       | iptables                               | nftables                                                 |
| :-------------------- | :------------------------------------- | :------------------------------------------------------- |
| **Familles d'adresses** | Séparé (iptables, ip6tables, ebtables) | Unifié (ip, ip6, inet, bridge, netdev)                 |
| **Syntaxe** | Per-protocole, verbeuse              | Expressive, basée sur la machine virtuelle de paquets |
| **Atomicité** | Non                                    | Oui (transactions)                                       |
| **Sets/Maps** | Implémentation limitée (`ipset`)       | Intégrés et puissants                                    |
| **Performance** | Moins performant avec bcp de règles    | Meilleure performance à grande échelle                   |
| **Développement** | Mode maintenance                     | Actif, futur du pare-feu Linux                           |
| **Complexité** | Plus simple pour le basique, complexe pour l'avancé | Plus complexe au démarrage, plus simple pour l'avancé |
