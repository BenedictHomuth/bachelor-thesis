go-build:
	docker build -t test-build -f docker/Dockerfile . 

terraform-plan:
	cd terraform && terraform plan

terraform-apply:
	cd terraform && terraform apply