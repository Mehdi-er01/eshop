-- ============================================================================
-- E-Shop Distributed Database — SCENARIO 2 Demonstration Script
-- Fragmentation by VOLUME: Site 1 (qty >= 100) / Site 2 (qty < 100)
-- RUN THIS IN: Oracle SQL Developer
-- CONNECTION: globale_user@//localhost:1524/ESHOP_GLOBALE_PDB
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
-- STEP 2: PREPARE TEST DATA — Global parent tables + Site-level reference data
-- In Scenario 2, the site procedures DO NOT auto-insert missing references.
-- We must manually populate COMMANDES and PRODUITS on the target sites.
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
    
    -- ==============================
    -- A) Insert on GLOBAL DB
    -- ==============================
    INSERT INTO FOURNISSEURS (ID_FOURNISSEUR, SOCIETE_FOURNISSEUR, CONTACT_FOURNISSEUR, FONCTION_FOURNISSEUR) 
    VALUES (9999, 'Fournisseur Demo S2', 'Contact Demo', 'Directeur');
    
    INSERT INTO CATEGORIES (ID_CATEGORIE, NOM_CATEGORIE) 
    VALUES (77, 'Catégorie Test S2');
    
    INSERT INTO PRODUITS (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE, PRIX_UNITAIRE) 
    VALUES (9999, 'Produit Gros Volume', 9999, 77, 25.50);
    
    INSERT INTO PRODUITS (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE, PRIX_UNITAIRE) 
    VALUES (8888, 'Produit Petit Volume', 9999, 77, 10.00);
    
    INSERT INTO CLIENTS (ID_CLIENT, CODE_CLIENT, SOCIETE, CONTACT, FONCTION) 
    VALUES (9999, 'C99', 'Société Demo S2', 'Contact Demo', 'Gérant');
    
    INSERT INTO EMPLOYES (ID_EMPLOYE, NOM, PRENOM) 
    VALUES (9999, 'Dupont', 'Jean');
    
    INSERT INTO COMMANDES (ID_COMMANDE, ID_EMPLOYE, ID_CLIENT, DATE_COMMANDE) 
    VALUES (9999, 9999, 9999, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== A) Données GLOBALES insérées avec succès. ===');

    -- ==============================
    -- B) Replicate references to SITE 1 (via DB Link)
    --    Site 1 = Gros volumes (qty >= 100)
    -- ==============================
    INSERT INTO FOURNISSEURS_1@SITE_1 (ID_FOURNISSEUR, SOCIETE_FOURNISSEUR, CONTACT_FOURNISSEUR, FONCTION_FOURNISSEUR) 
    VALUES (9999, 'Fournisseur Demo S2', 'Contact Demo', 'Directeur');
    
    INSERT INTO CATEGORIES_1@SITE_1 (ID_CATEGORIE, NOM_CATEGORIE) 
    VALUES (77, 'Catégorie Test S2');
    
    INSERT INTO PRODUITS_1@SITE_1 (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE, PRIX_UNITAIRE) 
    VALUES (9999, 'Produit Gros Volume', 9999, 77, 25.50);
    
    INSERT INTO PRODUITS_1@SITE_1 (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE, PRIX_UNITAIRE) 
    VALUES (8888, 'Produit Petit Volume', 9999, 77, 10.00);
    
    INSERT INTO EMPLOYES_1@SITE_1 (ID_EMPLOYE, NOM, PRENOM) 
    VALUES (9999, 'Dupont', 'Jean');
    
    INSERT INTO CLIENTS_1@SITE_1 (ID_CLIENT, CODE_CLIENT, SOCIETE, CONTACT, FONCTION) 
    VALUES (9999, 'C99', 'Société Demo S2', 'Contact Demo', 'Gérant');
    
    INSERT INTO COMMANDES_1@SITE_1 (ID_COMMANDE, ID_EMPLOYE, ID_CLIENT, DATE_COMMANDE) 
    VALUES (9999, 9999, 9999, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== B) Références SITE 1 insérées avec succès. ===');

    -- ==============================
    -- C) Replicate references to SITE 2 (via DB Link)
    --    Site 2 = Petits volumes (qty < 100)
    -- ==============================
    INSERT INTO FOURNISSEURS_2@SITE_2 (ID_FOURNISSEUR, SOCIETE_FOURNISSEUR, CONTACT_FOURNISSEUR, FONCTION_FOURNISSEUR) 
    VALUES (9999, 'Fournisseur Demo S2', 'Contact Demo', 'Directeur');
    
    INSERT INTO CATEGORIES_2@SITE_2 (ID_CATEGORIE, NOM_CATEGORIE) 
    VALUES (77, 'Catégorie Test S2');
    
    INSERT INTO PRODUITS_2@SITE_2 (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE, PRIX_UNITAIRE) 
    VALUES (9999, 'Produit Gros Volume', 9999, 77, 25.50);
    
    INSERT INTO PRODUITS_2@SITE_2 (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE, PRIX_UNITAIRE) 
    VALUES (8888, 'Produit Petit Volume', 9999, 77, 10.00);
    
    INSERT INTO EMPLOYES_2@SITE_2 (ID_EMPLOYE, NOM, PRENOM) 
    VALUES (9999, 'Dupont', 'Jean');
    
    INSERT INTO CLIENTS_2@SITE_2 (ID_CLIENT, CODE_CLIENT, SOCIETE, CONTACT, FONCTION) 
    VALUES (9999, 'C99', 'Société Demo S2', 'Contact Demo', 'Gérant');
    
    INSERT INTO COMMANDES_2@SITE_2 (ID_COMMANDE, ID_EMPLOYE, ID_CLIENT, DATE_COMMANDE) 
    VALUES (9999, 9999, 9999, SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== C) Références SITE 2 insérées avec succès. ===');
