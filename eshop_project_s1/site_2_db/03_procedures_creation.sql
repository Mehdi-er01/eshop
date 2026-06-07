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
    v_error_msg VARCHAR2(200);
    NOT_VALID EXCEPTION;
BEGIN
    -- 1. Check for negative or zero values
    IF p_quantite <= 0 OR p_remise < 0 OR p_id_ligne_commande <= 0 OR p_id_commande <= 0 OR p_id_produit <= 0 THEN
        v_error_msg := 'FAILED: One or more numeric inputs are invalid (<= 0).';
        RAISE NOT_VALID;
    END IF;

    -- 2. Check if the Ligne Commande ID already exists (Must be 0)
    SELECT COUNT(*) INTO nc FROM LIGNES_COMMANDES_2 WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;
    IF nc > 0 THEN
        v_error_msg := 'FAILED: ID_LIGNE_COMMANDE already exists.';
        RAISE NOT_VALID;
    END IF;

    -- 3. Check if the Commande exists (Must be > 0)
    SELECT COUNT(*) INTO nc FROM COMMANDES_2 WHERE ID_COMMANDE = p_id_commande;
    IF nc = 0 THEN
        v_error_msg := 'FAILED: The requested ID_COMMANDE does not exist.';
        RAISE NOT_VALID;
    END IF;

    -- 4. Check if the Produit exists (Must be > 0)
    SELECT COUNT(*) INTO nc FROM PRODUITS_2 WHERE ID_PRODUIT = p_id_produit;
    IF nc = 0 THEN
        v_error_msg := 'FAILED: The requested ID_PRODUIT does not exist.';
        RAISE NOT_VALID;
    END IF;

    -- 5. Insert
    INSERT INTO LIGNES_COMMANDES_2 (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (p_id_ligne_commande, p_id_commande, p_id_produit, p_quantite, p_remise);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Ligne commande inserted.');

EXCEPTION
    WHEN NOT_VALID THEN 
        DBMS_OUTPUT.PUT_LINE(v_error_msg);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED DATABASE ERROR: ' || SQLERRM);
        ROLLBACK;
END insert_ligne;
/
CREATE OR REPLACE PROCEDURE delete_ligne (
    p_id_ligne_commande IN LIGNES_COMMANDES_2.ID_LIGNE_COMMANDE%TYPE
)
AS
        CURSOR c_commandes(p_id_client COMMANDES_2.ID_CLIENT%TYPE) IS 
        SELECT ID_COMMANDE 
        FROM COMMANDES_2
        WHERE ID_CLIENT = p_id_client;
        
    v_id_client CLIENTS_2.ID_CLIENT%TYPE;
BEGIN
        BEGIN
        SELECT CL.ID_CLIENT INTO v_id_client 
        FROM CLIENTS_2 CL
        INNER JOIN COMMANDES_2 CM ON CM.ID_CLIENT = CL.ID_CLIENT
        INNER JOIN LIGNES_COMMANDES_2 LC ON LC.ID_COMMANDE = CM.ID_COMMANDE
        WHERE LC.ID_LIGNE_COMMANDE = p_id_ligne_commande         FETCH FIRST 1 ROWS ONLY;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: That Ligne Commande ID does not exist.');
            RETURN;     END;

        FOR r_commande IN c_commandes(v_id_client) 
    LOOP
                DELETE FROM LIGNES_COMMANDES_2 WHERE ID_COMMANDE = r_commande.ID_COMMANDE;
        
                DELETE FROM COMMANDES_2 WHERE ID_COMMANDE = r_commande.ID_COMMANDE;
    END LOOP;

    DELETE FROM CLIENTS_2 WHERE ID_CLIENT = v_id_client;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Client and all associated history deleted.');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
        ROLLBACK;
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
    v_error_msg VARCHAR2(200);
    CUSTOM_ERROR EXCEPTION; 
BEGIN
    
    SELECT COUNT(*) INTO nc FROM LIGNES_COMMANDES_2 WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;
    IF nc = 0 THEN
        v_error_msg := 'FAILED: Ligne Commande ID ' || p_id_ligne_commande || ' not found.';
        RAISE CUSTOM_ERROR;
    END IF;

    
    IF p_id_produit IS NOT NULL THEN
        SELECT COUNT(*) INTO nc FROM PRODUITS_2 WHERE ID_PRODUIT = p_id_produit;
        IF nc = 0 THEN
            v_error_msg := 'FAILED: Product ID ' || p_id_produit || ' does not exist in the database.';
            RAISE CUSTOM_ERROR;
        END IF;
    END IF;

    
    
    IF NVL(p_quantite, 1) <= 0 OR NVL(p_remise, 0) < 0 THEN
        v_error_msg := 'FAILED: Quantity must be > 0 and Remise must be >= 0.';
        RAISE CUSTOM_ERROR;
    END IF;

    
    
    
    UPDATE LIGNES_COMMANDES_2 
    SET
        ID_PRODUIT = NVL(p_id_produit, ID_PRODUIT),
        QUANTITE   = NVL(p_quantite, QUANTITE),
        REMISE     = NVL(p_remise, REMISE)
    WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Ligne Commande updated.');

EXCEPTION
    WHEN CUSTOM_ERROR THEN 
        
        DBMS_OUTPUT.PUT_LINE(v_error_msg);
    WHEN OTHERS THEN 
        
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
        ROLLBACK;
END update_ligne;
