# Appd-Cassandra-DB

Deploy a multi node Cassandra DB cluster using Docker.

Instructions

Clone this repository

`git clone https://github.com/Appdynamics/Appd-Cassandra-DB.git`

The script `ctl.sh` performs all of the tasks using the configuration information in `envvars.sh`

Setup the Environment variables

`. envvars.sh`

Update Ubuntu OS

`./ctl.sh update-ubuntu`

Install the latest version of Docker CE, version 19.03.8 recommended

`./ctl.sh docker-install`

Build the Docker images

`./ctl.sh build`

Create the Cluster nodes

`./ctl.sh nodes-create`

Check the status of the cluster nodes, wait for the nodes to start and sync

`./ctl.sh nodes-status`

Create a keyspace, table and insert data

`./ctl.sh create-data`

Generate load on the DB - 5000 iterations at 5 seconds each

`./ctl.sh load-gen 5000 5`

Stop and delete the nodes

`./ctl.sh nodes-stop`
