-- ============================================================================
-- EShop Distributed Database - Test Script for LIGNES_COMMANDES
-- Run this on: GLOBALE PDB (ESHOP_GLOBALE_PDB) as globale_user
-- Tests: DML operations + trigger synchronization + exceptions (Scenario 1)
-- ============================================================================

ALTER SESSION SET CONTAINER = ESHOP_GLOBALE_PDB;
ALTER SESSION SET CURRENT_SCHEMA = globale_user;
SET SERVEROUTPUT ON;

-- ============================================================================
-- SECTION 0: Setup - Ensure test data exists
-- ============================================================================
PROMPT ===== SECTION 0: SETUP TEST DATA =====

-- Check if we have required reference data
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM CATEGORIES WHERE ID_CATEGORIE = 50;
    IF v_count = 0 THEN
        INSERT INTO CATEGORIES (ID_CATEGORIE, NOM_CATEGORIE) VALUES (50, 'Catégorie Test 50');
        DBMS_OUTPUT.PUT_LINE('Inserted test category 50');
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM CATEGORIES WHERE ID_CATEGORIE = 35;
    IF v_count = 0 THEN
        INSERT INTO CATEGORIES (ID_CATEGORIE, NOM_CATEGORIE) VALUES (35, 'Catégorie Test 35');
        DBMS_OUTPUT.PUT_LINE('Inserted test category 35');
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM FOURNISSEURS WHERE ID_FOURNISSEUR = 9999;
    IF v_count = 0 THEN
        INSERT INTO FOURNISSEURS (ID_FOURNISSEUR, SOCIETE_FOURNISSEUR, CONTACT_FOURNISSEUR, FONCTION_FOURNISSEUR, ADRESSE_FOURNISSEUR, VILLE_FOURNISSEUR, REGION_FOURNISSEUR, CODE_POSTAL_FOURNISSEUR, PAYS_FOURNISSEUR, TEL_FOURNISSEUR, FAX_FOURNISSEUR)
        VALUES (9999, 'Fournisseur Test', 'Contact Test', 'Fonction Test', 'Adresse Test', 'Ville Test', 'Région Test', '12345', 'Pays Test', '0000000000', '0000000001');
        DBMS_OUTPUT.PUT_LINE('Inserted test fournisseur 9999');
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM PRODUITS WHERE ID_PRODUIT = 9999;
    IF v_count = 0 THEN
        INSERT INTO PRODUITS (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE, PRIX_UNITAIRE, UNITES_EN_STOCK, UNITES_COMMANDEES, NIVEAU_REAPPROVISIONNEMENT, INDISPONIBLE)
        VALUES (9999, 'Produit Test Site1', 9999, 50, 100.00, 100, 0, 10, 0);
        DBMS_OUTPUT.PUT_LINE('Inserted test produit 9999 (cat=50)');
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM PRODUITS WHERE ID_PRODUIT = 8888;
    IF v_count = 0 THEN
        INSERT INTO PRODUITS (ID_PRODUIT, DESIGNATION, ID_FOURNISSEUR, ID_CATEGORIE, PRIX_UNITAIRE, UNITES_EN_STOCK, UNITES_COMMANDEES, NIVEAU_REAPPROVISIONNEMENT, INDISPONIBLE)
        VALUES (8888, 'Produit Test Site2', 9999, 35, 50.00, 100, 0, 10, 0);
        DBMS_OUTPUT.PUT_LINE('Inserted test produit 8888 (cat=35)');
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM CLIENTS WHERE ID_CLIENT = 9999;
    IF v_count = 0 THEN
        INSERT INTO CLIENTS (ID_CLIENT, CODE_CLIENT, SOCIETE, CONTACT, FONCTION, ADRESSE, VILLE, DATE_NAISSANCE, REGION, CODE_POSTAL, PAYS, TELEPHONE, FAX)
        VALUES (9999, 'CLT9999', 'Société Test', 'Client Test', 'Fonction Test', 'Adresse Test', 'Ville Test', SYSDATE, 'Région Test', '12345', 'Pays Test', '0000000000', '0000000001');
        DBMS_OUTPUT.PUT_LINE('Inserted test client 9999');
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM EMPLOYES WHERE ID_EMPLOYE = 9999;
    IF v_count = 0 THEN
        INSERT INTO EMPLOYES (ID_EMPLOYE, NOM, PRENOM, FONCTION_EMPLOYE, TITRE_COURTOISIE, DATE_NAISSANCE, DATE_EMBAUCHE, ADRESSE_EMPLOYE, VILLE_EMPLOYE, PAYS_EMPLOYE, TEL_DOMICILE)
        VALUES (9999, 'Employé Test', 'Prénom Test', 'Fonction Test', 'M.', SYSDATE-365, SYSDATE, 'Adresse Test', 'Ville Test', 'Pays Test', '0000000000');
        DBMS_OUTPUT.PUT_LINE('Inserted test employé 9999');
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM COMMANDES WHERE ID_COMMANDE = 9999;
    IF v_count = 0 THEN
        INSERT INTO COMMANDES (ID_COMMANDE, DATE_COMMANDE, ID_CLIENT, ID_EMPLOYE)
        VALUES (9999, SYSDATE, 9999, 9999);
        DBMS_OUTPUT.PUT_LINE('Inserted test commande 9999');
    END IF;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Setup complete.');
