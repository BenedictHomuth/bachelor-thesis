go-build:
	docker build -t test-server -f docker/Dockerfile.server . 
	docker build -t test-db -f docker/Dockerfile.postgres . 

start-dev: go-build
	docker compose up

terraform-plan:
	cd terraform && terraform plan

terraform-apply:
	cd terraform && terraform apply
