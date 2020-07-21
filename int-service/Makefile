ECR := 046805072452.dkr.ecr.eu-central-1.amazonaws.com

.PHONY: int-service

int-service:
	aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $(ECR)
	docker build -t $(@):latest .
	docker tag $(@):latest $(ECR)/$(@):latest
	docker push $(ECR)/$(@):latest
