FROM docker.io/gvenzl/oracle-xe:21-slim-faststart

COPY --chown=oracle:oinstall ./*.sql /container-entrypoint-initdb.d/

EXPOSE 1521
