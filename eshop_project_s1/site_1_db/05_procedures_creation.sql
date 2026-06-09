ALTER SESSION SET CONTAINER = ESHOP_SITE1_PDB;
ALTER SESSION SET CURRENT_SCHEMA = globale_user;

CREATE OR REPLACE PROCEDURE insert_ligne (
    p_id_ligne_commande IN LIGNES_COMMANDES_1.ID_LIGNE_COMMANDE%TYPE,
    p_id_commande       IN LIGNES_COMMANDES_1.ID_COMMANDE%TYPE,
    p_id_produit        IN LIGNES_COMMANDES_1.ID_PRODUIT%TYPE,
    p_quantite          IN LIGNES_COMMANDES_1.QUANTITE%TYPE,
    p_remise            IN LIGNES_COMMANDES_1.REMISE%TYPE
)
AS
    nc INTEGER;
    v_error_msg VARCHAR2(500);
    NOT_VALID EXCEPTION;
    v_id_client COMMANDES_1.ID_CLIENT%TYPE;
    v_id_employe COMMANDES_1.ID_EMPLOYE%TYPE;
    v_id_fournisseur PRODUITS_1.ID_FOURNISSEUR%TYPE;
    v_id_categorie PRODUITS_1.ID_CATEGORIE%TYPE;
BEGIN
    -- 1. Validate inputs
    IF p_quantite <= 0 OR p_remise < 0 OR p_id_ligne_commande <= 0
       OR p_id_commande <= 0 OR p_id_produit <= 0 THEN
        v_error_msg := 'FAILED: One or more numeric inputs are invalid.';
        RAISE NOT_VALID;
    END IF;

    -- 2. Check ligne ID uniqueness
    SELECT COUNT(*) INTO nc FROM LIGNES_COMMANDES_1
    WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;
    IF nc > 0 THEN
        v_error_msg := 'FAILED: ID_LIGNE_COMMANDE already exists.';
        RAISE NOT_VALID;
    END IF;

    -- 3. Ensure Commande exists (auto-insert from global if missing)
    SELECT COUNT(*) INTO nc FROM COMMANDES_1 WHERE ID_COMMANDE = p_id_commande;
    IF nc = 0 THEN
        DECLARE
            v_cmd COMMANDES_G%ROWTYPE;
            v_cl  CLIENTS_G%ROWTYPE;
            v_emp EMPLOYES_G%ROWTYPE;
        BEGIN
            SELECT * INTO v_cmd FROM COMMANDES_G@GLOBALE
            WHERE ID_COMMANDE = p_id_commande;

            -- Ensure Client
            SELECT COUNT(*) INTO nc FROM CLIENTS_1 WHERE ID_CLIENT = v_cmd.ID_CLIENT;
            IF nc = 0 THEN
                SELECT * INTO v_cl FROM CLIENTS_G@GLOBALE
                WHERE ID_CLIENT = v_cmd.ID_CLIENT;
                INSERT INTO CLIENTS_1 VALUES v_cl;
            END IF;

            -- Ensure Employe
            SELECT COUNT(*) INTO nc FROM EMPLOYES_1 WHERE ID_EMPLOYE = v_cmd.ID_EMPLOYE;
            IF nc = 0 THEN
                SELECT * INTO v_emp FROM EMPLOYES_G@GLOBALE
                WHERE ID_EMPLOYE = v_cmd.ID_EMPLOYE;
                INSERT INTO EMPLOYES_1 VALUES v_emp;
            END IF;

            INSERT INTO COMMANDES_1 VALUES v_cmd;
        END;
    END IF;

    -- 4. Ensure Produit exists (auto-insert from global if missing)
    SELECT COUNT(*) INTO nc FROM PRODUITS_1 WHERE ID_PRODUIT = p_id_produit;
    IF nc = 0 THEN
        DECLARE
            v_prod PRODUITS_G%ROWTYPE;
            v_four FOURNISSEURS_G%ROWTYPE;
            v_cat  CATEGORIES_G%ROWTYPE;
        BEGIN
            SELECT * INTO v_prod FROM PRODUITS_G@GLOBALE
            WHERE ID_PRODUIT = p_id_produit;

            -- Ensure Fournisseur
            SELECT COUNT(*) INTO nc FROM FOURNISSEURS_1
            WHERE ID_FOURNISSEUR = v_prod.ID_FOURNISSEUR;
            IF nc = 0 THEN
                SELECT * INTO v_four FROM FOURNISSEURS_G@GLOBALE
                WHERE ID_FOURNISSEUR = v_prod.ID_FOURNISSEUR;
                INSERT INTO FOURNISSEURS_1 VALUES v_four;
            END IF;

            -- Ensure Categorie
            SELECT COUNT(*) INTO nc FROM CATEGORIES_1
            WHERE ID_CATEGORIE = v_prod.ID_CATEGORIE;
            IF nc = 0 THEN
                SELECT * INTO v_cat FROM CATEGORIES_G@GLOBALE
                WHERE ID_CATEGORIE = v_prod.ID_CATEGORIE;
                INSERT INTO CATEGORIES_1 VALUES v_cat;
            END IF;

            INSERT INTO PRODUITS_1 VALUES v_prod;
        END;
    END IF;

    -- 5. Get client ID for the FK
    SELECT ID_CLIENT INTO v_id_client FROM COMMANDES_1
    WHERE ID_COMMANDE = p_id_commande;

    -- 6. Insert the ligne
    INSERT INTO LIGNES_COMMANDES_1
        (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, ID_CLIENT, QUANTITE, REMISE)
    VALUES
        (p_id_ligne_commande, p_id_commande, p_id_produit, v_id_client, p_quantite, p_remise);

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
    p_id_ligne_commande IN LIGNES_COMMANDES_1.ID_LIGNE_COMMANDE%TYPE
)
AS
    v_id_commande COMMANDES_1.ID_COMMANDE%TYPE;
    v_id_client   CLIENTS_1.ID_CLIENT%TYPE;
    nc INTEGER;
