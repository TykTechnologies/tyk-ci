# Use to this to bring up the infra from scratch

.PHONY: prod

prod:
	@echo Generating plan upto vpc, for mount targets, and r53, for cloudflare NS entries
	terraform plan -target=module.vpc -target=aws_route53_zone.dev_tyk_tech -out=$(@).plan
	terraform apply $(@).plan
	@echo Generating plan for remaining resouces
	terraform plan -out=$(@).plan
	terraform apply $(@).plan

prereq:
	test -n "$(MONGODB_ATLAS_PUBLIC_KEY)"
	test -n "$(MONGODB_ATLAS_PRIVATE_KEY)"
	test -n "$(CLOUDFLARE_API_TOKEN)"
	test -n "$(CLOUDFLARE_ACCOUNT_ID)"
	test -n "$(AWS_ACCESS_KEY_ID)"
	test -n "$(AWS_SECRET_ACCESS_KEY)"
