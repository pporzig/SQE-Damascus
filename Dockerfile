FROM mariadb:10.2.14

RUN mkdir -p /tmp/tables /tmp/schema

ENV MYSQL_ROOT_PASSWORD=none

ADD ./import-database.sh /tmp
ADD ./tables /tmp/tables
ADD ./schema /tmp/schema

RUN chmod +x /tmp/import-database.sh

EXPOSE 3306

CMD ["mysqld"]
