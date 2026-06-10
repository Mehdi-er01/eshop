EXPLAIN PLAN
    FOR
SELECT
    c.id_client,
    COUNT(*) AS nbr_commandes_2026
FROM
    commandes c
WHERE
    EXTRACT(YEAR FROM c.date_commande) = 2026
GROUP BY
    c.id_client;

SELECT
    *
FROM
    TABLE ( dbms_xplan.display );

CREATE INDEX idx_cmd_date_client ON
    commandes (
        date_commande,
        id_client
    );

EXPLAIN PLAN FOR
SELECT 
    c.id_client,
    COUNT(*) AS nbr_commandes_2026
FROM
    commandes c
WHERE
        c.date_commande >= TO_DATE('2026-01-01', 'YYYY-MM-DD')
    AND c.date_commande < TO_DATE('2027-01-01', 'YYYY-MM-DD')
GROUP BY
    c.id_client;
    

SELECT
    *
FROM
    TABLE ( dbms_xplan.display );
    
    
    
    
    
    
    
    
SELECT 
    c.ID_CATEGORIE,
    c.NOM_CATEGORIE,
    SUM(ca_site) AS CHIFFRE_AFFAIRES_TOTAL_2026
FROM (
    -- Contribution du Site 1
    SELECT 
        p1.ID_CATEGORIE,
        SUM((lc1.QUANTITE * p1.PRIX_UNITAIRE) - lc1.REMISE) AS ca_site
    FROM LIGNES_COMMANDES_1 lc1
    JOIN PRODUITS_1 p1 ON p1.ID_PRODUIT = lc1.ID_PRODUIT
    JOIN COMMANDES_1 cmd1 ON cmd1.ID_COMMANDE = lc1.ID_COMMANDE
    WHERE EXTRACT(YEAR FROM cmd1.DATE_COMMANDE) = 2026
    GROUP BY p1.ID_CATEGORIE

    UNION ALL

    -- Contribution du Site 2
    SELECT 
        p2.ID_CATEGORIE,
        SUM((lc2.QUANTITE * p2.PRIX_UNITAIRE) - lc2.REMISE) AS ca_site
    FROM LIGNES_COMMANDES_2 lc2
    JOIN produits_2 p2 ON p2.ID_PRODUIT = lc2.ID_PRODUIT
    JOIN COMMANDES_2 cmd2 ON cmd2.ID_COMMANDE = lc2.ID_COMMANDE
    WHERE EXTRACT(YEAR FROM cmd2.DATE_COMMANDE) = 2026
    GROUP BY p2.ID_CATEGORIE
) sub
JOIN CATEGORIES c ON c.ID_CATEGORIE = sub.ID_CATEGORIE
GROUP BY c.ID_CATEGORIE, c.NOM_CATEGORIE
ORDER BY CHIFFRE_AFFAIRES_TOTAL_2026 DESC;



SELECT *
    FROM LIGNES_COMMANDES_2 lc2
    JOIN produits_2 p2 ON p2.ID_PRODUIT = lc2.ID_PRODUIT
    JOIN COMMANDES_2 cmd2 ON cmd2.ID_COMMANDE = lc2.ID_COMMANDE
    WHERE EXTRACT(YEAR FROM cmd2.DATE_COMMANDE) = 2026
   ;





