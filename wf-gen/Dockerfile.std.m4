include(header.m4)
FROM debian:buster-slim
RUN apt-get update \
 && apt-get dist-upgrade -y ca-certificates \
 && apt-get autoremove -y

COPY *.deb /
RUN dpkg -i /*.deb && rm /*.deb

ARG PORTS

EXPOSE $PORTS

ENTRYPOINT ["/opt/xCOMPATIBILITY_NAME/xREPO" ]
CMD [ "--conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf" ]
