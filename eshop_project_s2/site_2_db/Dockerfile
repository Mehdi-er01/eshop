FROM docker.io/gvenzl/oracle-xe:latest

COPY --chown=oracle:oinstall ./*.sql /container-entrypoint-initdb.d/

EXPOSE 1521
