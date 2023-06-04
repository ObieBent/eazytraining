#!/bin/bash
# This starts the pipeline new-pipeline with a given 

set -e -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare COMMAND="help"

GIT_URL=http://gitlab.eazytraining.lab/boass/eazytraining.git
GIT_REVISION=main
PIPELINE=gitops-dev-pipeline
CONTEXT_DIR='gitops/tekton'
IMAGE_NAME=image-registry.openshift-image-registry.svc:5000/eazytraining/dck_eazytraining-lab-http-simple-wow
TARGET_NAMESPACE=eazytraining

valid_command() {
  local fn=$1; shift
  [[ $(type -t "$fn") == "function" ]]
}

info() {
    printf "\n# INFO: $@\n"
}

err() {
  printf "\n# ERROR: $1\n"
  exit 1
}

command.help() {
  cat <<-EOF
  Starts a new pipeline in current kubernetes context

  Usage:
      pipeline.sh [command] [options]
  
  Examples:
      pipeline.sh init  # installs and creates all tasks, pvc and secrets
      pipeline.sh start -t art-tekton
      pipeline.sh stage -r 1.2.3 
      pipeline.sh logs
  
  COMMANDS:
      init                           creates ConfigMap, Tasks and Pipelines into current context
                                     it also creates a secret with -u/-p user/pwd for GitHub.com access
      start                          starts the given pipeline
      stage                          starts the stage pipeline and creates a release in quay.io and github
      logs                           shows logs of the last pipeline run
      help                           Help about this command

  OPTIONS:
      -c, --context-dir             Which context-dir to user ($CONTEXT_DIR)
      -t, --target-namespace        Which target namespace to start the app ($TARGET_NAMESPACE)
      -g, --git-repo                Which quarkus repository to clone ($GIT_URL)
      -r, --git-revision            Which git revision to use ($GIT_REVISION)
      
EOF
}

command.test() {
  cat > /tmp/tr.yaml <<-EOF
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: git-test-run-$(date "+%Y%m%d-%H%M%S")
spec:
  params:
    - name: kustomize-dir
      value: config/overlays/dev
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: builder-pvc      
  serviceAccountName: pipeline-bot
  taskRef:
    name: extract-kustomize-digest
EOF

oc apply -f /tmp/tr.yaml
}



while (( "$#" )); do
  case "$1" in
    start|logs|init|test|stage)
      COMMAND=$1
      shift
      ;;
    -c|--context-dir)
      CONTEXT_DIR=$2
      shift 2
      ;;
    -t|--target-namespace)
      TARGET_NAMESPACE=$2
      shift 2
      ;;
    -g|--git-repo)
      GIT_URL=$2
      shift 2
      ;;
    -r|--git-revision)
      GIT_REVISION=$2
      shift 2
      ;;
    -l|--pipeline)
      PIPELINE=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*|--*)
      command.help
      err "Error: Unsupported flag $1"
      ;;
    *) 
      break
  esac
done


command.init() {
  # This script imports the necessary files into the current project 
  
  oc apply -f infra/ns.yaml
  oc apply -f infra/pvc.yaml
  oc apply -f infra/sa.yaml
  oc apply -f infra/route-elistener.yaml

  oc apply -f tkn-tasks/kustomize-task.yaml
  oc apply -f tkn-tasks/extract-digest-task.yaml
  oc apply -f tkn-tasks/extract-digest-from-kustomize-task.yaml
  
  oc apply -f tkn-tasks/git-update-deployment.yaml
  oc apply -f tkn-tasks/bash-task.yaml

  oc apply -f pipelines/tekton-pipeline.yaml
}


command.logs() {
    tkn pr logs -f -L
}

command.start() {
  cat > /tmp/pipelinerun.yaml <<-EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: $PIPELINE-run-$(date "+%Y%m%d-%H%M%S")
spec:
  params:
    - name: git-url
      value: '$GIT_URL'
    - name: git-revision
      value: $GIT_REVISION
    - name: context-dir
      value: $CONTEXT_DIR
    - name: image-name
      value: $IMAGE_NAME
    - name: target-namespace
      value: $TARGET_NAMESPACE
  workspaces:
    - name: shared-workspace
      persistentVolumeClaim:
        claimName: builder-pvc 
    - configMap:
        name: maven-settings
      name: maven-settings
  pipelineRef:
    name: $PIPELINE
  serviceAccountName: pipeline-bot
EOF

    oc apply -f /tmp/pipelinerun.yaml
}


command.stage() {
  cat > /tmp/pipelinerun.yaml <<-EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: gitops-stage-release-run-$(date "+%Y%m%d-%H%M%S")
spec:
  params:
    - name: release-name
      value: $GIT_REVISION
  workspaces:
    - name: shared-workspace
      persistentVolumeClaim:
        claimName: builder-pvc 
  pipelineRef:
    name: gitops-stage-release
  serviceAccountName: pipeline-bot
EOF

    oc apply -f /tmp/pipelinerun.yaml
}

main() {
  local fn="command.$COMMAND"
  valid_command "$fn" || {
    command.help
    err "invalid command '$COMMAND'"
  }

  cd $SCRIPT_DIR
  $fn
  return $?
}

main