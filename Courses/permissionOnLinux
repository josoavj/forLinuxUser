## Ajout ou modification de la permission sur les fichiers sous Linux

### En utilisant chmod

- **chmod:** permet de modifier les permissions des fichiers et des répertoires
- La syntaxe de base est: `chmod [options] mode`

### Types de déclatation des permissions

- Il existe deux types de déclaration des modes ou des permissions: **la notation symbolique** et **la notation octale**

#### La notation symbolique
- Déclaration des permissions par des symboles
- Syntaxe: `chmod [notation_symbolique] fichier/dossier|

- Les symboles:
  - Pour les utilisateurs et groupes:
     - **u:** propriétaire (user)
     - **g:** groupe (group)
     - **o:** autres (others)
     - **a:** tous (all)

   - Pour les opérations à effectuer:
     - **+:** ajout du permission
     - **-:** retrait du permission
     - **=:** définition d'une permission exacte

   - Pour les sigles de permission:
     - **r:** read (Permission de lecture)
     - **w:** write (Permission d'écriture)
     - **x:** execute (Permission d'éxecution)

#### La notation octale

- C'est une représentation des permissions par un nombre à **trois chiffres** allant de **0 à 7**
- Syntaxe: `chmod number1 number2 number3 fichier/dossier`
   - **number1:** Pour l'utilisateur actuel
   - **number2:** Pour le groupe dr'utilisateur
   - **number3:** Pour les autres utilisateurs

- La valeur des chiffres:
   - **4:** read - lecture - r
   - **2:** write - écriture - w
   - **1:** execute - execution - x
- Ces chiffres sont additionnés pour définir les permissions souhaitées
- Remarques: 
   - `0` signifie **aucune permission attribuée**
   - `7` signifie que **toutes les permissions sont accordées (r,w,x)**

### Option courante
- Autorisation ou changement récursive: `-R`
  - `chmod -R permission fichier/dossier`
