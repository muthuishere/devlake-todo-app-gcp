# devlake-todo-app-gcp/makefile

.PHONY: clean build run test help docker-build docker-run docker-stop

# Default target
help:
	@echo "Available commands:"
	@echo "  make clean    - Clean build directories"
	@echo "  make build    - Build the application"
	@echo "  make run      - Run the application"
	@echo "  make test     - Run tests"
	@echo "  make all      - Clean, build, and run tests"

docker-build:
	docker build -t todo-app .

docker-run:
	docker run --rm -p 9090:9090 --name todo-app todo-app

docker: docker-build docker-run

# Clean build directories
clean:
	./gradlew clean

# Build the application
build:
	./gradlew build -x test

# Run the application
run:
	./gradlew bootRun

http-test:
	ijhttp -L VERBOSE  --env-file scripts/http-client.env.json --env development scripts/api-test.http --report

# Run tests
test:
	./gradlew test

# Clean, build, and run tests
all: clean build test
