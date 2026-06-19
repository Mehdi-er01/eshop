-- ============================================================================
-- E-Shop Distributed Database Demonstration Script
-- RUN THIS IN: Oracle SQL Developer
-- CONNECTION: globale_user@//localhost:1521/ESHOP_GLOBALE_PDB
-- ============================================================================

-- Execute this first to ensure output prints to the Script Output console
SET SERVEROUTPUT ON;

-- ============================================================================
-- STEP 1: VERIFY CONNECTIVITY AND DATABASE LINKS
-- ============================================================================
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS CURRENT_CONTAINER FROM DUAL;
SELECT 'Connexion à Site 1 réussie!' AS STATUT FROM DUAL@SITE_1;
SELECT 'Connexion à Site 2 réussie!' AS STATUT FROM DUAL@SITE_2;

-- ============================================================================
-- STEP 2: PREPARE TEST DATA (Parent tables)
-- Highlight and run this entire block.
-- ============================================================================
BEGIN
    -- Cleanup just in case (Delete children first, then parents)
    DELETE FROM LIGNES_COMMANDES WHERE ID_COMMANDE = 9999 OR ID_PRODUIT IN (9999, 8888);
    DELETE FROM COMMANDES WHERE ID_COMMANDE = 9999 OR ID_CLIENT = 9999 OR ID_EMPLOYE = 9999;
    DELETE FROM PRODUITS WHERE ID_PRODUIT IN (9999, 8888) OR ID_FOURNISSEUR = 9999;
    DELETE FROM CLIENTS WHERE ID_CLIENT = 9999;
    DELETE FROM EMPLOYES WHERE ID_EMPLOYE = 9999;
    DELETE FROM FOURNISSEURS WHERE ID_FOURNISSEUR = 9999;
    
    -- Insert Data
    INSERT INTO FOURNISSEURS (ID_FOURNISSEUR, SOCIETE_FOURNISSEUR, CONTACT_FOURNISSEUR, FONCTION_FOURNISSEUR) 
    VALUES (9999, 'Fournisseur Demo', 'Contact', 'Fonction');
    
    INSERT INTO PRODUITS (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE) 
    VALUES (9999, 'Produit Site 1 (Cat 50)', 9999, 50);
    
    INSERT INTO PRODUITS (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE) 
    VALUES (8888, 'Produit Site 2 (Cat 35)', 9999, 35);
    
    INSERT INTO CLIENTS (ID_CLIENT, CODE_CLIENT, SOCIETE, CONTACT, FONCTION) 
    VALUES (9999, 'C99', 'Société', 'Contact', 'Fonction');
    
    INSERT INTO EMPLOYES (ID_EMPLOYE, NOM, PRENOM) 
    VALUES (9999, 'Nom', 'Prenom');
    
    INSERT INTO COMMANDES (ID_COMMANDE, ID_EMPLOYE, ID_CLIENT, DATE_COMMANDE) 
    VALUES (9999, 9999, 9999, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Données de préparation insérées avec succès.');
END;
/

-- ============================================================================
-- STEP 3: TEST INSERT -> SITE 1 & SITE 2 & NO ROUTING
-- ============================================================================
-- INSERT for Site 1 (Cat 50, Qty 150)
INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE) 
VALUES (99001, 9999, 9999, 150, 0.05);

-- INSERT for Site 2 (Cat 35, Qty 75)
INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE) 
VALUES (99002, 9999, 8888, 75, 0.10);

-- INSERT No Routing (Cat 50, Qty 30 <= 50)
INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE) 
VALUES (99003, 9999, 9999, 30, 0.0);

COMMIT;

-- VERIFY INSERTS
SELECT 'GLOBAL' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES WHERE ID_LIGNE_COMMANDE IN (99001, 99002, 99003);
SELECT 'SITE_1' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES_1 WHERE ID_LIGNE_COMMANDE IN (99001, 99002, 99003);
SELECT 'SITE_2' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES_2 WHERE ID_LIGNE_COMMANDE IN (99001, 99002, 99003);

-- ============================================================================
-- STEP 4: TEST UPDATE -> SAME SITE
-- Update qty on Site 1 ligne (150 -> 200) -> Should stay on Site 1
-- ============================================================================
UPDATE LIGNES_COMMANDES SET QUANTITE = 200, REMISE = 0.08 WHERE ID_LIGNE_COMMANDE = 99001;
COMMIT;

SELECT 'SITE_1_AFTER_UPDATE' AS DB, ID_LIGNE_COMMANDE, QUANTITE FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 99001;

-- ============================================================================
-- STEP 5: TEST UPDATE -> SITE TRANSITION
-- Change produit 9999 (cat=50) -> 8888 (cat=35), qty 200 -> 80
-- Should DELETE from Site 1, INSERT to Site 2
-- ============================================================================
UPDATE LIGNES_COMMANDES SET ID_PRODUIT = 8888, QUANTITE = 80 WHERE ID_LIGNE_COMMANDE = 99001;
COMMIT;

SELECT 'SITE_1_DELETED' AS DB, COUNT(*) AS NB FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 99001;
SELECT 'SITE_2_INSERTED' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 99001;

-- ============================================================================
-- STEP 6: TEST UPDATE -> NO LONGER QUALIFIES
-- Reduce qty 80 -> 30 (<=50). Should DELETE from Site 2.
-- ============================================================================
UPDATE LIGNES_COMMANDES SET QUANTITE = 30 WHERE ID_LIGNE_COMMANDE = 99001;
COMMIT;

