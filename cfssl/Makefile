API_KEY ?= ${CFSSL_API_KEY}
ECR := 046805072452.dkr.ecr.eu-central-1.amazonaws.com

.PHONY: cfssl

cfssl:
	aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $(ECR)
	docker build -t $(@):latest .
	docker tag $(@):latest $(ECR)/$(@):latest
	docker push $(ECR)/$(@):latest

run:
	docker run --name ca --detach --publish 127.0.0.1:8888:8888 -v ${PWD}/rootca:/cfssl -e CFSSL_API_KEY=$(API_KEY) tykio/ca -loglevel 0

.PHONY: build run
