.PHONY: up down build clean logs test validate-frontend

# Starts the entire infrastructure and microservices in the background
up:
	docker-compose up -d

# Stops everything
down:
	docker-compose down

# Builds the docker images for all microservices
build:
	docker-compose build

# View logs for all running services
logs:
	docker-compose logs -f

# Cleans all .NET bin/obj folders to resolve caching issues, and removes docker volumes
clean:
	find . -type d -name "bin" -prune -exec rm -rf {} +
	find . -type d -name "obj" -prune -exec rm -rf {} +
	docker-compose down -v --remove-orphans

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