SELECT 'SITE_2_DELETED' AS DB, COUNT(*) AS NB FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 99001;

select * from lignes_commandes lc
join produits p 
on lc.id_produit = p.id_produit
where id_ligne_commande=99001;
select * from lignes_commandes_1 where id_ligne_commande=99001;
select * from lignes_commandes_2 where id_ligne_commande=99001;

-- ============================================================================
-- STEP 7: TEST UPDATEsel -> NEWLY QUALIFIES
-- Ligne 99003 is currently Unrouted (Qty=30). Let's increase it to 150.
-- Should INSERT to Site 1
-- ============================================================================
UPDATE LIGNES_COMMANDES SET QUANTITE = 150 WHERE ID_LIGNE_COMMANDE = 99003;
COMMIT;

SELECT 'SITE_1_NEWLY_INSERTED' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 99003;

-- ============================================================================
-- STEP 8: TEST DELETE -> FROM SITE 1
-- Delete ligne 99003 (currently on Site 1) -> Should DELETE from Site 1
-- ============================================================================
DELETE FROM LIGNES_COMMANDES WHERE ID_LIGNE_COMMANDE = 99003;
COMMIT;

SELECT 'SITE_1_AFTER_DELETE' AS DB, COUNT(*) AS NB FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 99003;

-- ============================================================================
-- STEP 9: TEST DELETE -> FROM SITE 2
-- Delete ligne 99002 (currently on Site 2) -> Should DELETE from Site 2
-- ============================================================================
DELETE FROM LIGNES_COMMANDES WHERE ID_LIGNE_COMMANDE = 99002;
COMMIT;

SELECT 'SITE_2_AFTER_DELETE' AS DB, COUNT(*) AS NB FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 99002;

-- ============================================================================
-- STEP 10: TEST EXCEPTIONS (Déclenchement des exceptions personnalisées)
-- Ces tests ciblent spécifiquement les exceptions que VOUS avez créées 
-- dans les procédures (NOT_VALID, CUSTOM_ERROR, NO_DATA_FOUND).
-- ============================================================================

-- 10.1: Test de NOT_VALID dans insert_ligne (Valeur invalide)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 10.1: NOT_VALID Exception (Quantité Négative) ---');
    insert_ligne@SITE_1(
        p_id_ligne_commande => 99010,
        p_id_commande       => 9999,
        p_id_produit        => 9999,
        p_quantite          => -10,  -- Déclenche: p_quantite <= 0
        p_remise            => 0
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 10.2: Test de NOT_VALID dans insert_ligne (ID Déjà Existant)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 10.2: NOT_VALID Exception (ID Déjà Existant) ---');
    -- Insertion préalable réussie
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE) 
    VALUES (99011, 9999, 9999, 150, 0.0);
    COMMIT;
    
    -- Appel direct avec le même ID
    insert_ligne@SITE_1(
        p_id_ligne_commande => 99011, -- Déclenche: ID_LIGNE_COMMANDE already exists
        p_id_commande       => 9999,
        p_id_produit        => 9999,
        p_quantite          => 150,
        p_remise            => 0
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 10.3: Test de NO_DATA_FOUND dans delete_ligne
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 10.3: NO_DATA_FOUND dans delete_ligne ---');
    -- Appel direct pour supprimer une ligne qui n'existe pas
    delete_ligne@SITE_1(
        p_id_ligne_commande => 999999 -- N'existe pas
    );
    -- delete_ligne gère l'erreur en interne et fait un RETURN sans crasher
    DBMS_OUTPUT.PUT_LINE('SUCCÈS : La procédure a géré l''erreur sans crasher.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERREUR INATTENDUE : ' || SQLERRM);
END;
/

-- 10.4: Test de CUSTOM_ERROR (via NO_DATA_FOUND) dans update_ligne
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 10.4: CUSTOM_ERROR (ID non trouvé) dans update_ligne ---');
    -- Appel direct pour mettre à jour une ligne qui n'existe pas
    update_ligne@SITE_1(
        p_id_ligne_commande => 999999, -- N'existe pas
        p_quantite          => 100
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 10.5: Test de CUSTOM_ERROR (Remise Négative) dans update_ligne
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 10.5: CUSTOM_ERROR Exception (Remise Négative) ---');
    -- Met à jour la ligne insérée au test 10.2 via le trigger global
    UPDATE LIGNES_COMMANDES SET REMISE = -0.10 WHERE ID_LIGNE_COMMANDE = 99011;
    COMMIT;
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
    ROLLBACK;
END;
/

-- ============================================================================
-- STEP 11: CLEANUP
-- ============================================================================
BEGIN
    -- Cleanup (Delete children first, then parents)
    DELETE FROM LIGNES_COMMANDES WHERE ID_COMMANDE = 9999 OR ID_PRODUIT IN (9999, 8888);
    DELETE FROM COMMANDES WHERE ID_COMMANDE = 9999 OR ID_CLIENT = 9999 OR ID_EMPLOYE = 9999;
    DELETE FROM PRODUITS WHERE ID_PRODUIT IN (9999, 8888) OR ID_FOURNISSEUR = 9999;
    DELETE FROM CLIENTS WHERE ID_CLIENT = 9999;
    DELETE FROM EMPLOYES WHERE ID_EMPLOYE = 9999;
    DELETE FROM FOURNISSEURS WHERE ID_FOURNISSEUR = 9999;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Base de données nettoyée avec succès.');
END;
/
