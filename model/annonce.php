<?php
class annonce
{
    private $pdo;

    public function __construct()
    {
        $config = parse_ini_file("config.ini");

        try {
            $this->pdo = new \PDO("mysql:host=" . $config["host"] . ";dbname=" . $config["database"] . ";charset=utf8", $config["user"], $config["password"]);
        } catch (Exception $e) {
            echo $e->getMessage();
        }
    }

    //Récupérer les logements dans la base de données
    public function recupererAnnonces($nb1 = null, $nb2 = null)
    {
        $sql = "SELECT disponibilite.id AS id, rue, codePostal, ville, description, idProprietaire, COUNT(Piece.id) AS nbPieces, SUM(surface) AS surfaceTotal, Photo.lien AS lienPhoto, tarif
                FROM Logement 
                INNER JOIN Piece ON Logement.id = Piece.idLogement 
                INNER JOIN Photo ON Logement.id = Photo.idLogement 
                INNER JOIN disponibilite ON Logement.id = disponibilite.idLogement
                WHERE valide = 1 
                GROUP BY disponibilite.id ";
        if ($nb1 != null && $nb2 != null) {
            $sql .= "LIMIT :n1 , :n2 ;";
        }
        
        $req = $this->pdo->prepare($sql);
        if ($nb1 != null && $nb2 != null) {
            $req->bindParam(":n1", $nb1, \PDO::PARAM_INT);
            $req->bindParam(":n2", $nb2, \PDO::PARAM_INT);
        }
        $res = $req->execute();
        $lesAnnonces = $req->fetchAll();

        
        return $lesAnnonces;
    }

    public function recupererUneAnnonce($id)
    {
        $sql = "SELECT Logement.id AS id, rue, codePostal, ville, description, idProprietaire, COUNT(Piece.id) AS nbPieces, SUM(surface) AS surfaceTotal, tarif 
                FROM Logement 
                INNER JOIN Piece ON Logement.id = Piece.idLogement
                INNER JOIN disponibilite ON Logement.id = disponibilite.idLogement 
                WHERE disponibilite.id = :unId
                GROUP BY Logement.id";
        $req = $this->pdo->prepare($sql);
        $req->bindParam(":unId", $id, \PDO::PARAM_INT);
        $res = $req->execute();
        $annonce = $req->fetch(\PDO::FETCH_ASSOC);

        $sqlPieces = "SELECT id, surface, type FROM piece WHERE idLogement = :unId";
        $reqPieces = $this->pdo->prepare($sqlPieces);
        $reqPieces->bindParam(":unId", $annonce["id"], \PDO::PARAM_STR);
        $resPieces = $reqPieces->execute();
        $annonce["lesPieces"] = $reqPieces->fetchAll(\PDO::FETCH_ASSOC);

        $sqlEquipements = "SELECT id, libelle, idPiece FROM equipement WHERE idLogement = :unId";
        $reqEquipements = $this->pdo->prepare($sqlEquipements);
        $reqEquipements->bindParam(":unId", $annonce["id"], \PDO::PARAM_STR);
        $resEquipements = $reqEquipements->execute();
        $annonce["lesEquipements"] = $reqEquipements->fetchAll(\PDO::FETCH_ASSOC);

        $sqlPhotos = "SELECT id, lien, idEquipement, idPiece FROM photo WHERE idLogement = :unId";
        $reqPhotos = $this->pdo->prepare($sqlPhotos);
        $reqPhotos->bindParam(":unId", $annonce["id"], \PDO::PARAM_STR);
        $resPhotos = $reqPhotos->execute();
        $annonce["lesPhotos"] = $reqPhotos->fetchAll(\PDO::FETCH_ASSOC);

        $sqlDisponibilite = "SELECT dateDebut, dateFin, tarif FROM disponibilite WHERE id = :unId";
        $reqDisponibilite = $this->pdo->prepare($sqlDisponibilite);
        $reqDisponibilite->bindParam(":unId", $id, \PDO::PARAM_STR);
        $resDisponibilite = $reqDisponibilite->execute();
        $annonce["lesDisponibilites"] = $reqDisponibilite->fetch(\PDO::FETCH_ASSOC);
        
        return $annonce;
    }

    public function creerReservation($dateD, $dateF, $idD, $idC){
        $sql = "INSERT INTO reservation(dateDebut, dateFin, idDisponibilite, idClient) 
                VALUES (:laDateDebut, :laDateFin, :unIdDisponibilite, :unIdClient)";
        $req = $this->pdo->prepare($sql);
        $req->bindParam(":laDateDebut", $dateD, \PDO::PARAM_STR);
        $req->bindParam(":laDateFin", $dateF, \PDO::PARAM_STR);
        $req->bindParam(":unIdDisponibilite", $idD, \PDO::PARAM_INT);
        $req->bindParam(":unIdClient", $idC, \PDO::PARAM_INT);
        $res = $req->execute();

        if($res){
            $sql = "UPDATE disponibilite SET valide = 0 WHERE id = :unId";
            $req = $this->pdo->prepare($sql);
            $req->bindParam(":unId", $idD, \PDO::PARAM_STR);
            $res = $req->execute();
        }else{
            return false;
        }
    }

    public function creerDisponibilite($dateD, $dateF, $idLogement, $tarif, $derive = null){
        $sql = "INSERT INTO disponibilite(dateDebut, dateFin, idLogement, tarif, valide, derive) 
                VALUES (:laDateDebut, :laDateFin, :unId, :unTarif, 1, :uneDerive)";
        $req = $this->pdo->prepare($sql);
        $req->bindParam(":laDateDebut", $dateD, \PDO::PARAM_STR);
        $req->bindParam(":laDateFin", $dateF, \PDO::PARAM_STR);
        $req->bindParam(":unId", $idLogement, \PDO::PARAM_INT);
        $req->bindParam(":unTarif", $tarif, \PDO::PARAM_INT);
        $req->bindParam(":uneDerive", $derive, \PDO::PARAM_INT);
        return $req->execute();
    }

}
