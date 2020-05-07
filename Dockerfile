FROM cassandra:latest

# Modify Cassandra configuration to allow authentication
#RUN sed -i 's/^authenticator.\+$/authenticator: PasswordAuthenticator/g' /etc/cassandra/cassandra.yaml
ARG CASSANDRA_CONFIG_DIR

RUN apt-get update -yqq   &&  \
    apt-get upgrade -yqq  &&  \
    apt-get install -yqq  build-essential vim curl wget \
    net-tools iputils-ping

COPY *.cql                ${CASSANDRA_CONFIG_DIR}/
COPY ctl.sh               ${CASSANDRA_CONFIG_DIR}/
COPY envvars.sh           ${CASSANDRA_CONFIG_DIR}/
COPY cassandra.yaml	      ${CASSANDRA_CONFIG_DIR}/
COPY cassandra-env.sh     ${CASSANDRA_CONFIG_DIR}/
COPY jmxremote.password   ${CASSANDRA_CONFIG_DIR}/
COPY jmxremote.access     ${CASSANDRA_CONFIG_DIR}/

RUN cd ${CASSANDRA_CONFIG_DIR}; ./ctl.sh cassandra-configure
