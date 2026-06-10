ALTER SESSION SET CONTAINER = ESHOP_GLOBALE_PDB;
ALTER SESSION SET CURRENT_SCHEMA = globale_user;

CREATE OR REPLACE TRIGGER SYC_INSERT_LIGNE
AFTER INSERT ON LIGNES_COMMANDES
FOR EACH ROW
WHEN (NEW.QUANTITE > 50)
DECLARE
    v_id_categorie PRODUITS.ID_CATEGORIE%TYPE;
BEGIN
    BEGIN
        SELECT ID_CATEGORIE INTO v_id_categorie
        FROM PRODUITS
        WHERE ID_PRODUIT = :NEW.ID_PRODUIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_categorie := NULL;
    END;

    IF v_id_categorie = 50 AND :NEW.QUANTITE > 100 THEN
        INSERT_LIGNE@SITE_1(
            p_id_ligne_commande => :NEW.ID_LIGNE_COMMANDE,
            p_id_commande       => :NEW.ID_COMMANDE,
            p_id_produit        => :NEW.ID_PRODUIT,
            p_quantite          => :NEW.QUANTITE,
            p_remise            => :NEW.REMISE
        );
    ELSIF v_id_categorie = 35 AND :NEW.QUANTITE > 50 THEN
        INSERT_LIGNE@SITE_2(
            p_id_ligne_commande => :NEW.ID_LIGNE_COMMANDE,
            p_id_commande       => :NEW.ID_COMMANDE,
            p_id_produit        => :NEW.ID_PRODUIT,
            p_quantite          => :NEW.QUANTITE,
            p_remise            => :NEW.REMISE
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SYC_INSERT_ERROR: ' || SQLERRM);
        RAISE;
END SYC_INSERT_LIGNE;
/
CREATE OR REPLACE TRIGGER SYC_DELETE_LIGNE
AFTER DELETE ON LIGNES_COMMANDES
FOR EACH ROW
WHEN (OLD.QUANTITE > 50)
DECLARE
    v_id_categorie PRODUITS.ID_CATEGORIE%TYPE;
BEGIN
    BEGIN
        SELECT ID_CATEGORIE INTO v_id_categorie
        FROM PRODUITS
        WHERE ID_PRODUIT = :OLD.ID_PRODUIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_categorie := NULL;
    END;

    IF v_id_categorie = 50 AND :OLD.QUANTITE > 100 THEN
        DELETE_LIGNE@SITE_1(
            p_id_ligne_commande => :OLD.ID_LIGNE_COMMANDE
        );
    ELSIF v_id_categorie = 35 AND :OLD.QUANTITE > 50 THEN
        DELETE_LIGNE@SITE_2(
            p_id_ligne_commande => :OLD.ID_LIGNE_COMMANDE
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SYC_DELETE_ERROR: ' || SQLERRM);
        RAISE;
END SYC_DELETE_LIGNE;
/
CREATE OR REPLACE TRIGGER SYC_UPDATE_LIGNE
AFTER UPDATE OF ID_PRODUIT, QUANTITE, REMISE ON LIGNES_COMMANDES
FOR EACH ROW
WHEN (OLD.QUANTITE > 50 OR NEW.QUANTITE > 50)
DECLARE
    v_new_id_categorie PRODUITS.ID_CATEGORIE%TYPE;
    v_old_id_categorie PRODUITS.ID_CATEGORIE%TYPE;
    v_is_qualified_for_site1 BOOLEAN := FALSE;
    v_is_qualified_for_site2 BOOLEAN := FALSE;
    v_was_qualified_for_site1 BOOLEAN := FALSE;
    v_was_qualified_for_site2 BOOLEAN := FALSE;
BEGIN
    -- Get new product category
    BEGIN
        SELECT ID_CATEGORIE INTO v_new_id_categorie
        FROM PRODUITS WHERE ID_PRODUIT = :NEW.ID_PRODUIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_new_id_categorie := NULL;
    END;

    -- Get old product category
    IF :NEW.ID_PRODUIT = :OLD.ID_PRODUIT THEN
        v_old_id_categorie := v_new_id_categorie;
    ELSE
        BEGIN
            SELECT ID_CATEGORIE INTO v_old_id_categorie
            FROM PRODUITS WHERE ID_PRODUIT = :OLD.ID_PRODUIT;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN v_old_id_categorie := NULL;
        END;
    END IF;

    -- Determine qualification for NEW values
    IF (:NEW.QUANTITE > 100 AND v_new_id_categorie = 50) THEN
        v_is_qualified_for_site1 := TRUE;
    END IF;
    IF (:NEW.QUANTITE > 50 AND v_new_id_categorie = 35) THEN
        v_is_qualified_for_site2 := TRUE;
    END IF;

    -- Determine qualification for OLD values
    IF (:OLD.QUANTITE > 100 AND v_old_id_categorie = 50) THEN
        v_was_qualified_for_site1 := TRUE;
    END IF;
    IF (:OLD.QUANTITE > 50 AND v_old_id_categorie = 35) THEN
        v_was_qualified_for_site2 := TRUE;
    END IF;

    -- Handle transitions
    IF v_was_qualified_for_site1 THEN
        IF v_is_qualified_for_site1 THEN
            UPDATE_LIGNE@SITE_1(
                p_id_ligne_commande => :NEW.ID_LIGNE_COMMANDE,
                p_id_produit        => :NEW.ID_PRODUIT,
                p_quantite          => :NEW.QUANTITE,
                p_remise            => :NEW.REMISE
            );
        ELSIF v_is_qualified_for_site2 THEN
            DELETE_LIGNE@SITE_1(p_id_ligne_commande => :OLD.ID_LIGNE_COMMANDE);
            INSERT_LIGNE@SITE_2(
                p_id_ligne_commande => :NEW.ID_LIGNE_COMMANDE,
                p_id_commande       => :NEW.ID_COMMANDE,
                p_id_produit        => :NEW.ID_PRODUIT,
                p_quantite          => :NEW.QUANTITE,
                p_remise            => :NEW.REMISE
            );
        ELSE
            DELETE_LIGNE@SITE_1(p_id_ligne_commande => :OLD.ID_LIGNE_COMMANDE);
        END IF;

    ELSIF v_was_qualified_for_site2 THEN
        IF v_is_qualified_for_site2 THEN
            UPDATE_LIGNE@SITE_2(
                p_id_ligne_commande => :NEW.ID_LIGNE_COMMANDE,
                p_id_produit        => :NEW.ID_PRODUIT,
                p_quantite          => :NEW.QUANTITE,
                p_remise            => :NEW.REMISE
            );
        ELSIF v_is_qualified_for_site1 THEN
            DELETE_LIGNE@SITE_2(p_id_ligne_commande => :OLD.ID_LIGNE_COMMANDE);
            INSERT_LIGNE@SITE_1(
                p_id_ligne_commande => :NEW.ID_LIGNE_COMMANDE,
                p_id_commande       => :NEW.ID_COMMANDE,
                p_id_produit        => :NEW.ID_PRODUIT,
                p_quantite          => :NEW.QUANTITE,
                p_remise            => :NEW.REMISE
            );
        ELSE
            DELETE_LIGNE@SITE_2(p_id_ligne_commande => :OLD.ID_LIGNE_COMMANDE);
        END IF;

    ELSIF v_is_qualified_for_site1 THEN
        INSERT_LIGNE@SITE_1(
            p_id_ligne_commande => :NEW.ID_LIGNE_COMMANDE,
            p_id_commande       => :NEW.ID_COMMANDE,
            p_id_produit        => :NEW.ID_PRODUIT,
            p_quantite          => :NEW.QUANTITE,
            p_remise            => :NEW.REMISE
        );

    ELSIF v_is_qualified_for_site2 THEN
        INSERT_LIGNE@SITE_2(
            p_id_ligne_commande => :NEW.ID_LIGNE_COMMANDE,
            p_id_commande       => :NEW.ID_COMMANDE,
            p_id_produit        => :NEW.ID_PRODUIT,
            p_quantite          => :NEW.QUANTITE,
            p_remise            => :NEW.REMISE
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SYC_UPDATE_ERROR: ' || SQLERRM);
        RAISE;
END SYC_UPDATE_LIGNE;
/
