DROP PROCEDURE IF EXISTS fusion;
DROP PROCEDURE IF EXISTS nouvelle_dates_anterieur;
DROP PROCEDURE IF EXISTS nouvelle_dates_posterieur;
DROP PROCEDURE IF EXISTS supprimer_reservation;
DROP PROCEDURE IF EXISTS get_last;

DELIMITER $$

CREATE PROCEDURE supprimer_reservation(idReservation INT)
BEGIN
    DECLARE countDispoDerive, idDispo, idDispoDerive1, idDispoDerive2, idDispoDerive3, idDispoDerive4, idReserv1, idFus1, idFus2, count INT;
    DECLARE idDispoDate DATE;

    DECLARE IdateDebut, IdateFin DATETIME;
    DECLARE IidLogement INT;
    DECLARE Itarif DECIMAL(10,2);

    -- Augmenter la limite récursive
    SET max_sp_recursion_depth = 100;

    -- Sauvegarde dans (idDispo) l'idDisponibilite de la reservation qu'on veut supprimer
    SELECT idDisponibilite INTO idDispo 
    FROM reservation 
    WHERE id = idReservation;

    -- Sauvegarde dans (countDispoDerive) le nombre de reservations qui ont pour disponibilités des dérivés de (idDispo)
    SELECT COUNT(*) INTO countDispoDerive 
    FROM reservation 
    WHERE idDisponibilite IN (
        SELECT id 
        FROM disponibilite 
        WHERE derive = idDispo
    );
    -- S'il n'y en a qu'une
    IF countDispoDerive = 1 THEN

        -- Sauvegarde dans (idDispoDerive1) la disponibilité qui est une dérivé de (idDispo)
        -- ET qui possède une reservation
        SELECT id INTO idDispoDerive1 -- 2
        FROM disponibilite 
        WHERE derive = idDispo AND id IN (SELECT idDisponibilite FROM reservation)
        LIMIT 1;

        -- Sauvegarde dans (idReserv1) la reservation de idDispoDerive1
        -- ET qui possède une reservation
        SELECT id INTO idReserv1 -- 2
        FROM reservation 
        WHERE idDisponibilite = idDispoDerive1;

        -- Sauvegarde dans une variable le nombre de reservations qui ont pour disponibilités des dérivés de celle de base (idDispo) 
        -- ET dont les dérivés ne possède pas de reservation
        SELECT COUNT(*) INTO count 
        FROM disponibilite 
        WHERE derive = idDispo AND id NOT IN (SELECT idDisponibilite FROM reservation);

        IF count = 1 THEN
            -- Sauvegarde dans une variable la disponibilité qui est une dérivé de idDispo
            -- ET qui NE possède PAS de reservation
            SELECT id INTO idDispoDerive2
            FROM disponibilite 
            WHERE derive = idDispo AND id NOT IN (SELECT idDisponibilite FROM reservation);

            -- Supprime le disponibilité dérivé de idDispo qui ne possède pas de reservation
            DELETE FROM disponibilite WHERE id = idDispoDerive2;    
        END IF;

        -- Si (idDispo) et (idDispoDerive1) ont la même dateDebut
        IF (SELECT dateDebut FROM disponibilite WHERE id = idDispo) = (SELECT dateDebut FROM disponibilite WHERE id = idDispoDerive1) THEN

            -- Sauvegarde dans (count) le nombre de disponibilités (1 ou 0)
            -- qui sont dérivé de (idDispoDerive1)
            -- ET dont la dateDebut est postérieur à la dateFin (idReserv1) (la reservation de idDispoDerive1)
            SELECT COUNT(*) INTO count 
            FROM disponibilite 
            WHERE derive = idDispoDerive1 AND dateDebut >= (
                SELECT dateFin 
                FROM reservation 
                WHERE id = idReserv1
            );

            -- On vérifie qu'elle existe
            IF count = 1 THEN

                -- Sauvegarde dans (idDispoDerive3) de la disponibilité dans dérivé de (idDispoDerive1)
                SELECT id INTO idDispoDerive3 
                FROM disponibilite 
                WHERE derive = idDispoDerive1 AND dateDebut >= (
                    SELECT dateFin 
                    FROM reservation 
                    WHERE id = idReserv1
                );
                -- Sauvegarde dans (idDispoDate) de la dateFin de (idDispo)
                SELECT dateFin INTO idDispoDate FROM disponibilite WHERE id = idDispo;

                -- Modifie la dateFin pour qu'elle corresponde à celle de (idDispo)
                UPDATE disponibilite SET dateFin = idDispoDate WHERE id = idDispoDerive3;

                -- Répète cette opération pour toutes les reservations qui sont dérivé de (idDispoDerive3)
                CALL nouvelle_dates_posterieur(idDispoDerive3);
            ELSE

                SET IdateDebut = (SELECT dateFin FROM reservation WHERE id = idReserv1);
                SET IdateFin = (SELECT dateFin FROM disponibilite WHERE id = idDispo);
                SET IidLogement = (SELECT idLogement FROM disponibilite WHERE id = idDispo);
                SET Itarif = (SELECT tarif FROM disponibilite WHERE id = idDispo);

                -- Si elle n'existe pas, on la crée
                INSERT INTO disponibilite(dateDebut, dateFin, idLogement, tarif, valide, derive) VALUES (IdateDebut, IdateFin, IidLogement, Itarif, 1, idDispo);

            END IF;
        -- Sinon ils ont la même dateFin
        ELSE

            -- Sauvegarde dans (count) le nombre de disponibilités (1 ou 0)
            -- qui sont dérivé de (idDispoDerive1)
            -- ET dont la dateFin est antérieur à la dateDebut (idReserv1) (la reservation de idDispoDerive1)
            SELECT COUNT(*) INTO count 
            FROM disponibilite 
            WHERE derive = idDispoDerive1 AND dateFin <= (
                SELECT dateDebut 
                FROM reservation 
                WHERE id = idReserv1
            );
            
            -- On vérifie qu'elle existe
            IF count = 1 THEN

                -- Sauvegarde dans (idDispoDerive3) de la disponibilité dans dérivé de (idDispoDerive1)
                SELECT id INTO idDispoDerive3 
                FROM disponibilite 
                WHERE derive = idDispoDerive1 AND dateFin <= (
                    SELECT dateDebut 
                    FROM reservation 
                    WHERE id = idReserv1
                );

                -- Sauvegarde dans (idDispoDate) de la dateDebut de (idDispo)
                SELECT dateDebut INTO idDispoDate FROM disponibilite WHERE id = idDispo;

                -- Modifie la dateFin pour qu'elle corresponde à celle de (idDispo)
                UPDATE disponibilite SET dateDebut = idDispoDate WHERE id = idDispoDerive3;

                -- Répète cette opération pour toutes les reservations qui sont dérivé de (idDispoDerive3)
                CALL nouvelle_dates_anterieur(idDispoDerive3);
            ELSE

                SET IdateDebut = (SELECT dateDebut FROM disponibilite WHERE id = idDispo);
                SET IdateFin = (SELECT dateFin FROM reservation WHERE id = idReserv1);
                SET IidLogement = (SELECT idLogement FROM disponibilite WHERE id = idDispo);
                SET Itarif = (SELECT tarif FROM disponibilite WHERE id = idDispo);

                -- Si elle n'existe pas, on la crée
                INSERT INTO disponibilite(dateDebut, dateFin, idLogement, tarif, valide, derive) VALUES (IdateDebut, IdateFin, IidLogement, Itarif, 1, idDispo);

            END IF;
        END IF;

        -- Modification des derivés de (idDispoDerive1) pour qu'elles pointent vers la disponibilité (idDispo)
        UPDATE disponibilite SET derive = idDispo WHERE derive = idDispoDerive1;
        -- Modification de l'idDisponibilite de la reservation lié à la disponibilité (idDispoDerive1) pour mettre à la place celle de la nouvelle (idDispo)
        UPDATE reservation SET idDisponibilite = idDispo WHERE idDisponibilite = idDispoDerive1;
        
        -- Supprime la disponibilité dérivé de idDispo
        DELETE FROM disponibilite WHERE id = idDispoDerive1;
    ELSEIF countDispoDerive = 2 THEN

        -- Sauvegarder dans (idDispoDerive1) la 1er disponibilité dérivé de (idDispo)
        SELECT id INTO idDispoDerive1 
        FROM disponibilite 
        WHERE derive = idDispo 
        LIMIT 1;

        -- Sauvegarder dans (idDispoDerive2) la 2e disponibilité dérivé de (idDispo)
        SELECT id INTO idDispoDerive2 
        FROM disponibilite 
        WHERE derive = idDispo 
        LIMIT 1 OFFSET 1;

        -- Sauvegarder dans (idReserv1) la reservation (idDispoDerive1)
        SELECT id INTO idReserv1 
        FROM reservation 
        WHERE idDisponibilite = idDispoDerive1;

        -- On change la disponibilité de reservation pour lui mettre celle de base
        UPDATE reservation SET idDisponibilite = idDispo WHERE id = idReserv1;

        -- Vérifie s'il y a une dérivée de idDispoDerive1 avec des dates antérieures à idReserv1
        -- si oui, on lui change sa dérivée pour mettre celle de base
        SELECT COUNT(*) INTO count 
        FROM disponibilite 
        WHERE derive = idDispoDerive1 AND dateFin <= (
            SELECT dateDebut 
            FROM reservation 
            WHERE id = idReserv1
        );

        IF count = 1 THEN

            SELECT id INTO idDispoDerive3
            FROM disponibilite 
            WHERE derive = idDispoDerive1 AND dateFin <= (
                SELECT dateDebut 
                FROM reservation 
                WHERE id = idReserv1
            );

            UPDATE disponibilite SET derive = idDispo WHERE id = idDispoDerive3;
        END IF;

        -- Vérifie s'il y a une dérivée de idDispoDerive1 avec des dates postérieures à idReserv1
        -- si oui, on lui change sa dérivée pour mettre celle de base
        SELECT COUNT(*) INTO count 
        FROM disponibilite 
        WHERE derive = idDispoDerive1 AND dateDebut >= (
            SELECT dateFin 
            FROM reservation 
            WHERE id = idReserv1
        );

        IF count = 1 THEN

            SELECT id INTO idDispoDerive3
            FROM disponibilite 
            WHERE derive = idDispoDerive1 AND dateDebut >= (
                SELECT dateFin 
                FROM reservation 
                WHERE id = idReserv1
            );

            UPDATE disponibilite SET derive = idDispo WHERE id = idDispoDerive3;
            CALL get_last(idDispoDerive3, idDispoDerive4);
            CALL fusion(idDispoDerive3, idDispoDerive2);
            CALL nouvelle_dates_anterieur(idDispoDerive4);
        ELSE

            SET IdateDebut = (SELECT dateFin FROM reservation WHERE id = idReserv1);
            SET IdateFin = (SELECT dateFin FROM disponibilite WHERE id = idDispo);
            SET IidLogement = (SELECT idLogement FROM disponibilite WHERE id = idDispo);
            SET Itarif = (SELECT tarif FROM disponibilite WHERE id = idDispo);

            INSERT INTO disponibilite(dateDebut, dateFin, idLogement, tarif, valide, derive) VALUES (IdateDebut, IdateFin, IidLogement, Itarif, 1, idDispo);

            SELECT id INTO idDispoDerive3
            FROM disponibilite 
            WHERE derive = idDispo AND dateDebut = IdateDebut AND dateFin = IdateFin;

            CALL get_last(idDispoDerive3, idDispoDerive4);

            CALL fusion(idDispoDerive3, idDispoDerive2);

            CALL nouvelle_dates_anterieur(idDispoDerive4);
        END IF;



        DELETE FROM disponibilite WHERE id = idDispoDerive1 OR id = idDispoDerive2;
    ELSE
        DELETE FROM disponibilite WHERE derive = idDispo;
        UPDATE disponibilite SET valide = 1 WHERE id = idDispo;
    END IF;

    DELETE FROM reservation WHERE id = idReservation;

    -- Réinitialiser la limite récursive à sa valeur par défaut
    SET max_sp_recursion_depth = DEFAULT;

