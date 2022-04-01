include(header.m4)
FROM debian:buster-slim
ARG TARGETARCH

RUN apt-get update \
    && apt-get dist-upgrade -y ca-certificates

ifelse(xREPO, <<tyk>>,<<RUN apt-get install -y python3-setuptools libpython3.7 python3.7-dev curl \
    && curl https://bootstrap.pypa.io/get-pip.py | python3 \
    && rm -rf /usr/include/* && rm /usr/lib/*-linux-gnu/*.a && rm /usr/lib/*-linux-gnu/*.o \
    && rm /usr/lib/python3.7/config-3.7m-*-linux-gnu/*.a \
    && pip3 install --only-binary ":all:" grpcio protobuf \
    && apt-get autoremove -y \
    && rm -rf /root/.cache \
    && rm -rf /var/lib/apt/lists/*
>>)

COPY *${TARGETARCH}.deb /
RUN dpkg -i /xCOMPATIBILITY_NAME*${TARGETARCH}.deb && rm /*.deb

ARG PORTS

EXPOSE $PORTS

WORKDIR /opt/xCOMPATIBILITY_NAME/

ifelse(xREPO, <<portal>>,
ENTRYPOINT ["/opt/xCOMPATIBILITY_NAME/xBINARY" ],
ENTRYPOINT ["/opt/xCOMPATIBILITY_NAME/xREPO" ]
)
CMD [ "--conf=/opt/xCOMPATIBILITY_NAME/xCONFIG_FILE" ]
