.PHONY: init plan apply destroy fmt validate
init:
	cd iac && terraform init
plan:
	cd iac && terraform plan
apply:
	cd iac && terraform apply -auto-approve
destroy:
	cd iac && terraform destroy -auto-approve
fmt:
	cd iac && terraform fmt -recursive
validate:
	cd iac && terraform validate


scp-init:
	cd org && terraform init

scp-apply:
	cd org && terraform apply -auto-approve

scp-destroy:
	cd org && terraform destroy -auto-approve
