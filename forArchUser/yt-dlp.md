# yt-dlp

En explorant des alternatives pour le téléchargement de vidéos YouTube, je suis tombé sur **yt-dlp**, un outil puissant et flexible.
Il permet d’extraire facilement du contenu multimédia (vidéos et audio) de plus d’un millier de sites web, directement depuis le terminal.

## Installation

* Sur les distributions basées sur Arch Linux, vous pouvez installer **yt-dlp** via Octopi ou directement en ligne de commande :

```bash
sudo pacman -S yt-dlp
```

* Pour d’autres distributions, il est possible d’installer via `pip` :

```bash
python3 -m pip install --upgrade yt-dlp
```

* Vous pouvez aussi télécharger l’exécutable directement depuis le dépôt officiel.

## Utilisation de base

L’utilisation est simple : il suffit de copier l’URL de la vidéo ou du contenu multimédia que vous souhaitez télécharger, puis d’exécuter la commande suivante :

```bash
yt-dlp URL_du_contenu
```

Par défaut, yt-dlp télécharge la meilleure qualité disponible.

## Personnalisation et configuration

Vous pouvez adapter yt-dlp à vos besoins grâce à un fichier de configuration. Celui-ci peut contenir des options par défaut telles que le format de la vidéo, la qualité, ou encore le répertoire de téléchargement.

Les emplacements habituels du fichier de configuration sont :

* `/etc/yt-dlp.conf` : configuration globale, valable pour tous les utilisateurs.
* `~/.config/yt-dlp/config` : configuration spécifique à l’utilisateur courant.

Si ces fichiers n’existent pas, vous pouvez les créer et y ajouter vos options personnalisées. Par exemple :

```text
# Exemple de configuration pour télécharger la meilleure qualité vidéo + audio fusionnée
-f bestvideo+bestaudio
-o ~/Téléchargements/%(title)s.%(ext)s
```

## Documentation et ressources utiles

* Liste complète des sites supportés par yt-dlp :
  [yt-dlp supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
* Dépôt officiel GitHub :
  [yt-dlp](https://github.com/yt-dlp/yt-dlp)
* Documentation complète et guide d’utilisation sur Arch Wiki :
  [yt-dlp - ArchWiki](https://wiki.archlinux.org/title/Yt-dlp)

