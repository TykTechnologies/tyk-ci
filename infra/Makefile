# Use to this to bring up the infra from scratch

# Only one of these buckets should exist in the known universe
DEVENV_STATE_BUCKET := terraform-state-devenv

.PHONY: prod devenv-euc1-test state-bucket

state-bucket:
	aws s3api head-bucket --bucket $(DEVENV_STATE_BUCKET) \
		|| aws s3api create-bucket --bucket $(DEVENV_STATE_BUCKET)

prod:
	@echo Generating plan upto vpc, for mount targets, and r53, for cloudflare NS entries
	terraform plan -var-file=$(@).tfvars -target=module.vpc -target=aws_route53_zone.dev_tyk_tech -out=$(@).plan
	terraform apply $(@).plan
	@echo Generating plan for remaining resouces
	terraform plan -var-file=$(@).tfvars -out=$(@).plan
	terraform apply $(@).plan

devenv-euc1-test:
	@echo Generating plan upto vpc, for mount targets, and r53, for cloudflare NS entries
	terraform plan -var-file=$(@).tfvars -target=module.vpc -target=aws_route53_zone.dev_tyk_tech -out=$(@).plan
	terraform apply $(@).plan

prereq:
	test -n "$(MONGODB_ATLAS_PUBLIC_KEY)"
	test -n "$(MONGODB_ATLAS_PRIVATE_KEY)"
	test -n "$(CLOUDFLARE_API_TOKEN)"
	test -n "$(CLOUDFLARE_ACCOUNT_ID)"
	test -n "$(AWS_ACCESS_KEY_ID)"
	test -n "$(AWS_SECRET_ACCESS_KEY)"