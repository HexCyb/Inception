NAME     := inception
ENV_FILE := srcs/.env
COMPOSE  := docker compose -f srcs/docker-compose.yml --env-file $(ENV_FILE) -p $(NAME)
SECRETS  := db_password db_root_password wp_admin_password wp_user_password

all: up

# first run: copy the example .env, generate random passwords, create the data folders
setup:
	@test -f $(ENV_FILE) || { cp srcs/.env.example $(ENV_FILE); echo "created $(ENV_FILE): set LOGIN, DOMAIN_NAME and DATA_PATH"; }
	@mkdir -p secrets
	@for s in $(SECRETS); do \
		test -s secrets/$$s.txt || openssl rand -hex 16 > secrets/$$s.txt; \
	done
	@. ./$(ENV_FILE) && mkdir -p "$$DATA_PATH/mariadb" "$$DATA_PATH/wordpress"

up: setup
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

# removes containers, images, volumes and the website + database files
clean:
	$(COMPOSE) down --rmi all --volumes

fclean: clean
	@. ./$(ENV_FILE) && sudo rm -rf "$$DATA_PATH/mariadb" "$$DATA_PATH/wordpress"

re: fclean all

.PHONY: all setup up down start stop ps logs clean fclean re
