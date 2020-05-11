#!/bin/bash
#
# Deploys using Docker a multi node Cassandra cluster.
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
         -p 7199:7199 \
         -v "$CASSANDRA_DATA_DIR/$CASSANDRA_NODE_1":/var/lib/cassandra/data \
         -e CASSANDRA_CLUSTER_NAME=$CASSANDRA_CLUSTER_NAME \
         -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch \
         -e CASSANDRA_DC=$CASSANDRA_DC_NAME \
         -d $DOCKER_TAG_NAME
  sleep 5
  NODE1_IP=`docker inspect --format='{{ .NetworkSettings.IPAddress }}' $CASSANDRA_NODE_1`
  echo "Node 1 IP $NODE1_IP"

  docker run --rm --name $CASSANDRA_NODE_2 \
         -v "$CASSANDRA_DATA_DIR/$CASSANDRA_NODE_2":/var/lib/cassandra/data \
         -e CASSANDRA_SEEDS="$NODE1_IP" \
         -e CASSANDRA_CLUSTER_NAME=$CASSANDRA_CLUSTER_NAME \
         -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch \
         -e CASSANDRA_DC=$CASSANDRA_DC_NAME \
         -d $DOCKER_TAG_NAME
  sleep 5

  NODE2_IP=`docker inspect --format='{{ .NetworkSettings.IPAddress }}' $CASSANDRA_NODE_2`
  echo "Node 2 IP $NODE2_IP"

  # Get Node 1 ID
  NODE1_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_1`
  docker exec -it $NODE1_ID nodetool -u $CASSANDRA_JMX_USER -pw $CASSANDRA_JMX_PWD status
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
  # Get Node 1 ID
  NODE1_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_1`

  docker exec -it $NODE1_ID nodetool -u $CASSANDRA_JMX_USER -pw $CASSANDRA_JMX_PWD status

  # Create keyspace, table and insert data
  docker exec -it $NODE1_ID cqlsh -u $CASSANDRA_DB_USER -p $CASSANDRA_DB_PWD -f $CASSANDRA_CONFIG_DIR/create-db.cql
}