END;
/

-- ============================================================================
-- STEP 3: TEST INSERT → SITE 1 (qty >= 100) & SITE 2 (qty < 100)
-- ============================================================================
-- 3.1: INSERT for Site 1 — Gros Volume (Qty = 150 >= 100)
INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE) 
VALUES (88001, 9999, 9999, 150, 0.05);
COMMIT;

-- 3.2: INSERT for Site 2 — Petit Volume (Qty = 75 < 100)
INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE) 
VALUES (88002, 9999, 8888, 75, 0.10);
COMMIT;

-- VERIFY: Both inserts routed correctly
SELECT 'GLOBAL' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES WHERE ID_LIGNE_COMMANDE IN (88001, 88002);
SELECT 'SITE_1' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES_1 WHERE ID_LIGNE_COMMANDE IN (88001, 88002);
SELECT 'SITE_2' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES_2 WHERE ID_LIGNE_COMMANDE IN (88001, 88002);
-- Expected: 88001 on SITE_1, 88002 on SITE_2

-- ============================================================================
-- STEP 4: TEST UPDATE → SAME SITE (qty stays in same range)
-- Update qty on Site 1 ligne (150 -> 200) → Still >= 100, stays on Site 1
-- ============================================================================
UPDATE LIGNES_COMMANDES SET QUANTITE = 200, REMISE = 0.08 WHERE ID_LIGNE_COMMANDE = 88001;
COMMIT;

SELECT 'SITE_1_AFTER_UPDATE' AS DB, ID_LIGNE_COMMANDE, QUANTITE, REMISE FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 88001;
-- Expected: qty=200, remise=0.08

-- ============================================================================
-- STEP 5: TEST UPDATE → SITE TRANSITION (Site 1 → Site 2)
-- Reduce qty 200 → 80 (< 100)
-- Should DELETE from Site 1, INSERT to Site 2
-- ============================================================================
UPDATE LIGNES_COMMANDES SET QUANTITE = 80 WHERE ID_LIGNE_COMMANDE = 88001;
COMMIT;

SELECT 'SITE_1_DELETED' AS DB, COUNT(*) AS NB FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 88001;
SELECT 'SITE_2_INSERTED' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 88001;
-- Expected: SITE_1 count=0, SITE_2 has 88001 with qty=80

