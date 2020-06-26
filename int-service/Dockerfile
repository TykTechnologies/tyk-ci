FROM golang:latest AS builder

ENV GOPATH "/go"
WORKDIR ${GOPATH}/src/integration
COPY . .
RUN go mod download && CGO_ENABLED=0 go build -o /integration

FROM alpine:latest
COPY --from=builder /integration /usr/local/bin/
ENV PATH "${PATH}:/usr/local/bin"

EXPOSE 8443
VOLUME /cfssl/certs
WORKDIR /cfssl

ENTRYPOINT [ "integration" ]
CMD [ "-certpath=certs" ]
