#!/bin/bash
#
#


CASSANDRA_CLUSTER_NAME="cluster1"
CASSANDRA_DATA_DIR="/tmp"
CASSANDRA_DC_NAME="DC1"
CASSANDRA_NODE_1="cnode1"
CASSANDRA_NODE_2="cnode2"
#CASSANDRA_NODE_3="cnode3"

docker run --name $CASSANDRA_NODE_1 \
       -p 9042:9042 \
       -v $CASSANDRA_DATA_DIR/node1:/var/lib/cassandra/data \
       -e CASSANDRA_CLUSTER_NAME=$CASSANDRA_CLUSTER_NAME \
       -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch \
       -e CASSANDRA_DC=$CASSANDRA_DC_NAME \
       -d cassandra:latest


docker run --name $CASSANDRA_NODE_2 \
       -v $CASSANDRA_DATA_DIR/node2:/var/lib/cassandra/data \
       -e CASSANDRA_SEEDS="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' $CASSANDRA_NODE_1)" \
       -e CASSANDRA_CLUSTER_NAME=$CASSANDRA_CLUSTER_NAME \
       -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch \
       -e CASSANDRA_DC=$CASSANDRA_DC_NAME \
       -d cassandra:latest

sleep 5
# Get Node 1 ID
NODE1_ID=`docker inspect --format='{{ .Id }}' cnode1`

docker exec -it $NODE1_ID nodetool status
