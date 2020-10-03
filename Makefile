build:
	docker-compose build

up: build
	docker-compose up

# use Ctrl-P Ctrl-Q to detach
debug-web:
	docker attach $$(docker-compose ps -q web)

test:
	docker-compose exec web rspec
