include(header.m4)
FROM gcr.io/distroless/static-debian10
WORKDIR /opt/xREPO
ifelse(xREPO, <<portal>>,
COPY xBINARY .,
COPY xREPO .
)
ifelse(xREPO, <<tyk>>,
COPY apps/app_sample.json apps/app_sample.json
COPY tyk.conf.example tyk.conf,
xREPO, <<tyk-analytics>>,
COPY portal schemas webclient/lang ./
COPY tyk_config_sample.config tyk-analytics.conf,
xREPO, <<tyk-pump>>,
COPY pump.example.conf tyk-pump.conf,
xREPO, <<portal>>,
COPY app app
COPY themes themes
COPY public public
)
ARG PORTS
EXPOSE $PORTS

ifelse(xREPO, <<portal>>,
ENTRYPOINT ["/opt/xCOMPATIBILITY_NAME/xBINARY" ],
ENTRYPOINT ["/opt/xCOMPATIBILITY_NAME/xREPO" ]
)
CMD [ "--conf=/opt/xCOMPATIBILITY_NAME/xCONFIG_FILE" ]
