include(header.m4)
FROM gcr.io/distroless/static-debian10
WORKDIR /opt/xCOMPATIBILITY_NAME

COPY xBINARY .

# Copy all the files required to run the binary. This should always
# match the `contents` list, minus the install/init scripts, in the
# nfpms build step in the goreleaser config.
ifelse(xREPO, <<tyk>>,
COPY tyk.conf.example xCONFIG_FILE
COPY apps/app_sample.json apps/
COPY templates/*.json templates/
COPY templates/playground/index.html templates/playground/
COPY templates/playground/playground.js templates/playground/
COPY middleware/*.js middleware/
COPY event_handlers/sample/*.js event_handlers/sample/
COPY policies/*.json policies/
COPY coprocess/* coprocess/
)
ifelse(xREPO, <<tyk-analytics>>,
COPY EULA.md EULA.md
COPY portal portal
COPY schemas schemas
COPY webclient/lang lang
COPY tyk_config_sample.config xCONFIG_FILE
)
ifelse(xREPO, <<tyk-pump>>,
COPY pump.example.conf xCONFIG_FILE
)
ifelse(xREPO, <<portal>>,
COPY app app
COPY themes themes
COPY public public
)dnl
ARG PORTS
EXPOSE $PORTS

ENTRYPOINT ["/opt/xCOMPATIBILITY_NAME/xBINARY" ]
CMD [ "--conf=/opt/xCOMPATIBILITY_NAME/xCONFIG_FILE" ]