_cassandra_load_gen_read() {
  # Get Node 1 ID
  NODE1_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_1`
  INTERATIONS_N=${2:-"2"}
  INTERVAL_SEC=${3:-"5"}
  echo "Iterations $INTERATIONS_N Interval $INTERVAL_SEC"
  for i in $(seq $INTERATIONS_N )
  do
    docker exec -it $NODE1_ID cqlsh -u $CASSANDRA_DB_USER -p $CASSANDRA_DB_PWD -f $CASSANDRA_CONFIG_DIR/query-db.cql
    sleep $INTERVAL_SEC
  done
}

_cassandra_load_gen_insert() {
  # Get Node 1 ID
  NODE_ID=$(_docker_get_container_id $CASSANDRA_NODE_1 )
  INTERATIONS_N=${2:-"2"}
  INTERVAL_SEC=${3:-"5"}
  echo "Iterations $INTERATIONS_N Interval $INTERVAL_SEC"
  for i in $(seq $INTERATIONS_N )
  do
    DATA_ID=$((RANDOM % 10000))
    DATA_V1=`uuidgen | cut -c 1-13`
    DATA_V2=`uuidgen | cut -c 1-13`
    docker exec -it $NODE_ID cqlsh -u $CASSANDRA_DB_USER -p $CASSANDRA_DB_PWD \
      -e "use Test1_keyspace; TRACING ON; insert into Test1_table(id,v1,v2) VALUES ($DATA_ID,'$DATA_V1','$DATA_V2');"
    sleep $INTERVAL_SEC
  done
}

_cassandra_load_gen() {
  # Get Node 1 ID
  NODE_ID=$(_docker_get_container_id $CASSANDRA_NODE_1 )
  INTERATIONS_N=${2:-"2"}
  INTERVAL_SEC=${3:-"5"}
  echo "Iterations $INTERATIONS_N Interval $INTERVAL_SEC"
  for i in $(seq $INTERATIONS_N ); do
    echo "$i"
    if [ $((RANDOM % 10)) -gt 6 ]; then
      DATA_ID=$((RANDOM % 10000))
      DATA_V1=`uuidgen | cut -c 1-13`
      DATA_V2=`uuidgen | cut -c 1-13`
      docker exec -it $NODE_ID cqlsh -u $CASSANDRA_DB_USER -p $CASSANDRA_DB_PWD \
        -e "use Test1_keyspace; insert into Test1_table(id,v1,v2) VALUES ($DATA_ID,'$DATA_V1','$DATA_V2');"
    else
      docker exec -it $NODE_ID cqlsh -u $CASSANDRA_DB_USER -p $CASSANDRA_DB_PWD \
        -e "use Test1_keyspace; TRACING ON; select count(*) from Test1_table;"
    fi
    sleep $INTERVAL_SEC
  done
}

_cassandra_configure() {
  # Copy conf files
  cp $CASSANDRA_CONFIG_DIR/cassandra.yaml       /etc/cassandra
  cp $CASSANDRA_CONFIG_DIR/cassandra-env.sh     /etc/cassandra
  cp $CASSANDRA_CONFIG_DIR/jmxremote.password   /etc/cassandra
  cp $CASSANDRA_CONFIG_DIR/jmxremote.access     /etc/cassandra
  # Permissions
  chmod 400 /etc/cassandra/jmxremote.password
  chmod 400 /etc/cassandra/jmxremote.access
}

_docker_get_container_id() {
  CONTAINER_NAME=$1
  echo `docker inspect --format='{{ .Id }}' $CONTAINER_NAME`
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
  build)
    docker build --build-arg CASSANDRA_CONFIG_DIR=${CASSANDRA_CONFIG_DIR} -t $DOCKER_TAG_NAME .
    ;;
  nodes-create)
  _cassandra_nodes_create
    ;;
  nodes-status)
    NODE1_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_1`
    docker exec -it $NODE1_ID nodetool -u $CASSANDRA_JMX_USER -pw $CASSANDRA_JMX_PWD status
    docker exec -it $NODE1_ID cqlsh -u $CASSANDRA_DB_USER -p $CASSANDRA_DB_PWD -f $CASSANDRA_CONFIG_DIR/show-version.cql
    ;;
  nodes-stop)
    _cassandra_nodes_stop
    ;;
  nodes-trace)
    NODE1_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_1`
    docker exec -it $NODE1_ID nodetool -u $CASSANDRA_JMX_USER -pw $CASSANDRA_JMX_PWD settraceprobability 1
    docker exec -it $NODE1_ID nodetool -u $CASSANDRA_JMX_USER -pw $CASSANDRA_JMX_PWD gettraceprobability
    # setlogginglevel org.apache.cassandra.transport TRACE
    ;;
  create-data)
    _cassandra_create_data
    ;;
  bash)
    NODE_NAME=${2:-$CASSANDRA_NODE_1}
    NODE_ID=`docker inspect --format='{{ .Id }}' $NODE_NAME`
    docker exec -it $NODE_ID bash
    ;;
  cqlsh)
    NODE_NAME=${2:-$CASSANDRA_NODE_1}
    NODE_ID=$(_docker_get_container_id $NODE_NAME )
    docker exec -it $NODE_ID cqlsh -u $CASSANDRA_DB_USER -p $CASSANDRA_DB_PWD
    ;;
  load-gen)
    _cassandra_load_gen $@
    ;;
  cassandra-configure)
    _cassandra_configure
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
    echo "ubuntu-update, docker-install, nodes-create, nodes-status, nodes-stop, create-data, load-gen"
    ;;
  *)
    echo "Not Found " "$@"
    ;;
esac
