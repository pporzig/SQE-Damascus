FROM mariadb:10.2.11

RUN mkdir -p /tmp/tables /tmp/schema /tmp/geom_tables

ADD ./import-docker.sh /tmp
ADD ./tables /tmp/tables
ADD ./schema /tmp/schema
ADD ./geom_tables /tmp/geom_tables

RUN chmod +x /tmp/import-docker.sh

EXPOSE 3306
CMD ["mysqld"]