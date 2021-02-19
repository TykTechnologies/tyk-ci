include(header.m4)
FROM gcr.io/distroless/static-debian10
WORKDIR /opt/xREPO
COPY xREPO .
ifelse(xREPO, <<tyk>>,
COPY apps/app_sample.json apps/app_sample.json
COPY tyk.conf.example tyk.conf,
xREPO, <<tyk-analytics>>,
COPY portal schemas webclient/lang ./
COPY tyk_config_sample.config tyk-analytics.conf,
xREPO, <<tyk-pump>>,
COPY pump.example.conf tyk-pump.conf)
ARG PORTS
EXPOSE $PORTS

ENTRYPOINT ["/opt/xREPO/xREPO" ]
CMD [ "--conf=/opt/xREPO/xREPO.conf" ]
