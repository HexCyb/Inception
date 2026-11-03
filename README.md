# Inception

[![CI](https://github.com/HexCyb/Inception/actions/workflows/ci.yml/badge.svg)](https://github.com/HexCyb/Inception/actions/workflows/ci.yml)

A small WordPress infrastructure built with **Docker Compose**: three containers, one per service, each built from `debian:bookworm`. They talk over a private network, and the only way in is HTTPS on port 443.

> Originally completed at **42 Türkiye** as part of the common core. This repository is a 2026 rewrite, because the original code was lost.
> 42 Türkiye'de tamamladığım projenin 2026'da yeniden yazılmış hali; orijinal kod kayboldu.

## Architecture

```
              https://login.42.fr   (port 443, TLS 1.2 / 1.3)
                          │
          ┌───────────────▼────────────────┐
          │  nginx       TLS, static files │──── wordpress_data (read only)
          └───────────────┬────────────────┘
                          │ FastCGI   wordpress:9000
          ┌───────────────▼────────────────┐
          │  wordpress   php-fpm + wp-cli  │──── wordpress_data → /home/login/data/wordpress
          └───────────────┬────────────────┘
                          │ SQL       mariadb:3306
          ┌───────────────▼────────────────┐
          │  mariadb     database          │──── mariadb_data   → /home/login/data/mariadb
          └────────────────────────────────┘
                   network: inception (bridge)
```

## Run it

```sh
echo "127.0.0.1 login.42.fr" | sudo tee -a /etc/hosts   # once: the domain points to this machine
make                                                    # first run also creates srcs/.env and secrets/
```

Then open **https://login.42.fr**. The certificate is self-signed, so the browser warns once. The admin panel is at `/wp-admin`.

| Command | What it does |
|---|---|
| `make` | Set up, build and start everything |
| `make down` / `make up` | Remove / recreate the containers. The data stays |
| `make ps` / `make logs` | Status / live logs |
| `make clean` | Remove containers, images and volumes |
| `make fclean` | Also delete the website and database files on the host |

## Subject rules and where they are handled

| Rule | How |
|---|---|
| One service per container, own Dockerfiles, no ready-made images | `srcs/requirements/*/Dockerfile`, all `FROM debian:bookworm` (the penultimate stable Debian) |
| Only NGINX is reachable, with TLS 1.2 / 1.3 only | `443:443` is published on nginx only, with `ssl_protocols TLSv1.2 TLSv1.3` |
| No passwords in Dockerfiles or in git | Docker secrets in `secrets/` (random, created by `make`, ignored by git). Other settings go in `srcs/.env` |
| Containers restart after a crash | `restart: unless-stopped` |
| No `tail -f` or endless loops, a real PID 1 | Each entrypoint prepares its service, then `exec`s it: `mariadbd`, `php-fpm -F`, `nginx -g 'daemon off;'` |
| Two volumes stored in `/home/login/data` | Named volumes `mariadb_data` and `wordpress_data`, bound to `$DATA_PATH` |
| Two WordPress users, the admin name without "admin" | `boss` (administrator) and `writer` (author), created by wp-cli |
| Own network, no `host` or `links` | `networks: inception` (bridge) |

## What happens on the first start

1. **mariadb**: The data folder is empty. The entrypoint creates the system tables, the `wordpress` database, its user and the root password (in bootstrap mode, with no network), then starts `mariadbd`. The healthcheck (`mariadb-admin ping`) makes WordPress wait until it is ready.
2. **wordpress**: There is no `wp-config.php` yet. wp-cli downloads WordPress, writes the config, installs the site and creates both users, then `php-fpm` takes over.
3. **nginx**: Writes its config for `DOMAIN_NAME` and creates a self-signed certificate. It serves static files itself and sends `.php` requests to `wordpress:9000`.

On every later start the files are already there, so each container goes straight to its service.

## Project structure

```
Makefile
secrets/                          generated passwords (not in git)
srcs/
├── docker-compose.yml
├── .env.example                  copied to .env on the first `make`
└── requirements/
    ├── mariadb/     Dockerfile   conf/50-server.cnf         tools/entrypoint.sh
    ├── wordpress/   Dockerfile   conf/www.conf              tools/entrypoint.sh
    └── nginx/       Dockerfile   conf/nginx.conf.template   tools/entrypoint.sh
```

## Continuous integration

Every push runs [GitHub Actions](https://github.com/HexCyb/Inception/actions/workflows/ci.yml) (`.github/workflows/ci.yml`):

- ShellCheck on the three entrypoints and `docker compose config` on the compose file
- **full stack**: `make` generates the secrets, builds the three images and starts them; the job then waits for WordPress over HTTPS through NGINX, checks a TLS 1.3 handshake, checks that 443 is the only published port and that MariaDB is healthy