BEGIN
    -- 1. Get parent commande ID
    BEGIN
        SELECT ID_COMMANDE INTO v_id_commande
        FROM LIGNES_COMMANDES_1
        WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Ligne Commande ID not found.');
            RETURN;
    END;

    -- 2. Delete the ligne
    DELETE FROM LIGNES_COMMANDES_1 WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;

    -- 3. Check if commande is now orphaned
    SELECT COUNT(*) INTO nc FROM LIGNES_COMMANDES_1
    WHERE ID_COMMANDE = v_id_commande;
    IF nc = 0 THEN
        -- Get client before deleting commande
        SELECT ID_CLIENT INTO v_id_client FROM COMMANDES_1
        WHERE ID_COMMANDE = v_id_commande;

        DELETE FROM COMMANDES_1 WHERE ID_COMMANDE = v_id_commande;

        -- 4. Check if client is now orphaned
        SELECT COUNT(*) INTO nc FROM COMMANDES_1
        WHERE ID_CLIENT = v_id_client;
        IF nc = 0 THEN
            DELETE FROM CLIENTS_1 WHERE ID_CLIENT = v_id_client;
        END IF;
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Ligne commande deleted.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
        ROLLBACK;
END delete_ligne;
/
CREATE OR REPLACE PROCEDURE update_ligne (
    p_id_ligne_commande IN LIGNES_COMMANDES_1.ID_LIGNE_COMMANDE%TYPE,
    p_id_produit        IN LIGNES_COMMANDES_1.ID_PRODUIT%TYPE DEFAULT NULL,
    p_quantite          IN LIGNES_COMMANDES_1.QUANTITE%TYPE DEFAULT NULL,
    p_remise            IN LIGNES_COMMANDES_1.REMISE%TYPE DEFAULT NULL
)
AS
    nc INTEGER;
    v_old_id_produit PRODUITS_1.ID_PRODUIT%TYPE;
    v_new_id_produit PRODUITS_1.ID_PRODUIT%TYPE;
    v_error_msg VARCHAR2(500);
    CUSTOM_ERROR EXCEPTION;
BEGIN
    -- 1. Check ligne exists and get old product
    BEGIN
        SELECT ID_PRODUIT INTO v_old_id_produit
        FROM LIGNES_COMMANDES_1
        WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_error_msg := 'FAILED: Ligne Commande ID not found.';
            RAISE CUSTOM_ERROR;
    END;

    v_new_id_produit := NVL(p_id_produit, v_old_id_produit);

    -- 2. Ensure new product exists (auto-insert if missing)
    IF p_id_produit IS NOT NULL THEN
        SELECT COUNT(*) INTO nc FROM PRODUITS_1 WHERE ID_PRODUIT = p_id_produit;
        IF nc = 0 THEN
            DECLARE
                v_prod PRODUITS_G%ROWTYPE;
                v_four FOURNISSEURS_G%ROWTYPE;
                v_cat  CATEGORIES_G%ROWTYPE;
            BEGIN
                SELECT * INTO v_prod FROM PRODUITS_G@GLOBALE
                WHERE ID_PRODUIT = p_id_produit;

                SELECT COUNT(*) INTO nc FROM FOURNISSEURS_1
                WHERE ID_FOURNISSEUR = v_prod.ID_FOURNISSEUR;
                IF nc = 0 THEN
                    SELECT * INTO v_four FROM FOURNISSEURS_G@GLOBALE
                    WHERE ID_FOURNISSEUR = v_prod.ID_FOURNISSEUR;
                    INSERT INTO FOURNISSEURS_1 VALUES v_four;
                END IF;

                SELECT COUNT(*) INTO nc FROM CATEGORIES_1
                WHERE ID_CATEGORIE = v_prod.ID_CATEGORIE;
                IF nc = 0 THEN
                    SELECT * INTO v_cat FROM CATEGORIES_G@GLOBALE
                    WHERE ID_CATEGORIE = v_prod.ID_CATEGORIE;
                    INSERT INTO CATEGORIES_1 VALUES v_cat;
                END IF;

                INSERT INTO PRODUITS_1 VALUES v_prod;
            END;
        END IF;
    END IF;

    -- 3. Validate values
    IF NVL(p_quantite, 1) <= 0 OR NVL(p_remise, 0) < 0 THEN
        v_error_msg := 'FAILED: Quantity must be > 0 and Remise must be >= 0.';
        RAISE CUSTOM_ERROR;
    END IF;

    -- 4. Update
    UPDATE LIGNES_COMMANDES_1
    SET ID_PRODUIT = v_new_id_produit,
        QUANTITE   = NVL(p_quantite, QUANTITE),
        REMISE     = NVL(p_remise, REMISE)
    WHERE ID_LIGNE_COMMANDE = p_id_ligne_commande;

    -- 5. Clean up old product if no longer referenced
    IF v_old_id_produit != v_new_id_produit THEN
        SELECT COUNT(*) INTO nc FROM LIGNES_COMMANDES_1
        WHERE ID_PRODUIT = v_old_id_produit;
        IF nc = 0 THEN
            DELETE FROM PRODUITS_1 WHERE ID_PRODUIT = v_old_id_produit;
        END IF;
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Ligne Commande updated.');

EXCEPTION
    WHEN CUSTOM_ERROR THEN
        DBMS_OUTPUT.PUT_LINE(v_error_msg);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
        ROLLBACK;
END update_ligne;
/
