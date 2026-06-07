FROM docker.io/gvenzl/oracle-xe:21-slim-faststart

#COPY --chown=oracle:oinstall ./scripts /opt/globale_db/scripts

COPY --chown=oracle:oinstall ./scripts/ /container-entrypoint-initdb.d/

#RUN chmod +x /container-entrypoint-initdb.d/globale-db-startup-script.sh

EXPOSE 1521