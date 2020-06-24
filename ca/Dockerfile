FROM golang:latest AS builder

RUN go get -u github.com/cloudflare/cfssl/cmd/...

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /go/bin/* /usr/bin/

VOLUME /cfssl
WORKDIR /cfssl
COPY rootca/ /cfssl/
RUN [ -f /cfssl/rootca/key.pem ] || cfssl gencert -initca rootca/csr.json | cfssljson -bare rootca
ENTRYPOINT [ "cfssl", "serve", "-ca", "rootca.pem", "-ca-key", "rootca-key.pem" ]
