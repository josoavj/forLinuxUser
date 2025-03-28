# Bases de mongoDB

## Installation et fonctionnement

- Télecharger mongodb compass et mongosh
- **Collections:** Equivalent des tables en SQL 
- **Méthodes:** Contenu de la base de données
- Orienté objets (Structure)


## Basic commands

- **exit:** Quitter mongosh
- **cls:** Nettoyer votre affichage

## Database

- Afficher les bases de données existant: `show dbs`
- Utiliser une base de données: `use database_name`
- Créer un nouveau base de donnée: `use new_database`
- Créer un nouveau collection: `db.createCollection("Collection_name")`
- Afficher les database existants (Seuls ceux qui contiennent des collections): `show dbs`
- Effacer une base de données: `db.dropDatabase("database_name")` ou `db.dropDatabase()` si la base de donnée est actif
- Ajouter le contenu d'une base de donnée: 
  - `use database_name`
  - `db.createCollection("Collection_name")`
  - `db.collection_name.insertOne({field: "value", field: value, field: value})`
- Afficher tout le contenu d'une base de données: `db.collection_name.find()`
- Ajouter plusieurs documents dans la collection: 
  - `db.collection_name.insertMany([{field1: "value", field2:value, field3:value}, {...}, {...}])`
  - Vous pouvez créer plusieurs documents en fonction de vos demandes
  - Ils doivent être consistantes (Même structure pour tous les autres documents)
