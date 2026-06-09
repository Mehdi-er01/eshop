ALTER SESSION SET CONTAINER = ESHOP_SITE1_PDB;

-- Create a PUBLIC database link from SITE 1 to the globale PDB
-- PUBLIC so all users (globale_user, site1_user) can access it
CREATE PUBLIC DATABASE LINK GLOBALE
CONNECT TO globale_user IDENTIFIED BY globale_password
USING '//globale-db:1521/ESHOP_GLOBALE_PDB';

/*
  Note: The host `globale-db` and service name `ESHOP_GLOBALE_PDB`
  match the docker-compose service definitions in the repo.
*/
