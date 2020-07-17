# Use to this to bring up the infra from scratch
# Or to destroy it, your choice

all:
	@echo Generating plan upto vpc setup so that mount targets can be computed
	terraform plan -target=module.vpc -out=out.plan
	terraform apply out.plan
	@echo Generating plan for remaining resouces
	terraform plan -out=out.plan
	terraform apply out.plan

destroy:
	terraform destroy
