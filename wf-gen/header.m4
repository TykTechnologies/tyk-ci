define(xDATE, esyscmd(date -u))dnl
changequote(<<, >>)dnl
dnl xCOMPATIBILITY_NAME is the legacy directory that the code is installed in. For new repos, use the repo name. The use of this parameter should reduce.
define(<<xCOMPATIBILITY_NAME>>, <<ifelse(xREPO, <<tyk>>, <<tyk-gateway>>, xREPO, <<tyk-analytics>>, <<tyk-dashboard>>, xREPO)>>)dnl
dnl The repository in Docker Hub defaults to xCOMPATIBILITY_NAME
define(<<xDH_REPO>>, <<ifelse(xREPO, <<tyk-pump>>, <<tyk-pump-docker-pub>>, xREPO, <<tyk-sink>>, <<tyk-mdcb-docker>>, xCOMPATIBILITY_NAME)>>)dnl
define(<<xPC_REPO>>, <<ifelse(xREPO, <<tyk-sink>>, <<tyk-mdcb>>, xCOMPATIBILITY_NAME)>>)dnl
define(<<xCGO>>, ifelse(xREPO, <<tyk>>, <<1>>, xREPO, <<tyk-analytics>>, <<1>>,  xREPO, <<raava>>, <<1>>, <<0>>))dnl
define(<<xCONFIG_FILE>>, <<ifelse(xREPO, <<tyk-analytics>>, <<tyk_analytics.conf>>, xREPO, <<tyk-sink>>, <<tyk_sink.conf>>, xREPO.conf)>>)dnl
dnl The comments below are quoted so that they are not treated as comments
<<#>> Generated by: tyk-ci/wf-gen
<<#>> Generated on: xDATE
<<#>> Generation commands:
<<#>> xPR_CMD_LINE
<<#>> xM4_CMD_LINE
