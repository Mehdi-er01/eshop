ALTER SESSION SET CONTAINER = ESHOP_GLOBALE_PDB;
ALTER SESSION SET CURRENT_SCHEMA = globale_user;

-- Marker table: created LAST to signal that globale_db init is complete.
-- The docker-compose healthcheck queries this table.
CREATE TABLE INIT_COMPLETE (
    STATUS VARCHAR2(20) DEFAULT 'READY',
    CREATED_AT DATE DEFAULT SYSDATE
);

INSERT INTO INIT_COMPLETE (STATUS) VALUES ('READY');
COMMIT;
