FROM postgres:13-alpine as dumper  

COPY ./seed/*.sql /docker-entrypoint-initdb.d/

RUN ["sed", "-i", "s/exec \"$@\"/echo \"skipping...\"/", "/usr/local/bin/docker-entrypoint.sh"]

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

ENV PGDATA=/data

RUN ["/usr/local/bin/docker-entrypoint.sh", "postgres"]


# final build stage
FROM postgres:13-alpine

COPY --from=dumper /data $PGDATA