END;
/

-- ============================================================================
-- SECTION 1: Test INSERT - Should route to SITE 1 (cat=50, qty>100)
-- ============================================================================
PROMPT ===== SECTION 1: TEST INSERT → SITE 1 =====
PROMPT Testing: cat=50, qty=150 (>100) → Should sync to Site 1

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Inserting ligne with ID=99001, qty=150, produit=9999 (cat=50) ---');
    
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (99001, 9999, 9999, 150, 0.05);
    
    DBMS_OUTPUT.PUT_LINE('INSERT successful on Global DB');
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Checking remote Site 1...');
END;
/

-- Verify on Site 1
SELECT 'SITE_1' AS SITE, ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE
FROM LIGNES_COMMANDES_1@SITE_1
WHERE ID_LIGNE_COMMANDE = 99001;

-- Should NOT exist on Site 2
SELECT 'SITE_2' AS SITE, ID_LIGNE_COMMANDE
FROM LIGNES_COMMANDES_2@SITE_2
WHERE ID_LIGNE_COMMANDE = 99001;

-- ============================================================================
-- SECTION 2: Test INSERT - Should route to SITE 2 (cat=35, qty>50)
-- ============================================================================
PROMPT ===== SECTION 2: TEST INSERT → SITE 2 =====
PROMPT Testing: cat=35, qty=75 (>50) → Should sync to Site 2

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Inserting ligne with ID=99002, qty=75, produit=8888 (cat=35) ---');
    
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (99002, 9999, 8888, 75, 0.10);
    
    DBMS_OUTPUT.PUT_LINE('INSERT successful on Global DB');
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Checking remote Site 2...');
END;
/

-- Verify on Site 2
SELECT 'SITE_2' AS SITE, ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE
FROM LIGNES_COMMANDES_2@SITE_2
WHERE ID_LIGNE_COMMANDE = 99002;

-- Should NOT exist on Site 1
SELECT 'SITE_1' AS SITE, ID_LIGNE_COMMANDE
FROM LIGNES_COMMANDES_1@SITE_1
WHERE ID_LIGNE_COMMANDE = 99002;

-- ============================================================================
-- SECTION 3: Test INSERT - Should NOT route (qty <= 50)
-- ============================================================================
PROMPT ===== SECTION 3: TEST INSERT → NO ROUTING =====
PROMPT Testing: qty=30 (<=50) → Should NOT sync to any site

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Inserting ligne with ID=99003, qty=30 → Should NOT trigger ---');
    
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (99003, 9999, 9999, 30, 0.0);
    
    DBMS_OUTPUT.PUT_LINE('INSERT successful on Global DB');
    
    COMMIT;
END;
/

-- Should NOT exist on either site
SELECT 'SITE_1' AS SITE, COUNT(*) AS COUNT_99003 FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 99003;
SELECT 'SITE_2' AS SITE, COUNT(*) AS COUNT_99003 FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 99003;

-- ============================================================================
-- SECTION 4: Test UPDATE - Stay on same site (Site 1 → Site 1)
-- ============================================================================
PROMPT ===== SECTION 4: TEST UPDATE → SAME SITE =====
PROMPT Testing: Update qty on Site 1 ligne (150 → 200) → Should UPDATE on Site 1

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Updating ligne 99001: qty 150 → 200 ---');
    
    UPDATE LIGNES_COMMANDES
    SET QUANTITE = 200, REMISE = 0.08
    WHERE ID_LIGNE_COMMANDE = 99001;
    
    DBMS_OUTPUT.PUT_LINE('UPDATE successful on Global DB');
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Checking remote Site 1...');
END;
/

