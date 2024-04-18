<?php
class reservation
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
// Récupérer les réservations en passant un id client en paramètre
    public function recupererReservations($idClient){
        $sql = "SELECT reservation.id AS id, rue, codePostal, ville, description, idProprietaire, tarif, 
                        COUNT(Piece.id) AS nbPieces, SUM(surface) AS surfaceTotal,reservation.dateDebut, reservation.dateFin, Photo.lien AS lienPhoto,
                        DATEDIFF(reservation.dateFin, reservation.dateDebut) * disponibilite.tarif as Total
                FROM reservation 
                INNER JOIN disponibilite ON reservation.idDisponibilite = disponibilite.id 
                INNER JOIN logement ON Logement.id = disponibilite.idLogement 
                INNER JOIN Piece ON Logement.id = Piece.idLogement 
                INNER JOIN Photo ON Logement.id = Photo.idLogement
                WHERE idClient = :unId 
                GROUP BY reservation.id ";

        $req = $this->pdo->prepare($sql);
        $req->bindParam(":unId", $idClient, \PDO::PARAM_INT);
        $res = $req->execute();
        if($res){
            $lesReservations = $req->fetchAll(\PDO::FETCH_ASSOC);
            return $lesReservations;
        }else{
            return false;
        }
    }
// Permet d'annuler pour le client 
    public function annulerReservation($id){
        $sql = "CALL supprimer_reservation(:unId)";
        $req = $this->pdo->prepare($sql);
        $req->bindParam(":unId", $id, \PDO::PARAM_INT);
        $res = $req->execute();
        if ($res){
            $resultat = $req->fetch(\PDO::FETCH_ASSOC);
        }else{
            return false;
        }
    }

    //Calculer tarif
    public function calculTarif($idReservation){
        $sql = "SELECT DATEDIFF(reservation.dateFin, reservation.dateDebut as nbjours, disponibilite.tarif 
                FROM reservation 
                INNER JOIN disponibilite ON reservation.idDisponibilite = disponibilite.id 
                WHERE reservation.id = :idReservation";
        $req = $this->pdo->prepare($sql);
        $req->bindParam(':idReservation', $idReservation, PDO::PARAM_INT);
        $req->execute();
        $resultat = $req->fetch();
        $duree = $resultat['duree'];
        $tarifjour = $resultat['tarif'];
        $total = $duree * $tarifjour;
        return $total;
    }
}