SET SERVEROUTPUT ON;
SET SQLBLANKLINES ON;

DECLARE
   v_current_con          varchar2(128);
   v_globale_con          varchar2(128) := 'ESHOP_GLOBALE_PDB';
   v_count                integer := 0;

   -- CREDENTIALS OF THE GLOBAL DATABASE USER
   v_globale_user_name    varchar2(128) := 'globale_user';
   v_globale_user_passwd  varchar2(128) := 'globale_password';

   -- CREDENTIALS OF THE SITE 1 USER
   v_site1_user_name      varchar2(128) := 'site1_user';
   v_site1_user_passwd    varchar2(128) := 'site1_password';

   -- CREDENTIALS OF THE SITE 2 USER
   v_site2_user_name      varchar2(128) := 'site2_user';
   v_site2_user_passwd    varchar2(128) := 'site2_password';
BEGIN

   -- RETRIEVE THE CURRENT CONTAINER OF THE CURRENT USER
   SELECT sys_context('USERENV', 'CON_NAME')
     INTO v_current_con
     FROM dual;

   -- VERIFY IF THE CONTAINER EXISTS
   SELECT count(*)
     INTO v_count
     FROM v$pdbs
    WHERE name = v_globale_con;

   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE PLUGGABLE DATABASE '
                        || v_globale_con
                        || ' ADMIN USER '
                        || v_globale_user_name
                        || ' IDENTIFIED BY '
                        || v_globale_user_passwd
                        || ' FILE_NAME_CONVERT = (''pdbseed'', ''' || v_globale_con || ''')';
                    

      DBMS_OUTPUT.PUT_LINE('CONTAINER <' || v_globale_con || '> HAS BEEN CREATED');
   ELSE
      DBMS_OUTPUT.PUT_LINE('CONTAINER <' || v_globale_con || '> IS ALREADY CREATED');
   END IF;

   -- ALTER THE SESSION TO THE GLOBALE CONTAINER
   EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ' || v_globale_con;

   -- OPEN THE PDB 
   BEGIN
       EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ' || v_globale_con || ' OPEN';
       DBMS_OUTPUT.PUT_LINE('CONTAINER <' || v_globale_con || '> IS NOW OPEN');
   EXCEPTION
       WHEN OTHERS THEN
           -- Ignore error if it is already open
           DBMS_OUTPUT.PUT_LINE('CONTAINER <' || v_globale_con || '> WAS ALREADY OPEN');
   END;

   EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = ' || v_globale_user_name;
   DBMS_OUTPUT.PUT_LINE('CURRENT SCHEMA CHANGED TO ' || v_globale_user_name || ' INSIDE ' || v_globale_con);

   -- CREATE THE SITE 1 USER
   BEGIN
       EXECUTE IMMEDIATE 'CREATE USER '
                         || v_site1_user_name
                         || ' IDENTIFIED BY "'
                         || v_site1_user_passwd
                         || '" ACCOUNT UNLOCK';
       DBMS_OUTPUT.PUT_LINE('USER OF SITE 1 HAS BEEN CREATED');
   EXCEPTION 
       WHEN OTHERS THEN 
           IF SQLCODE = -1920 THEN -- ORA-01920: user name conflicts with another user or role
               DBMS_OUTPUT.PUT_LINE('USER OF SITE 1 ALREADY EXISTS (Skipping Creation)');
           ELSE
               DBMS_OUTPUT.PUT_LINE('CRITICAL ERROR CREATING SITE 1: ' || SQLERRM);
               RAISE; 
           END IF;
   END;

   -- CREATE THE SITE 2 USER
   BEGIN
       EXECUTE IMMEDIATE 'CREATE USER '
                         || v_site2_user_name
                         || ' IDENTIFIED BY "'
                         || v_site2_user_passwd
                         || '" ACCOUNT UNLOCK';
       DBMS_OUTPUT.PUT_LINE('USER OF SITE 2 HAS BEEN CREATED');
   EXCEPTION 
       WHEN OTHERS THEN 
           IF SQLCODE = -1920 THEN
               DBMS_OUTPUT.PUT_LINE('USER OF SITE 2 ALREADY EXISTS (Skipping Creation)');
           ELSE
               DBMS_OUTPUT.PUT_LINE('CRITICAL ERROR CREATING SITE 2: ' || SQLERRM);
               RAISE;
           END IF;
   END;
   
   -- GRANT DBA TO GLOBAL USER
   BEGIN
       EXECUTE IMMEDIATE 'GRANT DBA TO ' || v_globale_user_name;
       DBMS_OUTPUT.PUT_LINE('DBA ROLE GRANTED TO ' || v_globale_user_name);
   EXCEPTION
       WHEN OTHERS THEN
           DBMS_OUTPUT.PUT_LINE('WARNING: Could not grant DBA to ' || v_globale_user_name || ': ' || SQLERRM);
   END;
   
   -- GRANT THE PRIVILEGES TO SITES
   EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO '
                     || v_site1_user_name
                     || ', '
                     || v_site2_user_name;

   DBMS_OUTPUT.PUT_LINE('PRIVILEGES GRANTED SUCCESSFULLY');
END;
/