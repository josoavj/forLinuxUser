# WHOIS : Annuaire Public des Noms de Domaine

**WHOIS** est un protocole de requête et de réponse qui est largement utilisé pour interroger des bases de données stockant les informations relatives aux propriétaires de noms de domaine et d'adresses IP. C'est en quelque sorte l'annuaire public d'Internet pour savoir "qui est" derrière un site web ou un bloc d'adresses IP.

Chaque fois qu'un nom de domaine est enregistré, l'ICANN (Internet Corporation for Assigned Names and Numbers) exige que les bureaux d'enregistrement de noms de domaine (registrars) collectent et stockent les informations de contact du propriétaire. Ces informations sont ensuite rendues accessibles via des serveurs WHOIS.

-----

## Fonctionnement de WHOIS ?

Lorsqu'une requête WHOIS est effectuée, elle interroge le ou les serveurs WHOIS appropriés pour obtenir les données d'enregistrement associées à un nom de domaine ou une adresse IP spécifique.

1.  **Requête :** Vous utilisez un client WHOIS (en ligne de commande ou un service web) pour interroger un nom de domaine (ex: `google.com`).
2.  **Redirection :** Le client WHOIS interroge d'abord un serveur racine WHOIS ou un serveur de domaine de premier niveau (TLD) (ex: pour `.com`). Ce serveur indique quel est le bureau d'enregistrement (registrar) du domaine.
3.  **Interrogation du Registrar :** Le client WHOIS se connecte ensuite au serveur WHOIS du bureau d'enregistrement spécifique qui a enregistré le domaine.
4.  **Réponse :** Le serveur du registrar renvoie les informations disponibles sur le propriétaire du domaine.

-----

## Les informations collectées avec WHOIS

Les informations que vous pouvez obtenir via une requête WHOIS varient en fonction du TLD (par exemple, les informations pour un `.com` peuvent différer de celles d'un `.fr` en raison des réglementations locales) et des services de confidentialité activés par le propriétaire du domaine. Cependant, voici les types d'informations courantes :

  * **Informations sur le Registrant (le Propriétaire du Domaine) :**
      * Nom et prénom (ou nom de l'organisation).
      * Adresse postale.
      * Adresse e-mail.
      * Numéro de téléphone.
  * **Informations sur le Registrar (le Bureau d'Enregistrement) :**
      * Nom du registrar (ex: GoDaddy, Gandi, OVH).
      * URL du registrar.
  * **Dates Clés :**
      * Date de création du domaine (`Creation Date`).
      * Date de dernière mise à jour (`Updated Date`).
      * Date d'expiration du domaine (`Expiration Date`).
  * **Serveurs de Noms (Name Servers) :**
      * Les serveurs DNS principaux et secondaires utilisés par le domaine (ex: `ns1.example.com`, `ns2.example.com`). Ces informations sont cruciales pour comprendre où le DNS du domaine est géré.
  * **Statut du Domaine :**
      * Indique si le domaine est actif, en attente de renouvellement, bloqué pour transfert, etc. (ex: `clientTransferProhibited`).

-----

## WHOIS dans le Contexte du Hacking : Reconnaissance passive

Dans le domaine du hacking éthique (ou malveillant), WHOIS est un outil de **reconnaissance passive** de premier plan. Il s'inscrit dans la phase de **footprinting** ou de **collecte d'informations (OSINT)**.

| Phase de Hacking | Rôle de `WHOIS`                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| :---------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Reconnaissance (OSINT)** | `WHOIS` est un outil direct pour la reconnaissance passive. Il permet d'obtenir des informations clés sur la cible sans interaction directe, ce qui est crucial pour rester furtif. \<br\>\<br\> Les informations obtenues sont utilisées pour : \<br\> - **Identifier la cible légale :** Connaître le propriétaire réel d'un domaine ou d'une adresse IP. \<br\> - **Collecter des contacts pour l'ingénierie sociale :** Les adresses e-mail et noms peuvent être utilisés pour des attaques de phishing ciblées. \<br\> - **Déterminer l'infrastructure DNS :** Les serveurs de noms indiquent qui gère les DNS du domaine, potentiellement un hébergeur ou un service Cloud. \<br\> - **Estimer l'ancienneté du domaine :** La date de création peut donner des indices sur la maturité de l'entreprise ou du projet. \<br\> - **Planifier le renouvellement :** La date d'expiration peut être un point faible (domain hijacking si le propriétaire oublie de renouveler). |
| 2. Scanne | Les serveurs de noms (`NS records`) obtenus via WHOIS peuvent être des cibles pour des requêtes DNS plus approfondies (avec `nslookup` ou `dig`) afin d'énumérer davantage de sous-domaines ou d'enregistrements.                                                                                                                                                                                                                                                         |
| 3. Accès Initial | L'e-mail du propriétaire peut être une cible de phishing très efficace, surtout s'il est lié à des privilèges administratifs sur le domaine ou l'infrastructure.                                                                                                                                                                                                                                                                                                          |

-----

## Confidentialité et Limites de WHOIS (Via Gemini)

Avec la montée des préoccupations concernant la vie privée et l'entrée en vigueur de réglementations comme le **RGPD (GDPR)**, la quantité d'informations personnelles disponibles publiquement via WHOIS a considérablement diminué pour les domaines enregistrés par des particuliers, notamment en Europe.

  * **Services de Confidentialité (WHOIS Privacy / Proxy) :** De nombreux registrars proposent des services de confidentialité WHOIS. Dans ce cas, les informations affichées sont celles du registrar ou d'un service proxy, et non celles du propriétaire réel. Cela limite la quantité d'informations directement utiles pour un attaquant.
  * **Données Anonymisées / Masquées :** Pour les domaines soumis au RGPD, les adresses e-mail, noms et adresses postales sont souvent masqués ou remplacés par des adresses génériques (`proxy@whois.domain-privacy.com`).
  * **Informations sur les adresses IP :** Les blocs d'adresses IP sont gérés par les RIR (Regional Internet Registries comme RIPE NCC, ARIN, APNIC, LACNIC, AFRINIC). Les requêtes WHOIS sur des adresses IP peuvent encore révéler des informations de contact pour les organisations ou les FAI qui gèrent ces blocs.

-----

## Utilisation de la Commande `whois`

La commande `whois` est disponible sur la plupart des systèmes Linux et macOS. Sur Windows, elle peut être téléchargée ou utilisée via des outils tiers.

**Syntaxe de base :**

```bash
whois [nom_de_domaine_ou_adresse_ip]
```

**Exemples :**

  * **Rechercher un domaine :**
    ```bash
    whois google.com
    ```
  * **Rechercher une adresse IP :**
    ```bash
    whois 8.8.8.8
    ```
    (Notez que pour une IP, la réponse proviendra du RIR gérant ce bloc d'adresses).

