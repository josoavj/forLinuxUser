# Guide d’utilisation de yt-dlp (Avancé)

**yt-dlp** est un fork amélioré de youtube-dl, offrant des fonctionnalités supplémentaires, une meilleure prise en charge des sites et une plus grande flexibilité pour le téléchargement et l’extraction de contenu multimédia.

---

## Installation

* Sur Arch Linux et dérivés :

```bash
sudo pacman -S yt-dlp
```

* Via `pip` (compatible avec la plupart des distributions Linux) :

```bash
python3 -m pip install --upgrade yt-dlp
```

* Téléchargement direct de l’exécutable :

```bash
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
```

---

## Utilisation de base

```bash
yt-dlp <URL>
```

Télécharge la meilleure qualité vidéo et audio disponible par défaut.

---

## Options avancées courantes

### 1. Sélection de formats spécifiques

* Télécharger la meilleure vidéo avec la meilleure piste audio et les fusionner :

```bash
yt-dlp -f bestvideo+bestaudio <URL>
```

* Télécharger uniquement l’audio au format mp3 :

```bash
yt-dlp -x --audio-format mp3 <URL>
```

* Liste des formats disponibles pour une vidéo :

```bash
yt-dlp -F <URL>
```

### 2. Personnalisation du nom de fichier

Personnaliser la sortie avec des métadonnées, par exemple :

```bash
yt-dlp -o '~/Videos/%(upload_date)s - %(title)s.%(ext)s' <URL>
```

Variables courantes :

* `%(title)s` — titre de la vidéo
* `%(upload_date)s` — date de publication (format AAAAMMJJ)
* `%(uploader)s` — nom de l’uploader

### 3. Limitation de la vitesse de téléchargement

Pour éviter de saturer la bande passante :

```bash
yt-dlp --limit-rate 1M <URL>
```

Limite la vitesse à 1 Mo/s.

### 4. Téléchargement par lot

Créer un fichier texte (par exemple `urls.txt`) contenant une URL par ligne, puis lancer :

```bash
yt-dlp -a urls.txt
```

### 5. Reprendre un téléchargement interrompu

Par défaut yt-dlp supporte la reprise, mais pour forcer :

```bash
yt-dlp --continue <URL>
```

---

## Configuration avancée via fichier

### Fichier global

* `/etc/yt-dlp.conf`

### Fichier utilisateur

* `~/.config/yt-dlp/config`

---

### Exemple de fichier de configuration avancé

```text
# Télécharger la meilleure qualité vidéo et audio, et fusionner
-f bestvideo+bestaudio

# Sortie dans le dossier Videos avec date et titre
-o ~/Videos/%(upload_date)s - %(title)s.%(ext)s

# Limiter la vitesse à 2Mo/s
--limit-rate 2M

# Continuer les téléchargements interrompus
--continue

# Ne pas télécharger les sous-titres
--no-subs

# Supprimer les fichiers temporaires après fusion
--rm-cache-dir

# Afficher une barre de progression détaillée
--progress-template "Downloading %(title)s: %(percent)s%% at %(speed)s ETA %(eta)s"
```

---

## Automatisation

### Utiliser un script bash simple

```bash
#!/bin/bash
while IFS= read -r url; do
  yt-dlp -f bestvideo+bestaudio --continue -o '~/Videos/%(upload_date)s - %(title)s.%(ext)s' "$url"
done < urls.txt
```

### Intégration avec cron

Pour lancer un téléchargement automatique tous les jours à 2h du matin (exemple) :

```bash
0 2 * * * /usr/local/bin/yt-dlp -a /home/user/urls.txt --continue -o '/home/user/Videos/%(upload_date)s - %(title)s.%(ext)s'
```

---

## Dépannage et ressources

* Afficher la sortie détaillée pour diagnostiquer :

```bash
yt-dlp -v <URL>
```

* Consulter la liste des sites supportés :
  [yt-dlp supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
* Documentation officielle et wiki Arch Linux :
  [https://wiki.archlinux.org/title/Yt-dlp](https://wiki.archlinux.org/title/Yt-dlp)
