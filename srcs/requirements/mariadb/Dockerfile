FROM debian:bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends mariadb-server mariadb-client \
 && rm -rf /var/lib/apt/lists/* \
 # empty data dir: the database is created on first start, inside the volume
 && rm -rf /var/lib/mysql/* \
 && mkdir -p /run/mysqld \
 && chown mysql:mysql /run/mysqld

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["entrypoint.sh"]
CMD ["mariadbd", "--user=mysql"]
