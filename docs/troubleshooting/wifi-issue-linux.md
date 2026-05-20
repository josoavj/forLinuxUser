---
title: "Wifi Issue Linux"
section: "troubleshooting"
category: "troubleshooting"
distro: null
usage: "troubleshooting"
---

# 📡 Dépannage – Pilote Wi-Fi Intel (**iwlwifi**)

> **ℹ️ À savoir :** Le pilote officiel pour les cartes Wi-Fi **Intel** sous Linux est `iwlwifi`.  
> Cette fiche explique comment le diagnostiquer, installer le firmware si nécessaire et le recharger.

---

## 1️⃣ Vérifier si le pilote est détecté par le noyau

```bash
sudo dmesg | grep iwlwifi

💡 **Astuce** :

* `dmesg` → Affiche le *kernel ring buffer* (messages internes du noyau).
* `sudo` → Permet d’afficher tous les messages, y compris ceux réservés à l’administrateur.

⚠ **Si aucun message n’apparaît** → Le pilote n’est peut-être pas installé ou reconnu.

---

## 2️⃣ En cas de problème ou de firmware manquant

🔍 Dans la sortie de `dmesg`, cherchez :

```
firmware: failed to load iwlwifi-xxxx-xx.ucode
```

ou

```
iwlwifi: unable to load firmware
```

📥 **Télécharger le firmware correspondant** :

```bash
sudo wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/iwlwifi-<version>.ucode -P /lib/firmware
```

* `-P /lib/firmware` → Enregistre directement dans le dossier système des firmwares.
* **Permissions root requises**.

💡 **Remplacez `<version>`** par la version exacte indiquée dans le message d’erreur.
*Exemple : `iwlwifi-8265-36.ucode`*

---

## 3️⃣ Recharger le module Wi-Fi

```bash
sudo modprobe -r iwlwifi    # Décharge le module
sudo modprobe iwlwifi       # Recharge le module
```

📌 **Note** :

* `modprobe` gère le chargement/déchargement des modules du noyau.
* L’option `-r` retire le module avant rechargement.

---

## 4️⃣ Redémarrer le gestionnaire réseau

```bash
sudo systemctl restart NetworkManager
```

Cela force la redétection et la réinitialisation du Wi-Fi.

---

## 5️⃣ Vérifications finales

1. **Firmware chargé** :

```bash
sudo dmesg | grep iwlwifi
```

2. **Interfaces réseau disponibles** :

```bash
ip link show
```

✅ Si votre carte Wi-Fi apparaît, le pilote est fonctionnel.

---

## 📎 Ressources utiles

* [📄 Documentation officielle iwlwifi (Intel)](https://wireless.wiki.kernel.org/en/users/drivers/iwlwifi)
* [💾 Dépôt officiel Linux Firmware](https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git)

