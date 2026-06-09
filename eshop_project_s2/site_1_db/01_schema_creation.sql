SET SERVEROUTPUT ON;
SET SQLBLANKLINES ON;

DECLARE
   v_current_con          varchar2(128);
   v_site1_con            varchar2(128) := 'ESHOP_SITE1_PDB';
   v_count                integer := 0;

   -- CREDENTIALS OF THE PDB OWNER (GLOBAL USER)
   v_globale_user_name    varchar2(128) := 'globale_user';
   v_globale_user_passwd  varchar2(128) := 'globale_password';

   -- CREDENTIALS OF THE LOCAL SITE 1 USER (READ-ONLY)
   v_site1_user_name      varchar2(128) := 'site1_user';
   v_site1_user_passwd    varchar2(128) := 'site1_password';

   -- ARRAY FOR TABLE GRANTS
   TYPE t_table_list IS TABLE OF VARCHAR2(50);
   v_tables t_table_list := t_table_list(
       'FOURNISSEURS_1', 
       'CATEGORIES_1', 
       'EMPLOYES_1', 
       'CLIENTS_1', 
       'PRODUITS_1', 
       'COMMANDES_1', 
       'LIGNES_COMMANDES_1'
   );

BEGIN
   -- 1. RETRIEVE THE CURRENT CONTAINER
   SELECT sys_context('USERENV', 'CON_NAME')
     INTO v_current_con
     FROM dual;

   -- 2. VERIFY IF THE SITE 1 CONTAINER EXISTS
   SELECT count(*)
     INTO v_count
     FROM v$pdbs
    WHERE name = v_site1_con;

   IF v_count = 0 THEN
      -- Create the PDB and make globale_user the Admin/Owner
      EXECUTE IMMEDIATE 'CREATE PLUGGABLE DATABASE '
                        || v_site1_con
                        || ' ADMIN USER '
                        || v_globale_user_name
                        || ' IDENTIFIED BY '
                        || v_globale_user_passwd
                        || ' FILE_NAME_CONVERT = (''pdbseed'', ''' || v_site1_con || ''')';
                    
      DBMS_OUTPUT.PUT_LINE('CONTAINER <' || v_site1_con || '> HAS BEEN CREATED');
   ELSE
      DBMS_OUTPUT.PUT_LINE('CONTAINER <' || v_site1_con || '> IS ALREADY CREATED');
   END IF;

   -- 3. ALTER THE SESSION TO THE SITE 1 CONTAINER
   EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ' || v_site1_con;

   -- 4. OPEN THE PDB 
   BEGIN
       EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ' || v_site1_con || ' OPEN';
       DBMS_OUTPUT.PUT_LINE('CONTAINER <' || v_site1_con || '> IS NOW OPEN');
   EXCEPTION
       WHEN OTHERS THEN
           DBMS_OUTPUT.PUT_LINE('CONTAINER <' || v_site1_con || '> WAS ALREADY OPEN');
   END;

   -- 5. SET SCHEMA TO THE OWNER
   EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = ' || v_globale_user_name;
   DBMS_OUTPUT.PUT_LINE('CURRENT SCHEMA CHANGED TO ' || v_globale_user_name || ' INSIDE ' || v_site1_con);

   -- 6. CREATE THE SITE 1 USER (NO SITE 2 USER HERE)
   BEGIN
       EXECUTE IMMEDIATE 'CREATE USER '
                         || v_site1_user_name
                         || ' IDENTIFIED BY "'
                         || v_site1_user_passwd
                         || '" ACCOUNT UNLOCK';
       DBMS_OUTPUT.PUT_LINE('USER OF SITE 1 HAS BEEN CREATED');
   EXCEPTION 
       WHEN OTHERS THEN 
           IF SQLCODE = -1920 THEN 
               DBMS_OUTPUT.PUT_LINE('USER OF SITE 1 ALREADY EXISTS (Skipping Creation)');
           ELSE
               DBMS_OUTPUT.PUT_LINE('CRITICAL ERROR CREATING SITE 1 USER: ' || SQLERRM);
               RAISE; 
           END IF;
   END;
   
   -- 7. GRANT DBA TO THE GLOBAL OWNER
   EXECUTE IMMEDIATE 'GRANT DBA TO ' || v_globale_user_name;
   
   -- 7b. EXPLICIT GRANTS FOR DBLINK CREATION
   EXECUTE IMMEDIATE 'GRANT CREATE DATABASE LINK TO ' || v_globale_user_name;
   EXECUTE IMMEDIATE 'GRANT CREATE SYNONYM TO ' || v_globale_user_name;
   
   -- 8. GRANT LOGIN PRIVILEGE TO SITE 1 USER
   EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ' || v_site1_user_name;
                     
   -- 9. LOOP THROUGH TABLES AND GRANT *ONLY* SELECT TO SITE 1 USER
   BEGIN
       FOR i IN 1 .. v_tables.COUNT LOOP
           -- This ensures the local user can only read, never write
           EXECUTE IMMEDIATE 'GRANT SELECT ON ' || v_tables(i) || ' TO ' || v_site1_user_name;
       END LOOP;
       DBMS_OUTPUT.PUT_LINE('READ-ONLY (SELECT) PRIVILEGES GRANTED ON ALL TABLES SUCCESSFULLY');
   EXCEPTION
       WHEN OTHERS THEN
           -- If tables aren't created yet, it will catch the error here and let you know!
           DBMS_OUTPUT.PUT_LINE('NOTE: Tables do not exist yet in this PDB. Run your CREATE TABLE script first, then re-run this block to grant SELECT privileges.');
   END;

   DBMS_OUTPUT.PUT_LINE('--- SITE 1 ENVIRONMENT SETUP COMPLETE ---');
END;
/