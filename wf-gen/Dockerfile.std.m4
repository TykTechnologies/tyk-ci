include(header.m4)
FROM debian:buster-slim
ARG TARGETARCH

RUN apt-get update \
 && apt-get dist-upgrade -y ca-certificates \
 && apt-get autoremove -y

COPY *${TARGETARCH}.deb /
RUN dpkg -i /xCOMPATIBILITY_NAME*${TARGETARCH}.deb

ARG PORTS

EXPOSE $PORTS

WORKDIR /opt/xCOMPATIBILITY_NAME/

ENTRYPOINT ["/opt/xCOMPATIBILITY_NAME/xREPO" ]
CMD [ "--conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf" ]
