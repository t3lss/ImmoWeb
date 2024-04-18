# AgenceImmoWeb

La base de donnée utilisé est Immobilier.sql
Le projet utilise un fichier config.ini pour faire la connexion à la BDD
> Ne pas hésitez à aller le modifier si besoin

Le projet contient déjà deux utilisateurs, un propriétaire et l'autre client
Utilisateur client : 
- email : a@a.a
- mdp : a

Utilisateur propriétaire : 
- email : b@b.b
- mdp : b

Lorsque l'utilisateur n'est pas connecté, il a accès aux annonces, à la bar de recherche ainsi qu'à l'inscription et à la connexion.

Lorsque l'utilisateur est connecté en tant que client, il en plus accès à toutes les reservations qu'il a fait et peut les annuler.

Lorsque l'utilisateur est connecté en tant que propriétaire, il a accès à toutes les logements qui lui appartiennent et pêut gérer les annonces (disponibilités) et les reservations qui y sont lié.