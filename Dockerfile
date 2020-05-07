FROM cassandra:latest

# Modify Cassandra configuration to allow authentication
#RUN sed -i 's/^authenticator.\+$/authenticator: PasswordAuthenticator/g' /etc/cassandra/cassandra.yaml
ARG CASSANDRA_CONFIG_DIR

COPY *.cql            ${CASSANDRA_CONFIG_DIR}/
COPY ctl.sh           ${CASSANDRA_CONFIG_DIR}/
COPY envvars.sh       ${CASSANDRA_CONFIG_DIR}/
COPY cassandra.yaml	  ${CASSANDRA_CONFIG_DIR}/
COPY cassandra-env.sh ${CASSANDRA_CONFIG_DIR}/

RUN cd ${CASSANDRA_CONFIG_DIR}; ./ctl.sh configure-cassandra
