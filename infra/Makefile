# Use to this to bring up the infra from scratch

prod:
	@echo Generating plan upto vpc setup so that mount targets can be computed
	terraform plan -var-file=$(@).tfvars -target=module.vpc -target=aws_route53_zone.dev_tyk_tech -out=out.plan
	terraform apply out.plan
	@echo Generating plan for remaining resouces
	terraform plan -var-file=$(@).tfvars -out=out.plan
	terraform apply out.plan
