### Application tierce ou installé via archive sur Linux

- Fonctionne principalement sur les distribution basés sur Debian
- Veuillez déplacer le dossier de l'application source vers `/opt` avec: `sudo mv /dossierApp /opt`

### Ajout d'une application dans l'utilitaire d'application sur un système Linux

- Aller dans applications: 
  - `cd /usr/share/applications`

  ou 
  - `cd ~/.local/share/applications` (Si votre application est uniquement disponible pour vous

- Ensuite: `sudo nano nom_application.desktop`
- Changer le nom par le nom de votre application
- Configurer le fichier **.desktop**:
  - Ces commandes sont tous dans le fichier:
    - `[Desktop Entry]` 
    - `Version=1.0`
    - `Type=Application`
    - `Name=Nom de l'Application`
    - `Exec=commande_ou_chemin_vers_l_application`
    - `Icon=chemin_vers_l_icon.png`
    - `Terminal=false`
    - `Categories=AppCat;`
    - `Comment=Une brève description de l'application`
   - La version de l'application doit correspondre à sa version actuelle
   - Dans **exec**: le chemin de l'application est soit `/opt/application/bin/appication.sh` (L'extension variera en fonction de l'application) 
   - La catégorie de l'application peut être: **Network, Utility, Development,...**
   - **Exec:** La commande pour lancer l'application
   - **Icon:** Icône de l'application
   - **Terminal:** détermine si l'application s'execute dans un terminal

- Sauvegarder le fichier: `ctrl+X`
- Actualisez le cache des icône et des menus: `update-desktop-database ~/.local/share/applications` (En fonction du répertoire choisi)