-- ============================================================================
-- STEP 6: TEST UPDATE → SITE TRANSITION (Site 2 → Site 1)
-- Increase qty 80 → 120 (>= 100)
-- Should DELETE from Site 2, INSERT to Site 1
-- ============================================================================
UPDATE LIGNES_COMMANDES SET QUANTITE = 120 WHERE ID_LIGNE_COMMANDE = 88001;
COMMIT;

SELECT 'SITE_2_DELETED' AS DB, COUNT(*) AS NB FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 88001;
SELECT 'SITE_1_REINSERTED' AS DB, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 88001;
-- Expected: SITE_2 count=0, SITE_1 has 88001 with qty=120

-- Verify current state
SELECT * FROM LIGNES_COMMANDES WHERE ID_LIGNE_COMMANDE IN (88001, 88002);
SELECT * FROM LIGNES_COMMANDES_1 WHERE ID_LIGNE_COMMANDE IN (88001, 88002);
SELECT * FROM LIGNES_COMMANDES_2 WHERE ID_LIGNE_COMMANDE IN (88001, 88002);

-- ============================================================================
-- STEP 7: TEST DELETE → FROM SITE 1
-- Delete ligne 88001 (currently on Site 1, qty=120) → Should DELETE from Site 1
-- ============================================================================
DELETE FROM LIGNES_COMMANDES WHERE ID_LIGNE_COMMANDE = 88001;
COMMIT;

SELECT 'SITE_1_AFTER_DELETE' AS DB, COUNT(*) AS NB FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 88001;
-- Expected: count=0

-- ============================================================================
-- STEP 8: TEST DELETE → FROM SITE 2
-- Delete ligne 88002 (currently on Site 2, qty=75) → Should DELETE from Site 2
-- ============================================================================
DELETE FROM LIGNES_COMMANDES WHERE ID_LIGNE_COMMANDE = 88002;
COMMIT;

SELECT 'SITE_2_AFTER_DELETE' AS DB, COUNT(*) AS NB FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 88002;
-- Expected: count=0

-- ============================================================================
-- STEP 9: TEST EXCEPTIONS (Déclenchement des exceptions personnalisées)
-- Ces tests ciblent les exceptions définies dans les procédures S2 :
-- -20001: Invalid numeric inputs
-- -20002: ID_LIGNE_COMMANDE already exists
-- -20003: ID_COMMANDE does not exist
-- -20004: ID_PRODUIT does not exist
-- -20005: Ligne Commande ID does not exist (delete)
-- -20006: Ligne Commande ID not found (update)
-- -20008: Quantity must be > 0 and Remise must be >= 0
-- ============================================================================