-- Verify update on Site 1
SELECT 'SITE_1' AS SITE, ID_LIGNE_COMMANDE, QUANTITE, REMISE
FROM LIGNES_COMMANDES_1@SITE_1
WHERE ID_LIGNE_COMMANDE = 99001;

-- ============================================================================
-- SECTION 5: Test UPDATE - Site transition (Site 1 → Site 2)
-- ============================================================================
PROMPT ===== SECTION 5: TEST UPDATE → SITE TRANSITION =====
PROMPT Testing: Change produit from cat=50 to cat=35 → Should DELETE from Site 1, INSERT to Site 2

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Updating ligne 99001: produit 9999 (cat=50) → 8888 (cat=35) ---');
    
    UPDATE LIGNES_COMMANDES
    SET ID_PRODUIT = 8888, QUANTITE = 80
    WHERE ID_LIGNE_COMMANDE = 99001;
    
    DBMS_OUTPUT.PUT_LINE('UPDATE successful on Global DB');
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Checking both sites...');
END;
/

-- Should NOT exist on Site 1 anymore
SELECT 'SITE_1' AS SITE, COUNT(*) AS COUNT_99001 FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 99001;

-- Should exist on Site 2 now
SELECT 'SITE_2' AS SITE, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE
FROM LIGNES_COMMANDES_2@SITE_2
WHERE ID_LIGNE_COMMANDE = 99001;

-- ============================================================================
-- SECTION 6: Test UPDATE - No longer qualifies (Site 2 → None)
-- ============================================================================
PROMPT ===== SECTION 6: TEST UPDATE → NO LONGER QUALIFIES =====
PROMPT Testing: Reduce qty to 30 (<=50) → Should DELETE from Site 2

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Updating ligne 99001: qty 80 → 30 → Should DELETE from Site 2 ---');
    
    UPDATE LIGNES_COMMANDES
    SET QUANTITE = 30
    WHERE ID_LIGNE_COMMANDE = 99001;
    
    DBMS_OUTPUT.PUT_LINE('UPDATE successful on Global DB');
    
    COMMIT;
END;
/

-- Should NOT exist on either site
SELECT 'SITE_1' AS SITE, COUNT(*) AS COUNT_99001 FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 99001;
SELECT 'SITE_2' AS SITE, COUNT(*) AS COUNT_99001 FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 99001;

-- ============================================================================
-- SECTION 7: Test UPDATE - Newly qualifies (None → Site 1)
-- ============================================================================
PROMPT ===== SECTION 7: TEST UPDATE → NEWLY QUALIFIES =====
PROMPT Testing: Increase qty to 150 with cat=50 → Should INSERT to Site 1

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Updating ligne 99001: qty 30 → 150, produit back to 9999 (cat=50) ---');
    
    UPDATE LIGNES_COMMANDES
    SET ID_PRODUIT = 9999, QUANTITE = 150
    WHERE ID_LIGNE_COMMANDE = 99001;
    
    DBMS_OUTPUT.PUT_LINE('UPDATE successful on Global DB');
    
    COMMIT;
END;
/

-- Should exist on Site 1
SELECT 'SITE_1' AS SITE, ID_LIGNE_COMMANDE, ID_PRODUIT, QUANTITE
FROM LIGNES_COMMANDES_1@SITE_1
WHERE ID_LIGNE_COMMANDE = 99001;

-- ============================================================================
-- SECTION 8: Test DELETE - From Site 1
-- ============================================================================
PROMPT ===== SECTION 8: TEST DELETE FROM SITE 1 =====
PROMPT Testing: Delete ligne 99001 (on Site 1) → Should DELETE from Site 1

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Deleting ligne 99001 (qty=150, cat=50) ---');
    
    DELETE FROM LIGNES_COMMANDES
    WHERE ID_LIGNE_COMMANDE = 99001;
    
    DBMS_OUTPUT.PUT_LINE('DELETE successful on Global DB');
    
    COMMIT;
END;
/

