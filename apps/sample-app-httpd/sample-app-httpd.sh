#!/bin/sh
set -e -u -o pipefail

declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)

declare -r NAMESPACE=${NAMESPACE:-eazytraining}

_log() {
    local level=$1; shift
    echo  "$level: $@"
}

log_err() {
    _log "ERROR" "$@" >&2
}

info() {
    _log "\nINFO" "$@"
}

err() {
    local code=$1; shift
    local msg="$@"; shift
    log_err $msg
    exit $code
}

sample_app_validate_tools() {
  info "validating tools"
  echo " "
  oc version  >/dev/null 2>&1 || err 1 "no oc binary found"
  return 0
}

bootstrapping() {
    sample_app_validate_tools
    info "ensure namespace $NAMESPACE exists"
    echo " "
    oc get ns "$NAMESPACE" 2>/dev/null  || {
      oc new-project $NAMESPACE
    }
}

sample_app_deploy_build_config_pipeline() {
  cd "$SCRIPT_DIR/openshift/templates"
  bootstrapping
  info "Deploying Build Config Pipeline"
  echo " "
  oc -n "$NAMESPACE" process -f sample-app-httpd.yaml | oc -n "$NAMESPACE" apply -f - 
  info "Build Config Pipeline"
  echo "==============================================="
  echo " "
  local pod_status=`oc -n $NAMESPACE get pods --field-selector=status.phase!=Running --ignore-not-found`

  if [[ -z $pod_status ]]; then
     log_err "There is something wrong inside your build config pipeline. Please check logs of containers !"
     exit 1  
  fi
}

sample_app_url(){
  info "Click the following URL to access the application"
  echo " "
  oc -n "$NAMESPACE" get route route-eazytraining-httpd --template='http://{{.spec.host}} '
  echo " " 
}

sample_app_deploy_build_config_pipeline 
sample_app_url