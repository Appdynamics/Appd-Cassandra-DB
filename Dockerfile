FROM cassandra:latest

# Modify Cassandra configuration to allow authentication
RUN sed -i 's/^authenticator.\+$/authenticator: PasswordAuthenticator/g' /etc/cassandra/cassandra.yaml

COPY *.cql /