END$$


CREATE PROCEDURE fusion(idDispo1 INT, idDispo2 INT)
BEGIN

    DECLARE count, idDispoNew INT;
    DECLARE idDispoDate DATETIME;

    DECLARE IdateDebut, IdateFin DATETIME;
    DECLARE IidLogement INT;
    DECLARE Itarif DECIMAL(10,2);

    -- Sauvegarde dans une variable le nombre de disponibilité
    -- qui sont dérivé de la disponibilité idDispo1 (paramètre)
    -- ET dont la dateDebut est postérieur à la dateFin de la reservation de la disponiblité
    SELECT COUNT(*) INTO count 
    FROM disponibilite 
    WHERE derive = idDispo1 AND dateDebut >= (
        SELECT dateFin 
        FROM reservation 
        WHERE idDisponibilite = idDispo1
    );

    -- On vérifie que la dérivé de la disponibilité en paramètre existe
    IF count = 1 THEN

        -- On sauvegarde dans une variable l'id de cette disponibilité dérivé
        SELECT id INTO idDispoNew 
        FROM disponibilite 
        WHERE derive = idDispo1 AND dateDebut >= (
            SELECT dateFin 
            FROM reservation 
            WHERE idDisponibilite = idDispo1
        );

        -- On rappelle la fonction qui va faire la même chose avec la dérivé
        CALL fusion(idDispoNew, idDispo2);

        -- On modifie la dateFin pour mettre celle de la disponibilité idDispo2
        SET idDispoDate = (SELECT dateFin FROM disponibilite WHERE id = idDispo2);
        UPDATE disponibilite SET dateFin = idDispoDate WHERE id = idDispo1;

    -- S'il n'y a pas de dérivé correspondante 
    -- Alors on vérifie le cas où il y a une reservation de cette dérivé mais pas de disponibilité dérivé postérieur
    ELSEIF (SELECT COUNT(*) FROM reservation WHERE idDisponibilite = idDispo1) = 1 THEN

        SET IdateDebut = (SELECT dateDebut FROM reservation WHERE id = (SELECT id FROM reservation WHERE idDisponibilite = idDispo1));
        SET IdateFin = (SELECT dateFin FROM disponibilite WHERE id = idDispo2);
        SET IidLogement = (SELECT idLogement FROM disponibilite WHERE id = idDispo2);
        SET Itarif = (SELECT tarif FROM disponibilite WHERE id = idDispo2);

        -- On insère une disponibilité dans le cas où il n'y en a pas.
        INSERT INTO disponibilite(dateDebut, dateFin, idLogement, tarif, valide, derive) VALUES (IdateDebut, IdateFin, IidLogement, Itarif, 1, idDispo1);

        -- On sauvegarde dans une variable l'id de cette disponibilité dérivé
        SELECT id INTO idDispoNew 
        FROM disponibilite 
        WHERE derive = idDispo1 AND dateDebut = (
            SELECT dateFin 
            FROM reservation 
            WHERE idDisponibilite = idDispo1
        );

        -- On rappelle la fonction qui va faire la même chose avec la dérivé
        CALL fusion(idDispoNew, idDispo2);
    ELSE

        -- On modifie l'idDisponibilite de la reservation lié à la disponibilité idDispo2 pour mettre à la place celle de la nouvelle idDispo1
        UPDATE reservation SET idDisponibilite = idDispo1 WHERE idDisponibilite = idDispo2;
        -- On modifie les derivés de idDispo2 pour qu'elles pointent vers la disponibilité idDispo1
        UPDATE disponibilite SET derive = idDispo1 WHERE derive = idDispo2;

        -- On modifie la dateFin de cette nouvelle disponibilité pour qu'elle reprenne celle de idDispo2
        SET idDispoDate = (SELECT dateFin FROM disponibilite WHERE id = idDispo2);
        UPDATE disponibilite SET dateFin = idDispoDate WHERE id = idDispo1;

        UPDATE disponibilite SET valide = 0 WHERE id = idDispo1;
    END IF;
