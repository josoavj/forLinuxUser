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

