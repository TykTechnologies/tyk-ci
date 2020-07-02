define(xDATE, esyscmd(date))dnl
ifelse(The comment below is quoted so that it is not treated as a comment)dnl
`#' Generated on: xDATE
# Generated by: wf-gen from tyk-ci
FROM debian:buster-slim

ARG conf_file=/conf/xREPO/xREPO.conf

ADD xREPO.tar.gz /opt/xREPO

VOLUME ["/conf"]
WORKDIR /opt/xREPO

ENTRYPOINT ["/opt/xREPO/xREPO", "--conf=${conf_file}" ]

# Local Variables:
# mode: dockerfile
# End: