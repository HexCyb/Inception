#!/bin/sh
# Writes nginx.conf for DOMAIN_NAME, creates a self-signed TLS certificate,
# then hands PID 1 over to nginx running in the foreground.
set -eu

sed "s/__DOMAIN_NAME__/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/nginx/ssl/inception.key -out /etc/nginx/ssl/inception.crt \
        -subj "/C=TR/O=42 Turkiye/CN=${DOMAIN_NAME}" 2> /dev/null
fi

exec "$@"
