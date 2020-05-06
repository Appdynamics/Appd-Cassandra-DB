# Appd-Cassandra-DB

Deploy a multi node Cassandra DB cluster1

Instructions

Clone this repository

`git clone ...`

Setup the Environment variables

`. envvars.sh`

Update Ubuntu OS

`ctl.sh update-ubuntu`

Install latest version of Docker CE

`ctl.sh docker install`

Build the Docker images

`./ctl.sh build`

Create the Cluster nodes

`./ctl.sh nodes-create`

Check the status of the cluster nodes, wait for the nodes to start and sync

`./ctl.sh nodes-status`

Create a keyspace, table and insert data

`./ctl.sh create-date`

Generate load on the DB

`./ctl.sh load-gen 5 1`