-- 9.1: Test -20001 (Invalid Input: Quantité Négative)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.1: Invalid Input (Quantité Négative) ---');
    insert_ligne@SITE_1(
        p_id_ligne_commande => 88010,
        p_id_commande       => 9999,
        p_id_produit        => 9999,
        p_quantite          => -10,  -- Déclenche: p_quantite <= 0
        p_remise            => 0
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 9.2: Test -20002 (ID Déjà Existant)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.2: ID_LIGNE_COMMANDE Already Exists ---');
    -- First, insert a ligne on Site 1
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE) 
    VALUES (88011, 9999, 9999, 150, 0.0);
    COMMIT;
    
    -- Now try to insert the same ID directly via the procedure
    insert_ligne@SITE_1(
        p_id_ligne_commande => 88011, -- Already exists on Site 1
        p_id_commande       => 9999,
        p_id_produit        => 9999,
        p_quantite          => 150,
        p_remise            => 0
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 9.3: Test -20003 (ID_COMMANDE Does Not Exist)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.3: ID_COMMANDE Does Not Exist ---');
    insert_ligne@SITE_1(
        p_id_ligne_commande => 88012,
        p_id_commande       => 77777, -- Does not exist
        p_id_produit        => 9999,
        p_quantite          => 120,
        p_remise            => 0
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 9.4: Test -20004 (ID_PRODUIT Does Not Exist)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.4: ID_PRODUIT Does Not Exist ---');
    insert_ligne@SITE_1(
        p_id_ligne_commande => 88013,
        p_id_commande       => 9999,
        p_id_produit        => 77777, -- Does not exist
        p_quantite          => 120,
        p_remise            => 0
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 9.5: Test -20005 (Delete: Ligne Not Found)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.5: Delete Non-Existent Ligne ---');
    delete_ligne@SITE_1(
        p_id_ligne_commande => 999999 -- N'existe pas
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 9.6: Test -20006 (Update: Ligne Not Found)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.6: Update Non-Existent Ligne ---');
    update_ligne@SITE_1(
        p_id_ligne_commande => 999999, -- N'existe pas
        p_quantite          => 100
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 9.7: Test -20008 (Update: Remise Négative)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.7: Update with Negative Remise ---');
    -- Ligne 88011 is on Site 1 (qty=150)
    update_ligne@SITE_1(
        p_id_ligne_commande => 88011,
        p_remise            => -0.10 -- Déclenche: remise < 0
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- 9.8: Test -20007 (Update: Product ID Does Not Exist)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test 9.8: Update with Non-Existent Product ---');
    update_ligne@SITE_1(
        p_id_ligne_commande => 88011,
        p_id_produit        => 77777 -- Does not exist
    );
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SUCCÈS - ERREUR CAPTURÉE : ' || SQLERRM);
END;
/

-- ============================================================================
-- STEP 10: CLEANUP
-- ============================================================================
BEGIN
    -- Cleanup Global (Delete children first, then parents)
    DELETE FROM LIGNES_COMMANDES WHERE ID_COMMANDE = 9999 OR ID_PRODUIT IN (9999, 8888);
    DELETE FROM COMMANDES WHERE ID_COMMANDE = 9999 OR ID_CLIENT = 9999 OR ID_EMPLOYE = 9999;
    DELETE FROM PRODUITS WHERE ID_PRODUIT IN (9999, 8888) OR ID_FOURNISSEUR = 9999;
    DELETE FROM CATEGORIES WHERE ID_CATEGORIE = 77;
    DELETE FROM CLIENTS WHERE ID_CLIENT = 9999;
    DELETE FROM EMPLOYES WHERE ID_EMPLOYE = 9999;
    DELETE FROM FOURNISSEURS WHERE ID_FOURNISSEUR = 9999;
    
    -- Cleanup Site 1
    DELETE FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_COMMANDE = 9999;
    DELETE FROM COMMANDES_1@SITE_1 WHERE ID_COMMANDE = 9999;
    DELETE FROM PRODUITS_1@SITE_1 WHERE ID_PRODUIT IN (9999, 8888);
    DELETE FROM CATEGORIES_1@SITE_1 WHERE ID_CATEGORIE = 77;
    DELETE FROM CLIENTS_1@SITE_1 WHERE ID_CLIENT = 9999;
    DELETE FROM EMPLOYES_1@SITE_1 WHERE ID_EMPLOYE = 9999;
    DELETE FROM FOURNISSEURS_1@SITE_1 WHERE ID_FOURNISSEUR = 9999;
    
    -- Cleanup Site 2
    DELETE FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_COMMANDE = 9999;
    DELETE FROM COMMANDES_2@SITE_2 WHERE ID_COMMANDE = 9999;
    DELETE FROM PRODUITS_2@SITE_2 WHERE ID_PRODUIT IN (9999, 8888);
    DELETE FROM CATEGORIES_2@SITE_2 WHERE ID_CATEGORIE = 77;
    DELETE FROM CLIENTS_2@SITE_2 WHERE ID_CLIENT = 9999;
    DELETE FROM EMPLOYES_2@SITE_2 WHERE ID_EMPLOYE = 9999;
    DELETE FROM FOURNISSEURS_2@SITE_2 WHERE ID_FOURNISSEUR = 9999;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Base de données nettoyée avec succès (Global + Site 1 + Site 2).');
END;
/
