#!/bin/bash
#
#
# Maintainer: David Ryder, david.ryder@appdynamics.com


. envvars.sh

# Get Node 1 ID
NODE1_ID=`docker inspect --format='{{ .Id }}' cnode1`
INTERATIONS_N=1000
INTERVAL_SEC=5
for i in $(seq $INTERATIONS_N )
do
  docker exec -it $NODE1_ID cqlsh -f /tmp/query-db.cql
  sleep $INTERVAL_SEC
done
