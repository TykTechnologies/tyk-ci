include(header.m4)

ARG BASE_IMAGE=debian:buster-slim
ARG PORTS
ARG TARBALL

FROM $BASE_IMAGE

RUN apt-get update \
 && apt-get dist-upgrade -y ca-certificates \
 && apt-get autoremove -y

WORKDIR /opt/xCOMPATIBILITY_NAME
COPY $TARBALL .

EXPOSE $PORTS

ENTRYPOINT ["/opt/xCOMPATIBILITY_NAME/xREPO" ]
CMD [ "--conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf" ]
