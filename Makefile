include env/deploy.env
export

.DEFAULT_GOAL := help
.PHONY: help

help:
	@grep -Eh '(\s##\s|^##\s)' $(MAKEFILE_LIST) \
	| grep -Ev '^--' \
	| awk '\
		/^##/ { print ""; print substr($$0,4); print ""; next } \
		BEGIN { FS=":[[:space:]]*##[[:space:]]*" } \
		{ printf "\033[32m  %-35s\033[0m %s\n", $$1, $$2 }'

MYSQL_HOST ?= 127.0.0.1
MYSQL_PORT ?= 3307
MYSQL_USER ?= acore
MYSQL_PASSWORD ?= $(MYSQL_ROOT_PASSWORD)

## INIT

init: ## Initialize deploy files
	$(CURDIR)/sql/envsub.sh
	$(CURDIR)/init.sh

install-quadlets: ## Install the Quadlet unit files
	$(CURDIR)/podman/install-quadlets.sh

init-realmlist: ## Initialize the database realmlist
	mysql \
		--ssl=0 \
 		-h $(MYSQL_HOST) \
 		-P $(MYSQL_PORT) \
 		-u $(MYSQL_USER) \
 		-p$(MYSQL_PASSWORD) \
 		< $(CURDIR)/sql/db-post-init/add-realms.sql

gen-ssh: ## Generate an SSH key pair
	$(CURDIR)/gen-ssh.sh

## BUILD
build: ## Builds binary/db images
	$(MAKE) build-db
	$(MAKE) build-auth
	$(MAKE) build-world-live
	$(MAKE) build-world-dev

build-db: ## Builds the db image
	podman build \
	-f $(CURDIR)/podman/Containerfile \
	--target database \
	-t acore-database:latest $(CURDIR)

build-auth: ## Builds the auth server image
	podman build \
	-f $(CURDIR)/podman/Containerfile \
	--target authserver \
	-t acore-authserver:live $(CURDIR)/src/live

build-world-live: ## Builds the live world server image
	podman build \
	-f $(CURDIR)/podman/Containerfile \
	--target worldserver \
	-t acore-worldserver:live $(CURDIR)/src/live

build-world-dev: ## Builds the dev world server image
	podman build \
	--build-arg BRANCH_SET=dev \
	-f $(CURDIR)/podman/Containerfile \
	--target worldserver \
	-t acore-worldserver:dev $(CURDIR)/src/dev

## REBUILD

rebuild-db: ## Rebuild the db image without using cache
	podman build \
	--no-cache \
	-f $(CURDIR)/podman/Containerfile \
	--target database \
	-t acore-database:latest $(CURDIR)

rebuild-auth: ## Rebuild the auth server image without using cache
	podman build \
	--no-cache \
	-f $(CURDIR)/podman/Containerfile \
	--target authserver \
	-t acore-authserver:live $(CURDIR)/src/live

rebuild-world-live: ## Rebuild the live world server image without using cache
	podman build \
	--no-cache \
	-f $(CURDIR)/podman/Containerfile \
	--target worldserver \
	-t acore-worldserver:live $(CURDIR)/src/live

rebuild-world-dev: ## Rebuild the development world server image without using cache
	podman build \
	--no-cache \
	--build-arg BRANCH_SET=dev \
	-f $(CURDIR)/podman/Containerfile \
	--target worldserver \
	-t acore-worldserver:dev $(CURDIR)/src/dev

## START
start: ## Start all services
	$(MAKE) start-db
	$(MAKE) start-auth
	$(MAKE) start-world-live
	$(MAKE) start-world-dev

start-db: ## Start the database service
	systemctl --user start acore-database.service

start-auth: ## Start the auth server service
	systemctl --user start acore-authserver.service

start-world-live: ## Start the live world server service
	systemctl --user start acore-worldserver.service

start-world-dev: ## Start the development world server service
	systemctl --user start acore-worldserver-dev.service

## RESTART

restart-db: ## Restart the database service
	systemctl --user restart acore-database.service

restart-auth: ## Restart the auth server service
	systemctl --user restart acore-authserver.service

restart-world-live: ## Restart the live world server service
	systemctl --user restart acore-worldserver.service

restart-world-dev: ## Restart the development world server service
	systemctl --user restart acore-worldserver-dev.service

## CONTAINER SHELL

world-live-shell: ## Open a shell in the live world server container
	podman exec -it acore-worldserver /bin/bash

world-dev-shell: ## Open a shell in the development world server container
	podman exec -it acore-worldserver-dev /bin/bash

auth-shell: ## Open a shell in the auth server container
	podman exec -it acore-authserver /bin/bash

db-shell: ## Open a shell in the database container
	podman exec -it acore-database /bin/bash

## LOGS

logs-auth: ## Follow the auth server logs
	journalctl --user -u acore-authserver.service -f

logs-world-live: ## Follow the live world server logs
#	journalctl --user -u acore-worldserver.service -f
	journalctl --user -u acore-worldserver.service -n 200

logs-world-dev: ## Follow the development world server logs
	journalctl --user -u acore-worldserver-dev.service -n 200

## PODMAN RUN
pmrun-auth:
	podman run --rm -it --env-file env/live.env localhost/acore-authserver:live

pmrun-world:
	podman run --rm -it --env-file env/live.env localhost/acore-worldserver:live

## OTHER

reload: ## Reload the user systemd daemon
	systemctl --user daemon-reload

prune: ## Remove unused Podman images
	podman image prune -f

db-console: ## Open a MySQL client connected to the database
	mysql \
		--ssl=0 \
 		-h $(MYSQL_HOST) \
 		-P $(MYSQL_PORT) \
 		-u $(MYSQL_USER) \
 		-p$(MYSQL_PASSWORD)
