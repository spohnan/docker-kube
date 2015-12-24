#!/usr/bin/env bash

# Container versions that may need to be adjusted
KUBE_VERSION=1.1.3
KUBE_UI_VERSION=4
ETCD_VERSION=2.2.1

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
KUBE_BIN=$SCRIPT_DIR/bin/kubectl
API_SERVER=http://localhost:8080

download_kube_bin() {
    if [ ! -f $KUBE_BIN ]; then
        echo "No kubectl found downloading ..."
        curl https://storage.googleapis.com/kubernetes-release/release/v${KUBE_VERSION}/bin/linux/amd64/kubectl > $KUBE_BIN
        chmod +x $KUBE_BIN
    fi
}

check_path_for_kubectl() {
    which $(basename $KUBE_BIN) > /dev/null 2>&1
    if [ $? != 0 ]; then
        echo "kubectl not found ... consider alias k8='${KUBE_BIN}'"
    fi
}

# Avoid race conditions and actually poll for availability of component dependencies
# Credit: http://stackoverflow.com/questions/8350942/how-to-re-run-the-curl-command-automatically-when-the-error-occurs/8351489#8351489
with_backoff() {
    local max_attempts=${ATTEMPTS-5}
    local timeout=${INTIAL_POLLING_INTERVAL-2}
    local attempt=0
    local exitCode=0

    while (( $attempt < $max_attempts ))
    do
        set +e
        "$@"
        exitCode=$?
        set -e

        if [[ $exitCode == 0 ]]; then
            break
        fi

        echo "Retrying $@ in $timeout.." 1>&2
        sleep $timeout
        attempt=$(( attempt + 1 ))
        timeout=$(( timeout * 2 ))
    done

    if [[ $exitCode != 0 ]]; then
        echo "Fail: $@ failed to complete after $max_attempts attempts" 1>&2
    fi

    return $exitCode
}

is_kube_api_available() {
    curl -m 2 ${API_SERVER} > /dev/null 2>&1
    return $?
}

start_kube_containers() {
    docker pull gcr.io/google_containers/pause:0.8.0

    docker run \
      --net=host \
      -d gcr.io/google_containers/etcd:${ETCD_VERSION} /usr/local/bin/etcd \
      --addr=127.0.0.1:4001 \
      --bind-addr=0.0.0.0:4001 \
      --data-dir=/var/etcd/data

    docker run \
        --volume=/sys:/sys:ro \
        --volume=/dev:/dev \
        --volume=/var/lib/docker/:/var/lib/docker:ro \
        --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
        --volume=/var/run:/var/run:rw \
        --net=host \
        --pid=host \
        --privileged=true \
        -d \
        gcr.io/google_containers/hyperkube:v${KUBE_VERSION} \
        /hyperkube kubelet --containerized --hostname-override="127.0.0.1" --address="0.0.0.0" --api-servers=${API_SERVER} --config=/etc/kubernetes/manifests

    docker run \
        -d --net=host \
        --privileged gcr.io/google_containers/hyperkube:v${KUBE_VERSION} /hyperkube proxy \
        --master=${API_SERVER}
}

start_kube_ui() {
    with_backoff is_kube_api_available
    if [ $? != 0 ]; then
        echo "kube API not available before timeout. Exiting ..."
        exit 1
    fi

    $KUBE_BIN run kube-ui --image=gcr.io/google_containers/kube-ui:v${KUBE_UI_VERSION} --port=8080
    $KUBE_BIN expose rc kube-ui --port=8080 --type=LoadBalancer
}

# Download start and show the current version
download_kube_bin
check_path_for_kubectl
start_kube_containers
start_kube_ui
$KUBE_BIN version
echo "View the UI at: http://localhost:8080/api/v1/proxy/namespaces/default/services/kube-ui/"
