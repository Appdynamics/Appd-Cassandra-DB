#!/bin/bash
#
#
# Maintainer: David Ryder, david.ryder@appdynamics.com


. envvars.sh

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