END$$

CREATE PROCEDURE nouvelle_dates_posterieur(idDispo1 INT)
BEGIN

    DECLARE count, idDispoNew INT;
    DECLARE idDispoDate DATETIME;

    -- Sauvegarde dans une variable le nombre de disponibilité
    -- qui sont dérivé de la disponibilité idDispo1 (paramètre)
    -- ET dont la dateDebut est postérieur à la dateFin de la reservation de la disponiblité
    SELECT COUNT(*) INTO count 
    FROM disponibilite 
    WHERE derive = idDispo1 AND dateDebut >= (
        SELECT dateFin 
        FROM reservation 
        WHERE idDisponibilite = idDispo1
    );

    -- On vérifie que la dérivé de la disponibilité en paramètre existe
    IF count = 1 THEN

        -- Si elle existe, alors on sauvegarde dans une variable l'id de cette disponibilité dérivé
        SELECT id INTO idDispoNew 
        FROM disponibilite 
        WHERE derive = idDispo1 AND dateDebut >= (
            SELECT dateFin 
            FROM reservation 
            WHERE idDisponibilite = idDispo1
        );

        SELECT dateFin INTO idDispoDate FROM disponibilite WHERE id = idDispo1;

        -- On change la dateFin pour mettre celle de la disponibilité en paramètre
        UPDATE disponibilite SET dateFin = idDispoDate WHERE id = idDispoNew;

        -- On rappelle la fonction pour qu'elle face pareille avec la dérivé
        call nouvelle_dates_posterieur(idDispoNew);
    END IF;
