-- =========================================================================
-- PROJET BDD REPARTIES - SCENARIO 2 - REQUETES ET OPTIMISATION
-- =========================================================================

ALTER SESSION SET CONTAINER = ESHOP_GLOBALE_PDB;
ALTER SESSION SET CURRENT_SCHEMA = globale_user;

-- =========================================================================
-- QUESTION 1 : Nombre de commandes par client réalisées en 2026 (BDD Globale)
-- =========================================================================
-- Nous utilisons un filtrage par plage de dates (>= 01-Jan-2026 et < 01-Jan-2027) 
-- plutôt que la fonction EXTRACT(YEAR FROM DATE_COMMANDE) afin de permettre à 
-- Oracle d'utiliser un éventuel index B-Tree standard sur la colonne DATE_COMMANDE.

SELECT 
    c.ID_CLIENT, 
    cl.SOCIETE, 
    COUNT(c.ID_COMMANDE) AS NB_COMMANDES
FROM COMMANDES c
JOIN CLIENTS cl ON c.ID_CLIENT = cl.ID_CLIENT
WHERE c.DATE_COMMANDE >= TO_DATE('2026-01-01', 'YYYY-MM-DD')
  AND c.DATE_COMMANDE < TO_DATE('2027-01-01', 'YYYY-MM-DD')
GROUP BY c.ID_CLIENT, cl.SOCIETE
ORDER BY NB_COMMANDES DESC;


-- =========================================================================
-- QUESTION 2 : Génération et analyse du Plan d'Exécution
-- =========================================================================

EXPLAIN PLAN FOR
SELECT 
    c.ID_CLIENT, 
    cl.SOCIETE, 
    COUNT(c.ID_COMMANDE) AS NB_COMMANDES
FROM COMMANDES c
JOIN CLIENTS cl ON c.ID_CLIENT = cl.ID_CLIENT
WHERE c.DATE_COMMANDE >= TO_DATE('2026-01-01', 'YYYY-MM-DD')
  AND c.DATE_COMMANDE < TO_DATE('2027-01-01', 'YYYY-MM-DD')
GROUP BY c.ID_CLIENT, cl.SOCIETE;

-- Affichage du plan d'exécution :
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
ANALYSE DES OPERATIONS COUTEUSES :
1. FULL TABLE SCAN (FTS) sur la table 'COMMANDES' : Comme il n'y a pas d'index initial 
   sur DATE_COMMANDE, Oracle doit scanner l'intégralité de la table COMMANDES pour filtrer 
   les lignes de 2026.
2. HASH JOIN / MERGE JOIN : Le rapprochement entre CLIENTS et COMMANDES se fera par un HASH JOIN 
   coûteux en mémoire si les volumes sont importants, en particulier sans index sur la clé 
   étrangère ID_CLIENT de la table COMMANDES.
3. HASH GROUP BY : L'opération de regroupement (GROUP BY) nécessite un tri et un hachage en 
   mémoire (ou temporaire sur disque si la mémoire PGA est insuffisante).
*/


-- =========================================================================
-- QUESTION 3 : Création d'index pour optimiser les performances
-- =========================================================================

-- 1. Index sur la date de commande (permet un INDEX RANGE SCAN pour isoler l'année 2026)
CREATE INDEX IDX_COMMANDES_DATE ON COMMANDES(DATE_COMMANDE);

-- 2. Index sur la clé étrangère ID_CLIENT (optimise la jointure avec la table CLIENTS)
CREATE INDEX IDX_COMMANDES_CLIENT ON COMMANDES(ID_CLIENT);

/*
JUSTIFICATION DES CHOIX :
* IDX_COMMANDES_DATE : Cet index transforme le parcours séquentiel complet (Full Table Scan) 
  de la table COMMANDES en un parcours par plage d'index (Index Range Scan), réduisant 
  considérablement les lectures de blocs physiques pour isoler les commandes de 2026.
* IDX_COMMANDES_CLIENT : Cet index accélère la jointure entre la table CLIENTS (via sa clé primaire) 
  et COMMANDES (via sa clé étrangère). De plus, l'indexation des clés étrangères évite les verrous 
  complets de table lors des updates/deletes sur la table parente CLIENTS.
*/


-- =========================================================================
-- QUESTION 4 : Requête distribuée (Chiffre d'Affaires total par catégorie en 2026)
-- =========================================================================
-- Cette requête utilise les synonymes locaux (qui pointent vers les sites distants) 
-- pour récupérer les lignes de commandes associées aux commandes de 2026 sur les 
-- deux sites physiques. Elle somme ensuite le chiffre d'affaires et le groupe par catégorie.

WITH ALL_LIGNES AS (
    -- Contribution du Site 1 (Grossistes : QUANTITE >= 100)
    SELECT lc.ID_PRODUIT, lc.QUANTITE, lc.REMISE, cmd.DATE_COMMANDE
    FROM LIGNES_COMMANDES_1 lc
    JOIN COMMANDES_1 cmd ON lc.ID_COMMANDE = cmd.ID_COMMANDE
    UNION ALL
    -- Contribution du Site 2 (Magasins de proximité / Détail : QUANTITE < 100)
    SELECT lc.ID_PRODUIT, lc.QUANTITE, lc.REMISE, cmd.DATE_COMMANDE
    FROM LIGNES_COMMANDES_2 lc
    JOIN COMMANDES_2 cmd ON lc.ID_COMMANDE = cmd.ID_COMMANDE
)
SELECT 
    p.ID_CATEGORIE, 
    cat.NOM_CATEGORIE,
    ROUND(SUM(al.QUANTITE * p.PRIX_UNITAIRE * (1 - al.REMISE)), 2) AS CA_TOTAL_2026
FROM ALL_LIGNES al
JOIN PRODUITS p ON al.ID_PRODUIT = p.ID_PRODUIT
JOIN CATEGORIES cat ON p.ID_CATEGORIE = cat.ID_CATEGORIE
WHERE al.DATE_COMMANDE >= TO_DATE('2026-01-01', 'YYYY-MM-DD')
  AND al.DATE_COMMANDE < TO_DATE('2027-01-01', 'YYYY-MM-DD')
GROUP BY p.ID_CATEGORIE, cat.NOM_CATEGORIE
ORDER BY CA_TOTAL_2026 DESC;