-- Should NOT exist on Site 1
SELECT 'SITE_1' AS SITE, COUNT(*) AS COUNT_99001 FROM LIGNES_COMMANDES_1@SITE_1 WHERE ID_LIGNE_COMMANDE = 99001;

-- ============================================================================
-- SECTION 9: Test DELETE - From Site 2
-- ============================================================================
PROMPT ===== SECTION 9: TEST DELETE FROM SITE 2 =====
PROMPT Testing: Delete ligne 99002 (on Site 2) → Should DELETE from Site 2

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Deleting ligne 99002 (qty=75, cat=35) ---');
    
    DELETE FROM LIGNES_COMMANDES
    WHERE ID_LIGNE_COMMANDE = 99002;
    
    DBMS_OUTPUT.PUT_LINE('DELETE successful on Global DB');
    
    COMMIT;
END;
/

-- Should NOT exist on Site 2
SELECT 'SITE_2' AS SITE, COUNT(*) AS COUNT_99002 FROM LIGNES_COMMANDES_2@SITE_2 WHERE ID_LIGNE_COMMANDE = 99002;

-- ============================================================================
-- SECTION 10: Test EXCEPTIONS - Invalid inputs
-- ============================================================================
PROMPT ===== SECTION 10: TEST EXCEPTIONS =====

-- Test 10a: Negative quantity
PROMPT Test 10a: INSERT with negative quantity → Should fail in procedure
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Inserting with qty=-10 → Expect error ---');
    
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (99010, 9999, 9999, -10, 0.0);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('ERROR: Should have failed but did not!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Test 10b: Zero quantity
PROMPT Test 10b: INSERT with qty=0 → Should fail in procedure
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Inserting with qty=0 → Expect error ---');
    
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (99011, 9999, 9999, 0, 0.0);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('ERROR: Should have failed but did not!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Test 10c: Invalid product ID
PROMPT Test 10c: INSERT with non-existent product → Should handle gracefully
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Inserting with non-existent produit=99999 ---');
    
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (99012, 9999, 99999, 150, 0.0);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Note: Trigger handles NULL category gracefully');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error caught: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Test 10d: Negative remise
PROMPT Test 10d: UPDATE with negative remise → Should fail in procedure
BEGIN
    -- First insert a valid ligne
    INSERT INTO LIGNES_COMMANDES (ID_LIGNE_COMMANDE, ID_COMMANDE, ID_PRODUIT, QUANTITE, REMISE)
    VALUES (99013, 9999, 9999, 150, 0.05);
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('--- Updating with remise=-0.10 → Expect error ---');
    
    UPDATE LIGNES_COMMANDES
    SET REMISE = -0.10
    WHERE ID_LIGNE_COMMANDE = 99013;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('ERROR: Should have failed but did not!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
        ROLLBACK;
END;
/

-- ============================================================================
-- SECTION 11: Cleanup test data
-- ============================================================================
PROMPT ===== SECTION 11: CLEANUP =====

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Cleaning up test data ---');
    
    -- Delete test lignes (child table first)
    DELETE FROM LIGNES_COMMANDES WHERE ID_LIGNE_COMMANDE IN (99001, 99002, 99003, 99010, 99011, 99012, 99013);
    
    -- Delete test commande (after lignes)
    DELETE FROM COMMANDES WHERE ID_COMMANDE = 9999;
    
    -- Delete test produit (before fournisseur/category)
    DELETE FROM PRODUITS WHERE ID_PRODUIT IN (9999, 8888);
    
    -- Delete test client (after commandes)
    DELETE FROM CLIENTS WHERE ID_CLIENT = 9999;
    
    -- Delete test employé (after commandes)
    DELETE FROM EMPLOYES WHERE ID_EMPLOYE = 9999;
    
    -- Delete test fournisseur (after produits)
    DELETE FROM FOURNISSEURS WHERE ID_FOURNISSEUR = 9999;
    
    -- Delete test categories (after produits)
    DELETE FROM CATEGORIES WHERE ID_CATEGORIE IN (50, 35);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Cleanup complete.');
END;
/

PROMPT ===== TEST COMPLETE =====
PROMPT Review the output above to verify:
PROMPT 1. INSERTs routed to correct sites based on category and quantity
PROMPT 2. UPDATEs handled site transitions correctly
PROMPT 3. DELETEs removed data from correct sites
PROMPT 4. Exceptions were caught and handled properly