END$$

CREATE PROCEDURE nouvelle_dates_anterieur(idDispo1 INT)
BEGIN

    DECLARE count, idDispoNew, idReserv INT;
    DECLARE idDispoDate DATETIME;

    DECLARE IdateDebut, IdateFin DATETIME;
    DECLARE IidLogement INT;
    DECLARE Itarif DECIMAL(10,2);

    -- Récupère le nombre de disponibilité dont la derive est celle en paramètre 
    -- ET dont la date de fin se passe avant celle de début de la reservation de la disponibilité
    SELECT COUNT(*) INTO count 
    FROM disponibilite 
    WHERE derive = idDispo1 AND dateFin <= (
        SELECT dateDebut 
        FROM reservation 
        WHERE idDisponibilite = idDispo1
    );

    -- On vérifie que la dérivé de la disponibilité en paramètre existe
    IF count = 1 THEN

        -- Si elle existe, alors sauvegarde dans une variable l'id de la disponibilité dérivé
        SELECT id INTO idDispoNew 
        FROM disponibilite 
        WHERE derive = idDispo1 AND dateFin <= (
            SELECT dateDebut 
            FROM reservation 
            WHERE idDisponibilite = idDispo1
        );

        SELECT dateDebut INTO idDispoDate FROM disponibilite WHERE id = idDispo1;

        -- On change la dateDebut pour mettre celle de la disponibilité en paramètre
        UPDATE disponibilite SET dateDebut = idDispoDate WHERE id = idDispoNew;

        -- On rappelle la fonction pour qu'elle face pareille avec la dérivé
        call nouvelle_dates_anterieur(idDispoNew);
    ELSEIF (SELECT COUNT(*) FROM reservation WHERE idDisponibilite = idDispo1) = 1 THEN
        SELECT id INTO idReserv FROM reservation WHERE idDisponibilite = idDispo1;

        SET IdateDebut = (SELECT dateDebut FROM disponibilite WHERE id = idDispo1);
        SET IdateFin = (SELECT dateDebut FROM reservation WHERE id = idReserv);
        SET IidLogement = (SELECT idLogement FROM disponibilite WHERE id = idDispo2);
        SET Itarif = (SELECT tarif FROM disponibilite WHERE id = idDispo2);

        -- On insère une disponibilité dans le cas où il n'y en a pas.
        INSERT INTO disponibilite(dateDebut, dateFin, idLogement, tarif, valide, derive) VALUES (IdateDebut, IdateFin, IidLogement, Itarif, 1, idDispo1);
    END IF;
END$$

CREATE PROCEDURE get_last(idDispo INT, OUT idOut INT)
BEGIN
    
    DECLARE count, idDispoNew, idOut2 INT;

    SELECT COUNT(*) INTO count 
        FROM disponibilite 
        WHERE derive = idDispo AND dateDebut >= (
            SELECT dateFin 
            FROM reservation 
            WHERE idDisponibilite = idDispo
        );

    -- On vérifie que la dérivé de la disponibilité en paramètre existe
    IF count = 1 THEN

        -- Si elle existe, alors sauvegarde dans une variable l'id de la disponibilité dérivé
        SELECT id INTO idDispoNew 
        FROM disponibilite 
        WHERE derive = idDispo AND dateDebut >= (
            SELECT dateFin 
            FROM reservation 
            WHERE idDisponibilite = idDispo
        );

        CALL get_last(idDispoNew, idOut2);

        SET idOut = idOut2;
        
    ELSE
        SET idOut = idDispo;
    END IF;

END$$
DELIMITER ;