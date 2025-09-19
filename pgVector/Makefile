.PHONY: build up down restart logs backup restore monitor test-replication test-vectors

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

backup:
	scripts/backup.sh

restore:
	scripts/restore.sh

monitor:
	scripts/monitor.sh

test-replication:
	scripts/test-replication.sh

test-vectors:
	scripts/test-vector-similarity.sh