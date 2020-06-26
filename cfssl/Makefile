API_KEY ?= ${CFSSL_API_KEY}

build:
	docker build -t tykio/ca .

run:
	docker run --name ca --detach --publish 127.0.0.1:8888:8888 -v ${PWD}/rootca:/cfssl -e CFSSL_API_KEY=$(API_KEY) tykio/ca -loglevel 0

.PHONY: build run
