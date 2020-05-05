#!/bin/bash
#
#
# Maintainer: David Ryder, david.ryder@appdynamics.com


. envvars.sh

NODE1_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_1`
NODE2_ID=`docker inspect --format='{{ .Id }}' $CASSANDRA_NODE_2`

echo $NODE1_ID
echo $NODE2_ID

docker stop  $NODE1_ID
docker stop  $NODE2_ID

rm -rf  $CASSANDRA_DATA_DIR/C$ASSANDRA_NODE_1
rm -rf  $CASSANDRA_DATA_DIR/C$ASSANDRA_NODE_2
