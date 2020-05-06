#!/bin/bash
#
#
# Maintainer: David Ryder, david.ryder@appdynamics.com
#
#
CMD_LIST=${1:-"help"}

. envvars.sh

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

_cassandra_nodes_create() {
  docker run --rm --name $CASSANDRA_NODE_1 \
         -p 9042:9042 \
         -v "$CASSANDRA_DATA_DIR/$CASSANDRA_NODE_1":/var/lib/cassandra/data \
         -e CASSANDRA_CLUSTER_NAME=$CASSANDRA_CLUSTER_NAME \
         -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch \
         -e CASSANDRA_DC=$CASSANDRA_DC_NAME \
         -d cassandra:latest
  sleep 5
  NODE1_IP=`docker inspect --format='{{ .NetworkSettings.IPAddress }}' $CASSANDRA_NODE_1`
  echo "Node 1 IP $NODE1_IP"

  docker run --rm --name $CASSANDRA_NODE_2 \
         -v "$CASSANDRA_DATA_DIR/$CASSANDRA_NODE_2":/var/lib/cassandra/data \
         -e CASSANDRA_SEEDS="$NODE1_IP" \
         -e CASSANDRA_CLUSTER_NAME=$CASSANDRA_CLUSTER_NAME \
         -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch \
         -e CASSANDRA_DC=$CASSANDRA_DC_NAME \
         -d cassandra:latest
  sleep 5

  NODE2_IP=`docker inspect --format='{{ .NetworkSettings.IPAddress }}' $CASSANDRA_NODE_2`
  echo "Node 2 IP $NODE2_IP"

  # Get Node 1 ID
  NODE1_ID=`docker inspect --format='{{ .Id }}' cnode1`
  docker exec -it $NODE1_ID nodetool status
}

_cassandra_nodes_stop() {
  NODE1_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_1`
  NODE2_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_2`

  echo $NODE1_ID
  echo $NODE2_ID

  docker stop  $NODE1_ID
  docker stop  $NODE2_ID

  rm -rf  $CASSANDRA_DATA_DIR/C$ASSANDRA_NODE_1
  rm -rf  $CASSANDRA_DATA_DIR/C$ASSANDRA_NODE_2
}

_cassandra_create_data() {
  # Copy in CQL files
  docker cp show-version.cql $CASSANDRA_NODE_1:/tmp
  docker cp create-db.cql    $CASSANDRA_NODE_1:/tmp
  docker cp query-db.cql    $CASSANDRA_NODE_1:/tmp


  # Get Node 1 ID
  NODE1_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_1`

  docker exec -it $NODE1_ID nodetool status

  # Create keyspace, table and insert data
  docker exec -it $NODE1_ID cqlsh -f /tmp/create-db.cql
}


_cassandra_load_gen() {
  # Get Node 1 ID
  NODE1_ID=`docker inspect --format='{{ .Id }}' cnode1`
  INTERATIONS_N=${2:-"2"}
  INTERVAL_SEC=${3:-"5"}
  echo "Iterations $INTERATIONS_N Interval $INTERVAL_SEC"
  for i in $(seq $INTERATIONS_N )
  do
    docker exec -it $NODE1_ID cqlsh -f /tmp/query-db.cql
    sleep $INTERVAL_SEC
  done
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
  nodes-create)
  _cassandra_nodes_create
    ;;
  nodes-status)
    NODE1_ID=`docker inspect --format='{{ .Id }}' cnode1`
    docker exec -it $NODE1_ID nodetool status
    ;;
  nodes-stop)
    _cassandra_nodes_stop
    ;;
  create-data)
    _cassandra_create_data
    ;;
  load-gen)
    _cassandra_load_gen $@
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
    echo "ubuntu-update, docker-install, nodes-create, nodes-status, nodes-stop"
    ;;
  *)
    echo "Not Found " "$@"
    ;;
esac
