ALTER SESSION SET CONTAINER = ESHOP_SITE2_PDB;

-- Create a PUBLIC database link from SITE 2 to the globale PDB
-- PUBLIC so all users (globale_user, site2_user) can access it
CREATE PUBLIC DATABASE LINK GLOBALE
CONNECT TO globale_user IDENTIFIED BY globale_password
USING '//globale-db:1521/ESHOP_GLOBALE_PDB';

/*
  The host name and service name are aligned with docker-compose service definitions.
*/
