#!/bin/bash
#
#
# Maintainer: David Ryder, david.ryder@appdynamics.com
#
#
CMD_LIST=${1:-"help"}

_Ubuntu_Update() {
  # Update Ubuntu - quiet install, non noninteractive
  sudo apt-get update
  DEBIAN_FRONTEND=noninteractive sudo apt-get -yqq upgrade
  DEBIAN_FRONTEND=noninteractive sudo apt-get -yqq install zip
}

_DockerCE_Install() {
  # Install Docker CE V19+ for Ubuntu
  # https://docs.docker.com/install/linux/docker-ce/ubuntu/

  # Install DockerCE
  sudo apt install -yqq apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
  apt-cache policy docker-ce
  sudo apt -yqq install docker-ce
  # Need to exit shell/ssh session for the following command to take effect
  sudo usermod -aG docker ${USER}
  echo ""
  echo ">>>> Exit current session: shell/ssh, and re-enter for previous usermod command to work <<<<"

  # Validate Docker Version and status
  #docker version

  #sudo systemctl status docker

  # Pull Ubuntu Docker image into local repository
  #docker pull ubuntu
  #docker images
  #docker search ubuntu
}

_validateEnvironmentVars() {
  echo "Validating environment variables for $1"
  shift 1
  VAR_LIST=("$@") # rebuild using all args
  #echo $VAR_LIST
  for i in "${VAR_LIST[@]}"; do
    echo "$i=${!i}"
    if [ -z ${!i} ] || [[ "${!i}" == REQUIRED_* ]]; then
       echo "Please set the Environment variable: $i"; ERROR="1";
    fi
  done
  [ "$ERROR" == "1" ] && { echo "Exiting"; exit 1; }
}

# Define the namespace and list of K8s resources to deploy into that namespace
ALL_NS_LIST=("namespace-test")
ALL_RUN_LIST=("alpine1" "alpine2" "busyboxes1" "busyboxes2")

# Execute command
case "$CMD_LIST" in
  ubuntu-update)
    _Ubuntu_Update
    ;;
  docker-install)
    _DockerCE_Install
    ;;
  services)
    $KUBECTL_CMD get services --all-namespaces -o wide
    ;;
  ns)
    $KUBECTL_CMD get all --all-namespaces
    ;;
  del-force)
    docker rmi $(docker images -q) -f
    docker system prune --all --force
    ;;
  group-remove)
    # Testing
    sudo gpasswd -d $USER microk8s
    sudo gpasswd -d $USER docker
    ;;
  test)
    echo "Test"
    ;;
  help)
    echo "ubuntu-update, docker-install, k8s-install, k8s-start, pods-create, appd-create-cluster-agent, appd-delete-cluster-agent"
    ;;
  *)
    echo "Not Found " "$@"
    ;;
esac
