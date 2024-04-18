<?php
session_start();

// Test de connexion à la base
$config = parse_ini_file("config.ini");
try {
    $pdo = new \PDO("mysql:host=".$config["host"].";dbname=".$config["database"].";charset=utf8", $config["user"], $config["password"]);
} catch (Exception $e) {
    echo "<h1>Erreur de connexion à la base de données :</h1>";
    echo $e->getMessage();
    exit;
}

// Chargement des fichiers MVC
require("control/controleur.php");
require("view/vue.php");
require("model/Utilisateur.php");
require("model/annonce.php");
require("model/reservation.php");
require("model/proprietaire.php");
require("model/recherche.php");


//Routes
if(isset($_GET["action"])) {
    switch($_GET["action"]) {
        case "accueil":
            (new controleur)->accueil();
            break;
        case "connexion":
            (new controleur)->connexion();
            break;
        case "inscription":
            (new controleur)->inscription();
            break;
        case "recherche":
            (new controleur)->recherche();
            break;
        case "demandeReservation":
            (new controleur)->demandeReservation();
            break;
        case "succes":
            (new controleur)->succes();
            break;
        case "reservation":
            (new controleur)->reservation();
            break;
        case "mesLogements":
            (new controleur)->mesLogements();
            break;
        case "mesReservationsClient":
            (new Controleur)->mesReservationsClient();
            break;
        case "GestionsReservationIdLogement":
            (new Controleur)->GestionsReservationIdLogement();
            break;
        case "GestionsDisponibiliteIdLogement":
            (new Controleur)->GestionsDisponibiliteIdLogement();
            break;
        case "logout":
            (new controleur)->logout();
            (new controleur)->accueil();
            //header("index.php");
            break;
        case "annonce":
            (new controleur)->boutonannonce();
            break;
        case "annulerReservation":
            (new Controleur)->annulerReservation();
            break;
        default:
            //route par default : erreur404
            (new controleur)->erreur404();
            break;
    }
} else {
    // Pas d'action précisée = afficher l'accueil
    (new controleur)->accueil();
}
?>