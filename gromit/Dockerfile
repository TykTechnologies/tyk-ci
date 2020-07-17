FROM golang:latest AS builder

ENV GOPATH "/go"
WORKDIR ${GOPATH}/src/gromit
COPY . .
RUN go mod download && CGO_ENABLED=0 go build -o /gromit

FROM alpine:latest
COPY --from=builder /gromit /usr/local/bin/
ENV PATH "${PATH}:/usr/local/bin"

EXPOSE 8443
VOLUME /cfssl
WORKDIR /cfssl

ENTRYPOINT [ "gromit" ]
CMD [ "-ca=rootca.pem", "-cert=server.pem", "-key=server-key.pem" ]
