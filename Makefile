.PHONY: up up-dev down build clean logs test validate-frontend test-e2e

# Starts the isolated infrastructure (only API Gateway :5000 and Frontend :3000 exposed)
up:
	docker compose up -d

# Starts the stack in Development mode with Swagger UI and 127.0.0.1 debug ports (5001-5004)
up-dev:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Stops everything
down:
	docker compose down

# Builds the docker images for all services
build:
	docker compose build

# View logs for all running services
logs:
	docker compose logs -f

# Cleans all .NET bin/obj folders to resolve caching issues, and removes docker volumes
clean:
	find . -type d -name "bin" -prune -exec rm -rf {} +
	find . -type d -name "obj" -prune -exec rm -rf {} +
	docker compose down -v --remove-orphans

# Finds and runs tests across all individual solution files
test:
	find . -name "*.sln*" -exec dotnet test {} \;

# Validates frontend tests, build and docker container
validate-frontend:
	@echo "Running frontend validation"
	cd src/frontend && npm run validate
	@echo "Building frontend Docker container"
	docker compose build frontend
	@echo "Frontend validation completed successfully."

# Runs End-to-End API Gateway integration tests using Newman
test-e2e:
	@echo "Running End-to-End API Gateway integration tests..."
	npx --yes newman run tests/postman/uct-map.collection.json -e tests/postman/local.environment.json -d tests/postman/default-data.json --reporters cli
