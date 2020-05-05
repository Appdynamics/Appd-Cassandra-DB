#!/bin/bash
#
#
# Maintainer: David Ryder, david.ryder@appdynamics.com

. envvars.sh

# Copy in CQL files
docker cp show-version.cql $CASSANDRA_NODE_1:/tmp
docker cp create-db.cql $CASSANDRA_NODE_1:/tmp


# Get Node 1 ID
NODE1_ID=`docker inspect --format='{{ .Id }}' cnode1`

docker exec -it $NODE1_ID nodetool status

# Copy in CQL files
docker cp *.cql $CASSANDRA_NODE_1:/tmp

# Create keyspace, table and insert data
docker exec -it $NODE1_ID cqlsh -f /tmp/create-data.cql
