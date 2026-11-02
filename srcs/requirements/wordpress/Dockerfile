FROM debian:bookworm

ARG WP_CLI_VERSION=2.12.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        php-fpm php-mysql php-curl php-gd php-intl php-mbstring php-xml php-zip \
        mariadb-client curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# wp-cli installs and configures WordPress from the command line
RUN curl -fsSL -o /usr/local/bin/wp \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
 && chmod +x /usr/local/bin/wp

# works whatever PHP version the distribution ships (8.2 on bookworm)
COPY conf/www.conf /tmp/www.conf
RUN set -eu; \
    fpm_dir="$(echo /etc/php/*/fpm)"; \
    mv /tmp/www.conf "$fpm_dir/pool.d/www.conf"; \
    ln -s "$(ls /usr/sbin/php-fpm*)" /usr/local/sbin/php-fpm; \
    mkdir -p /run/php /var/www/html

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm", "-F"]
