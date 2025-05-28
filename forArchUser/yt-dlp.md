# yt-dlp

En cherchant de nouvelles altenatives sur le télechargement de vidéos Youtube, je suis tombé sur cet outil **yt-dlp**
Il me permet de facilement extraire (télecharger xD) du contenu multimédia (vidéos et audio) de plus d'un millier de sites internet, directement depuis mon terminal.

## Installation et utilisation

- Vous pouvez l'installer dans votre distribution (Arch Based) directement dans **Octopi** ou aussi directement dans votre terminal.
- Pour l'utilisation, il suffit de copier le lien du contenu multimédia que vous souhaitez télecharger et de procéder comme suit:
  - `yt-dlp lien_du_fichier`
- Plusieurs options et configurations sont possible, selon vos préferences. Comme la qualité par défaut et aussi le format de la vidéo. Vous pouvez trouver (ou créer s'il est absent) le fichier de configuration dans: 
  - `/etc/yt-dlp.conf`: pour une configuration globale. 
  - `~/.config/yt-dlp/config`: pour une configuration spécifique et uniquement à l'utilisateur actuel.

### Documentation sur yt-dlp

- La liste des sites supportés par cet outil sont dans [yt-dlp supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
- Le dépôt GitHub: [yt-dlp](https://github.com/yt-dlp)
- Vous pouvez consulter la documentation officielle dans [yt-dlp wiki](https://wiki.archlinux.org/title/Yt-dlp)
