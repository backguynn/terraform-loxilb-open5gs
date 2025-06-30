TERRAFORM = terraform
TFVARS = terraform.tfvars
WORKDIR = $(CURDIR)

.PHONY: init plan apply deploy destroy clean zip

init:
	$(TERRAFORM) init

plan:
	$(TERRAFORM) plan -var-file=$(TFVARS)

apply:
	$(TERRAFORM) apply -auto-approve -var-file=$(TFVARS)

deploy: init apply

destroy:
	$(TERRAFORM) destroy -auto-approve -var-file=$(TFVARS)

zip:
	@echo "Creating terraform-package.zip..."
	@zip -r terraform-package.zip *.tf scripts/ files/ modules/ output/ -x "*.terraform*" "*.zip" "*.log" "*terraform.tfstate*"

clean:
	rm -rf .terraform terraform.tfstate* crash.log *.zip *.tar.gz

