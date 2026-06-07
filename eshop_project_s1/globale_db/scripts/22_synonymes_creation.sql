SET SERVEROUTPUT ON;

ALTER SESSION SET CONTAINER = ESHOP_GLOBALE_PDB;
ALTER SESSION SET CURRENT_SCHEMA = globale_user;

DECLARE
   -- We only define the BASE names here. We will append _1 and _2 dynamically!
   TYPE t_table_list IS TABLE OF VARCHAR2(50);
   v_base_tables t_table_list := t_table_list(
       'FOURNISSEURS', 'CATEGORIES', 'EMPLOYES', 
       'CLIENTS', 'PRODUITS', 'COMMANDES', 'LIGNES_COMMANDES'
   );
   
   v_site1_table VARCHAR2(60);
   v_site2_table VARCHAR2(60);
BEGIN
   FOR i IN 1 .. v_base_tables.COUNT LOOP
       v_site1_table := v_base_tables(i) || '_1'; 
       
       EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM ' || v_site1_table || 
                         ' FOR ' || v_site1_table || '@SITE_1';
   END LOOP;
   DBMS_OUTPUT.PUT_LINE('SUCCESS: Site 1 Synonyms created (COMMANDES_1 -> @SITE_1)');

   FOR i IN 1 .. v_base_tables.COUNT LOOP
       v_site2_table := v_base_tables(i) || '_2'; 
       
       EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM ' || v_site2_table || 
                         ' FOR ' || v_site2_table || '@SITE_2';
   END LOOP;
   DBMS_OUTPUT.PUT_LINE('SUCCESS: Site 2 Synonyms created (COMMANDES_2 -> @SITE_2)');

END;
/