ALTER SESSION SET CONTAINER = ESHOP_SITE2_PDB;
ALTER SESSION SET CURRENT_SCHEMA = globale_user;

CREATE OR REPLACE PROCEDURE insert_ligne (
    p_id_ligne_commande IN LIGNES_COMMANDES_2.ID_LIGNE_COMMANDE%TYPE,
    p_id_commande       IN LIGNES_COMMANDES_2.ID_COMMANDE%TYPE,
    p_id_produit        IN LIGNES_COMMANDES_2.ID_PRODUIT%TYPE,
    p_quantite          IN LIGNES_COMMANDES_2.QUANTITE%TYPE,
    p_remise            IN LIGNES_COMMANDES_2.REMISE%TYPE
) 
AS
    nc INTEGER DEFAULT 0;
BEGIN
    -- 1. Check for negative or zero values
    IF p_quantite <= 0 OR p_remise < 0 OR p_id_ligne_commande <= 0 OR p_id_commande <= 0 OR p_id_produit <= 0 THEN
        raise_application_error(-20001, 'FAILED: One or more numeric inputs are invalid (<= 0).');
    END IF;

    -- 2. Check if the Ligne Commande ID already exists
    SELECT COUNT(*) INTO nc FROM LIGNES_COMMANDES_2 WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;
    IF nc > 0 THEN
        raise_application_error(-20002, 'FAILED: ID_LIGNE_COMMANDE already exists.');
    END IF;

    -- 3. Check if the Commande exists
    SELECT COUNT(*) INTO nc FROM COMMANDES_2 WHERE ID_COMMANDE = p_id_commande;
    IF nc = 0 THEN
        raise_application_error(-20003, 'FAILED: The requested ID_COMMANDE does not exist.');
    END IF;

    -- 4. Check if the Produit exists
    SELECT COUNT(*) INTO nc FROM PRODUITS_2 WHERE ID_PRODUIT = p_id_produit;
    IF nc = 0 THEN
        raise_application_error(-20004, 'FAILED: The requested ID_PRODUIT does not exist.');
    END IF;

    -- 5. Insert
    INSERT INTO LIGNES_COMMANDES_2 (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (p_id_ligne_commande, p_id_commande, p_id_produit, p_quantite, p_remise);

    DBMS_OUTPUT.PUT_LINE('SUCCESS: Ligne commande inserted.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED DATABASE ERROR: ' || SQLERRM);
        RAISE;
END insert_ligne;
/
CREATE OR REPLACE PROCEDURE delete_ligne (
    p_id_ligne_commande IN LIGNES_COMMANDES_2.ID_LIGNE_COMMANDE%TYPE
)
AS
    v_id_commande LIGNES_COMMANDES_2.ID_COMMANDE%TYPE;
    v_id_client COMMANDES_2.ID_CLIENT%TYPE;
    v_count_lines INTEGER;
    v_count_orders INTEGER;
BEGIN
    -- 1. Retrieve the command ID of this line
    SELECT ID_COMMANDE INTO v_id_commande
    FROM LIGNES_COMMANDES_2
    WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;

    -- 2. Delete the line itself
    DELETE FROM LIGNES_COMMANDES_2 WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;

    -- 3. Check if there are other lines left for this command in Site 2
    SELECT COUNT(*) INTO v_count_lines 
    FROM LIGNES_COMMANDES_2 
    WHERE ID_COMMANDE = v_id_commande;

    -- 4. If no more lines remain, delete the command as well
    IF v_count_lines = 0 THEN
        SELECT ID_CLIENT INTO v_id_client 
        FROM COMMANDES_2 
        WHERE ID_COMMANDE = v_id_commande;

        DELETE FROM COMMANDES_2 WHERE ID_COMMANDE = v_id_commande;

        -- 5. If this client has no other commands left in Site 2, clean up the client
        SELECT COUNT(*) INTO v_count_orders 
        FROM COMMANDES_2 
        WHERE ID_CLIENT = v_id_client;

        IF v_count_orders = 0 THEN
            DELETE FROM CLIENTS_2 WHERE ID_CLIENT = v_id_client;
        END IF;
    END IF;

    DBMS_OUTPUT.PUT_LINE('SUCCESS: Ligne commande and empty parent structures deleted.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20005, 'ERROR: That Ligne Commande ID does not exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
        RAISE;
END delete_ligne;
/
CREATE OR REPLACE PROCEDURE update_ligne (
    p_id_ligne_commande IN LIGNES_COMMANDES_2.ID_LIGNE_COMMANDE%TYPE,
    p_id_produit        IN LIGNES_COMMANDES_2.ID_PRODUIT%TYPE DEFAULT NULL,
    p_quantite          IN LIGNES_COMMANDES_2.QUANTITE%TYPE DEFAULT NULL,
    p_remise            IN LIGNES_COMMANDES_2.REMISE%TYPE DEFAULT NULL
)
IS
    nc INTEGER;
BEGIN
    SELECT COUNT(*) INTO nc FROM LIGNES_COMMANDES_2 WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;
    IF nc = 0 THEN
        raise_application_error(-20006, 'FAILED: Ligne Commande ID ' || p_id_ligne_commande || ' not found.');
    END IF;

    IF p_id_produit IS NOT NULL THEN
        SELECT COUNT(*) INTO nc FROM PRODUITS_2 WHERE ID_PRODUIT = p_id_produit;
        IF nc = 0 THEN
            raise_application_error(-20007, 'FAILED: Product ID ' || p_id_produit || ' does not exist in the database.');
        END IF;
    END IF;

    IF NVL(p_quantite, 1) <= 0 OR NVL(p_remise, 0) < 0 THEN
        raise_application_error(-20008, 'FAILED: Quantity must be > 0 and Remise must be >= 0.');
    END IF;

    UPDATE LIGNES_COMMANDES_2 
    SET
        ID_PRODUIT = NVL(p_id_produit, ID_PRODUIT),
        QUANTITE   = NVL(p_quantite, QUANTITE),
        REMISE     = NVL(p_remise, REMISE)
    WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;

    DBMS_OUTPUT.PUT_LINE('SUCCESS: Ligne Commande updated.');

EXCEPTION
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
        RAISE;
END update_ligne;
/

GRANT EXECUTE ON insert_ligne TO site2_user;
GRANT EXECUTE ON delete_ligne TO site2_user;
GRANT EXECUTE ON update_ligne TO site2_user;
