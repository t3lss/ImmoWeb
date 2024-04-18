<?php 
class Disponibilite{
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
    //Récuperer tte les disponibilités d'un logement passée en paramètre
    public function lesDisponibilites($idlogement){
        $sql ='SELECT dateDebut, dateFin FROM disponibilite WHERE idLogement = :id AND valide = 1';
        $req = $this->pdo->prepare($sql);
        $req->bindParam(':id',$idlogement, PDO::PARAM_INT);
        $req->execute();
        return $req->fetchAll();
    }

    //Ajouter une disponibilite
    public function ajouterDisponibilite($dateDebut, $dateFin, $idLogement, $tarif, $valide, $derive){
        $sql = 'INSERT INTO disponibilite (dateDebut, dateFin, idLogement, tarif, valide, derive) VALUES (:dateDebut, :dateFin, :idLogement, :tarif, :valide, :derive)';
        $req = $this->pdo->prepare($sql);
        $req->bindParam(':dateDebut', $dateDebut, PDO::PARAM_STR);
        $req->bindParam(':dateFin', $dateFin, PDO::PARAM_STR);
        $req->bindParam(':idLogement', $idLogement, PDO::PARAM_INT);
        $req->bindParam(':tarif', $tarif, PDO::PARAM_INT);
        $req->bindParam(':valide', $valide, PDO::PARAM_INT);
        $req->bindParam(':derive', $derive, PDO::PARAM_INT);
        $req->execute();
    }
    //Supprimer une disponibilité
    public function supprimerDisponibilite($id){
        $sql = 'DELETE FROM disponibilite WHERE id = :id';
        $req = $this->pdo->prepare($sql);
        $req->bindParam(':id', $id, PDO::PARAM_INT);
        $req->execute();
    }
    
    
}
?>