#!/bin/bash
#
#
# Maintainer: David Ryder, david.ryder@appdynamics.com


. envvars.sh

# Get Node 1 ID
NODE1_ID=`docker inspect --format='{{ .Id }}' cnode1`
docker exec -it $NODE1_ID nodetool status
