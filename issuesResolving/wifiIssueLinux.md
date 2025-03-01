### En cas de problème sur la détection du pilote wifi intel

- Pour intel, le pilote est **iwlwifi**
- Vérifier dans les messages du kernel si le pilote est présent: `sudo dmesg | grep iwlwifi`
  - **dmesg** est une commande qui affiche le tampon de messages du noyau (kernel ring buffer). 
  Ce tampon contient des informations sur l'activité du noyau, y compris les messages de démarrage, les erreurs matérielles et les informations sur les pilotes de périphériques.
  - **sudo** est utilisé car la lecture du tampon de messages du noyau nécessite des privilèges d'administrateur.
- Si jamais il y a un problème détecté, réferer aux forums 
- Si jamais le firmware wifi est absent dans votre système et qu'il est mentionné dans les messages
  - Executer cette commande pour le télegcharger: `sudo wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/iwlwifi-version-spécifié.ucode -P /lib/firmware`
  - Cette commande permet de télecharger directement le firmware spécifié dans `/lib/firmware` (Librairie des firmwares)
  - Execution en tant que superutilisateur requis car la permission d'écriture dans `/lib/firmware` est réservé uniquement à ceux là
  - Ensuite, recharger le module wifi: `sudo modprobe -r iwlwifi`
    -  - Cette commande est utilisée pour charger le module du noyau **iwlwifi**
    - **modprobe** est une commande qui charge ou décharge des modules du noyau
  - Puis: `sudo modprobe iwlwifi`
  - Rédemarrer le gestionnaire réseau pour activer le Wifi: `sudo systemctl restart NetworkManager`
  - Vérifier si le firmware est bien chargé: `sudo dmesg | grep iwlwifi`
  - Vérifier dans la liste des interfaces: `ip link show`
   
