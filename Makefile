### Defensive settings for make:
#     https://tech.davis-hansson.com/p/make/
SHELL:=bash
.ONESHELL:
# for Makefile debugging purposes add -x to the .SHELLFLAGS
.SHELLFLAGS:=-eu -o pipefail -O inherit_errexit -c
.SILENT:
.DELETE_ON_ERROR:
MAKEFLAGS+=--warn-undefined-variables
MAKEFLAGS+=--no-builtin-rules

CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
GIT_FOLDER=$(CURRENT_DIR)/.git

PROJECT_NAME=kvoltoweb
STACK_NAME=www-geosphere-at

# We like colors
# From: https://coderwall.com/p/izxssa/colored-makefile-for-golang-projects
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`
YELLOW=`tput setaf 3`

.PHONY: all
all: install

# Add the following 'help' target to your Makefile
# And add help text after each target name starting with '\#\#'
.PHONY: help
help: ## This help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

###########################################
# Frontend
###########################################
.PHONY: frontend-install
frontend-install:  ## Install React Frontend
	$(MAKE) -C "./frontend/" install

.PHONY: frontend-build
frontend-build:  ## Build React Frontend
	$(MAKE) -C "./frontend/" build

.PHONY: frontend-start
frontend-start:  ## Start React Frontend
	$(MAKE) -C "./frontend/" start

.PHONY: frontend-test
frontend-test:  ## Test frontend codebase
	@echo "Test frontend"
	$(MAKE) -C "./frontend/" test

.PHONY: frontend-check
frontend-check:  ## Test frontend codebase
	@echo "Test frontend"
	$(MAKE) -C "./frontend/" lint

###########################################
# Backend
###########################################
.PHONY: backend-install
backend-install: backend-build backend-create-site ## Create virtualenv and install Plone
	@echo "Installed backend with site"

.PHONY: backend-build
backend-build:  ## Build Backend
	$(MAKE) -C "./backend/" zope-instance

.PHONY: backend-create-site
backend-create-site: ## Create a Plone site with default content
	$(MAKE) -C "./backend/" plone-site-create

.PHONY: backend-start
backend-start: ## Start Plone Backend
	$(MAKE) -C "./backend/" zope-start

.PHONY: backend-test
backend-test:  ## Test backend codebase
	@echo "Test backend"
	$(MAKE) -C "./backend/" test

.PHONY: backend-check
backend-check:  ## Test backend codebase
	@echo "Check backend"
	$(MAKE) -C "./backend/" check

###########################################
# General
###########################################
.PHONY: install
install:  ## Install
	@echo "Install Backend & Frontend"
	$(MAKE) backend-install
	$(MAKE) frontend-install

.PHONY: start
start: install  ## Start help
	@echo "$(GREEN)In order to start the application you need to run $(YELLOW)'make backend-start'$(GREEN) in one terminal and $(YELLOW)'make frontend-start'$(GREEN) in another terminal$(RESET)"

.PHONY: clean
clean:  ## Clean installation
	@echo "Clean installation"
	$(MAKE) -C "./backend/" clean
	$(MAKE) -C "./frontend/" clean

.PHONY: i18n
i18n:  ## Update locales
	@echo "Update locales"
	$(MAKE) -C "./backend/" i18n
	$(MAKE) -C "./frontend/" i18n

.PHONY: check
check:  backend-check frontend-check ## Test codebase

.PHONY: test
test:  backend-test frontend-test ## Test codebase

## Acceptance
.PHONY: build-acceptance-servers
build-acceptance-servers: ## Build Acceptance Servers
	@echo "Build acceptance backend"
	@docker build backend -t collective/kvoltoweb-backend:acceptance -f backend/Dockerfile.acceptance
	@echo "Build acceptance frontend"
	@docker build frontend -t collective/kvoltoweb-frontend:acceptance -f frontend/Dockerfile

.PHONY: start-acceptance-servers
start-acceptance-servers: build-acceptance-servers ## Start Acceptance Servers
	@echo "Start acceptance backend"
	@docker run --rm -p 55001:55001 --name kvoltoweb-backend-acceptance -d collective/kvoltoweb-backend:acceptance
	@echo "Start acceptance frontend"
	@docker run --rm -p 3000:3000 --name kvoltoweb-frontend-acceptance --link kvoltoweb-backend-acceptance:backend -e RAZZLE_API_PATH=http://localhost:55001/plone -e RAZZLE_INTERNAL_API_PATH=http://backend:55001/plone -d collective/kvoltoweb-frontend:acceptance

.PHONY: stop-acceptance-servers
stop-acceptance-servers: ## Stop Acceptance Servers
	@echo "Stop acceptance containers"
	@docker stop kvoltoweb-frontend-acceptance
	@docker stop kvoltoweb-backend-acceptance

.PHONY: run-acceptance-tests
run-acceptance-tests: ## Run Acceptance tests
	$(MAKE) start-acceptance-servers
	npx wait-on --httpTimeout 20000 http-get://localhost:55001/plone http://localhost:3000
	$(MAKE) -C "./frontend/" test-acceptance-headless
	$(MAKE) stop-acceptance-servers
