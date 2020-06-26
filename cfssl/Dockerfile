FROM golang:latest AS builder

ENV GOPATH "/go"
RUN CGO_ENABLED=0 go get -u github.com/cloudflare/cfssl/cmd/...

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /go/bin/* /usr/local/bin/
ENV PATH "${PATH}:/usr/local/bin"

EXPOSE 8888
VOLUME /cfssl
WORKDIR /cfssl

ENTRYPOINT [ "cfssl", "serve", "-address=0.0.0.0", "-port=8888", "-ca=rootca.pem", "-ca-key=rootca-key.pem", "-config=config.json" ]
CMD [ "-loglevel", "1" ]
