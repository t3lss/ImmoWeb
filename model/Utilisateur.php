<?php
class Utilisateur {
    private $pdo;

    public function __construct(){
        $config=parse_ini_file("config.ini");
        
        try{
            $this->pdo = new \PDO("mysql:host=".$config["host"].";dbname=".$config["database"].";charset=utf8", $config["user"], $config["password"]);
		} catch(Exception $e) {
			echo $e->getMessage();
		}
	}
    public function connexion($mail,$password){
        $sql = 'SELECT id,mdp,Proprietaire FROM Utilisateur WHERE mail =:mail';
        $req = $this->pdo->prepare($sql);
        $req->bindParam(':mail',$mail,PDO::PARAM_STR);
        $req->execute();
        $ligne = $req->fetch();
        if($ligne != false){
            if(password_verify($password, $ligne['mdp'])){
                if($ligne["Proprietaire"] == 1 ){
                    $_SESSION["Proprietaire_session"] = $ligne['id'];
                    return true;
                }elseif($ligne["Proprietaire"] == 0 )
                {
                    $_SESSION["Client_session"] = $ligne['id'];
                    return true;
                }
            else{
                throw new Exception("Mot de passe incorrect");
            }
        }else{
            throw new Exception("Utilisateur non trouvé");
        }
        }
        return false;
    }


    //Verifie si l'utilisateur est déjà inscrit
    public function dejaInscrit($mail){
        $sql = "SELECT COUNT(*) AS nombre FROM Utilisateur WHERE mail = :mail";
        $req = $this->pdo->prepare($sql);
        $req->bindParam(':mail',$mail, PDO::PARAM_STR);
        $req->execute();
        $ligne = $req->fetch();
        if($ligne['nombre']==0){
            return false; 
        }else{
            return true;
        } 
    }
    //Inscrire un utilisateur
    public function inscription($mdp, $nom, $prenom, $mail){
        $sql ="INSERT INTO Utilisateur (mdp, nom, prenom, mail, proprietaire) VALUES (:mdp, :nom, :prenom, :mail, 0)";
        $req = $this->pdo->prepare($sql);
        $req->bindParam(":mdp",$mdp, PDO::PARAM_STR);
        $req->bindParam(":nom",$nom, PDO::PARAM_STR);
        $req->bindParam(":prenom", $prenom, PDO::PARAM_STR);
        $req->bindParam(":mail", $mail, PDO::PARAM_STR);
        $res = $req->execute();
        return $res;
    }
    //Récuperer les infos de l'utilisateur
    public function infosUtilisateur($utilisateur){
        $sql="SELECT * FROM Utilisateur WHERE id = :id";
        $req = $this->pdo->prepare($sql);
        $req->bindParam('id',$utilisateur, PDO::PARAM_INT);
        $req->execute();
        return $req->fetch();
    }
    
}

?>