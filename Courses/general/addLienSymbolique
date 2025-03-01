> Pour installer un logiciel:
  -> fichier .tar: Extract > Aller dans bin(Ou fichier d'installation au cas où ce n'est pas bin) > Copier le chemin de cet installation

> Lier à path et fish
  -> Créer un fichier et y ajouter:
    -> set -gx Nom_var chemin_d_installation
    -> set -gx PATH $PATH $Nom_var
    -> ouvrir ~/.config/fish/config.fish et y ajouter ce code:
       -> if test -e chemin_du_fichier
           source chemin_du_fichier
          end
    -> Enfin: source chemin_du_fichier

> Sur bash
  -> Créer un fichier et ye ajouter:
     -> export Var_name=chemin_d_installation
     -> export PATH=$PATH:$Var_name
  -> Rendre executable le fichier en question: chmod +x chemin_du_fichier
  -> Ouvrir le fichier ~/.bashrc et écrire:
     -> if [ -e chemin_du_fichier ]; then
           . chemin_du_fichier
        fi

Remarque:
-> Pour les noms des fichiers, je recommande de les faire comme suit: .nom_fichier
