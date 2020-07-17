ECR := 046805072452.dkr.ecr.eu-central-1.amazonaws.com

.PHONY: gromit

debug: *.go
	go mod tidy
	go build -o $(@)

gromit:
	aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $(ECR)
	docker build -t $(@):latest .
	docker tag $(@):latest $(ECR)/$(@):latest
	docker push $(ECR)/$(@):latest
