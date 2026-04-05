# =============================================================================
# GenticOS - Makefile
# Production orchestrator for the GenticOS platform
# =============================================================================

.PHONY: up down logs health backup restore kill certs migrate seed build restart ps clean deploy

# Default service for targeted commands
svc ?=
file ?=
token ?=

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

## Start all services in detached mode
up:
	docker compose up -d

## Stop all services
down:
	docker compose down

## Build all images (or specific service)
build:
	docker compose build $(svc)

## Restart a service (or all)
restart:
	docker compose restart $(svc)

## Show running containers
ps:
	docker compose ps

## Tail logs (optionally for a specific service: make logs svc=control-plane)
logs:
	docker compose logs -f $(svc)

## Stop all services and DESTROY volumes (with confirmation)
clean:
	@echo "WARNING: This will destroy all data volumes (postgres, redis, minio, grafana)."
	@read -p "Are you sure? Type 'yes' to confirm: " confirm && \
	if [ "$$confirm" = "yes" ]; then \
		docker compose down -v; \
		echo "All volumes destroyed."; \
	else \
		echo "Aborted."; \
	fi

# ---------------------------------------------------------------------------
# Operations
# ---------------------------------------------------------------------------

## Check control-plane health
health:
	@curl -sf http://localhost:4100/health | jq . || echo "Control plane unreachable"

## Run database migrations
migrate:
	docker compose exec control-plane node dist/db/migrate.js

## Seed the database
seed:
	docker compose exec control-plane node dist/db/seed.js

## Activate global kill switch
kill:
	@if [ -z "$(token)" ]; then echo "Usage: make kill token=<jwt>"; exit 1; fi
	curl -X POST http://localhost:4100/api/v1/kill-switch \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $(token)" \
		-d '{"scope":"global","active":true}' | jq .

## Generate mTLS certificates
certs:
	./certs/generate-mtls.sh

# ---------------------------------------------------------------------------
# Backup & Restore
# ---------------------------------------------------------------------------

## Full backup (postgres + redis + minio)
backup:
	./scripts/backup.sh

## Restore from backup archive: make restore file=path/to/backup.tar.gz
restore:
	@if [ -z "$(file)" ]; then echo "Usage: make restore file=<path/to/backup.tar.gz>"; exit 1; fi
	./scripts/restore.sh $(file)

# ---------------------------------------------------------------------------
# Deployment
# ---------------------------------------------------------------------------

## Deploy to production VPS
deploy:
	./scripts/deploy.sh
