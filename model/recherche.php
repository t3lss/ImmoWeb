<?php
Class rechercher{
    private $pdo;

    public function __construct(){
        $config=parse_ini_file("config.ini");
        try{
            $this->pdo = new \PDO("mysql:host=".$config["host"].";dbname=".$config["database"].";charset=utf8", $config["user"], $config["password"]);
		} catch(Exception $e) {
			echo $e->getMessage();
		}
	}

    //Reccuperer les logements par rapport aux recherches
    public function recupAnnonceRecherche(){
        if(isset($_POST["btnRecherche"]) && !empty($_POST["barRecherche"])){
            $recherche = htmlspecialchars($_POST["barRecherche"]);
            $champ = $_POST["barRecherche"];
            $champ = trim($champ);
            $champ = strip_tags($champ);

            $requete = "SELECT DISTINCT logement.*, photo.lien AS lienPhoto  
            FROM logement 
            INNER JOIN disponibilite on logement.id = disponibilite.idLogement 
            INNER JOIN equipement on logement.id = equipement.idLogement 
            INNER JOIN photo on logement.id = photo.idLogement 
            INNER JOIN piece on logement.id = piece.idLogement 
            WHERE logement.description LIKE :champ 
            OR logement.ville LIKE :champ_ville";
            $champ = "%".$champ."%";
            $req = $this->pdo->prepare($requete);
            $req->bindParam(":champ", $champ, \PDO::PARAM_STR);
            $req->bindParam(":champ_ville", $champ, \PDO::PARAM_STR);
            $req->execute();
            $recherche = $req->fetchAll(\PDO::FETCH_ASSOC);
            return $recherche;
        }

    }
}
?>