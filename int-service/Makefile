all: integration
	./$<

integration: main.go
	go build -o $@

image: 
	docker build -t tykio/integration .
