# Agentic CRM OS — schema + lead state machine reference implementation
# Real targets only: this repo is Postgres + SQL, no app server to build/deploy.

.PHONY: up down psql migrate test clean

PGUSER ?= postgres
PGDB ?= agentic_crm_os
COMPOSE = docker compose

## Start Postgres
up:
	$(COMPOSE) up -d
	@echo "Waiting for Postgres..."
	@until $(COMPOSE) exec -T postgres pg_isready -U $(PGUSER) >/dev/null 2>&1; do sleep 1; done

## Stop Postgres
down:
	$(COMPOSE) down

## Open a psql shell against the running database
psql:
	$(COMPOSE) exec postgres psql -U $(PGUSER) -d $(PGDB)

## Apply all migrations in order (idempotent only if DB is fresh)
migrate:
	@for f in migrations/*.sql; do \
		echo "-- $$f"; \
		$(COMPOSE) exec -T postgres psql -U $(PGUSER) -d $(PGDB) -v ON_ERROR_STOP=1 < $$f || exit 1; \
	done

## Run the fn_transition_lead() test suite against the running database
test:
	$(COMPOSE) exec -T postgres psql -U $(PGUSER) -d $(PGDB) -v ON_ERROR_STOP=1 < tests/test_state_machine.sql

## Stop Postgres and destroy the data volume
clean:
	$(COMPOSE) down -v
