FROM cassandra:latest

# Maintainer: David Ryder, david.ryder@appdynamics.com

# Dir for confi files
ARG CASSANDRA_CONFIG_DIR

# OS Updates
RUN apt-get update -yqq   &&  \
    apt-get upgrade -yqq  &&  \
    apt-get install -yqq  build-essential vim curl wget \
    net-tools iputils-ping

# Copy in config files
COPY *.cql                ${CASSANDRA_CONFIG_DIR}/
COPY ctl.sh               ${CASSANDRA_CONFIG_DIR}/
COPY envvars.sh           ${CASSANDRA_CONFIG_DIR}/
COPY cassandra.yaml	      ${CASSANDRA_CONFIG_DIR}/
COPY cassandra-env.sh     ${CASSANDRA_CONFIG_DIR}/
COPY jmxremote.password   ${CASSANDRA_CONFIG_DIR}/
COPY jmxremote.access     ${CASSANDRA_CONFIG_DIR}/

# Configure
RUN cd ${CASSANDRA_CONFIG_DIR}; ./ctl.sh cassandra-configure
