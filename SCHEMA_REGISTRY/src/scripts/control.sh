#!/bin/bash

set -x

DEFAULT_SCHEMA_REGISTRY_HOME=/usr/share/java/schema-registry
SCHEMA_REGISTRY_HOME=${SCHEMA_REGISTRY_HOME:-$DEFAULT_SCHEMA_REGISTRY_HOME}

# Example first line of version file: version=0.1.0-3.2.2
SCHEMA_REGISTRY_VERSION=$(grep "^version=" $SCHEMA_REGISTRY_HOME/cloudera/cdh_version.properties | cut -d '=' -f 2)
echo "Confluent Schema Registry version found: ${SCHEMA_REGISTRY_VERSION}"

# Generating Zookeeper quorum
QUORUM=$ZK_QUORUM
if [[ -n $CHROOT ]]; then
  QUORUM="${QUORUM}${CHROOT}"
fi

# Add Listener
if [[ ${SSL_ENABLED} == "true" ]]; then
    LISTENERS="https://0.0.0.0:${SSL_PORT}"
else
    LISTENERS="http://0.0.0.0:${PORT}"
fi

# Define log4j.properties
LOG_DIR=/var/log/schema-registry
SCHEMA_REGISTRY_LOG4J_OPTS="-Dlog4j.configuration=file:$CONF_DIR/log4j.properties"
export SCHEMA_REGISTRY_LOG4J_OPTS="-Dschema-registry.log.dir=$LOG_DIR $SCHEMA_REGISTRY_LOG4J_OPTS"
SCHEMA_REGISTRY_CONF_FILE=$CONF_DIR/schema-registry-conf/schema-registry.properties

echo -e "######################################################################################"
echo -e "# PARROT DISTRIBUTION - SCHEMA REGISTRY"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# DATE:                       `date`"
echo -e "# PORT:                       $PORT"
echo -e "# HOST:                       $HOST"
echo -e "# PWD:                        `pwd`"
echo -e "# CONF_DIR:                   $CONF_DIR"
echo -e "# CONF_FILE:                  $CONF_FILE"
echo -e "# SCHEMA_REGISTRY_HOME:       $SCHEMA_REGISTRY_HOME"
echo -e "# SCHEMA_REGISTRY_VERSION:    $SCHEMA_REGISTRY_VERSION"
echo -e "# SCHEMA_REGISTRY_LOG4J_OPTS: $SCHEMA_REGISTRY_LOG4J_OPTS"
echo -e "# ZK_QUORUM:                  $QUORUM"
echo -e "#-------------------------------------------------------------------------------------"
echo -e "# SSL_ENABLED:                $SSL_ENABLED"
echo -e "# SSL_PORT:                   $SSL_PORT"
echo -e "# SSL_KEYSTORE_LOCATION:      $SSL_KEYSTORE_LOCATION"
echo -e "# SSL_KEYSTORE_PASSWORD:      $SSL_KEYSTORE_PASSWORD"
echo -e "# SSL_TRUSTSTORE_LOCATION:    $SSL_TRUSTSTORE_LOCATION"
echo -e "# SSL_TRUSTSTORE_PASSWORD:    $SSL_TRUSTSTORE_PASSWORD"
echo -e "######################################################################################"

# Replace kafkastore.connection.url placeholder with ZooKeeper Quorum
perl -pi -e "s#\#kafkastore.connection.url={{QUORUM}}#kafkastore.connection.url=${QUORUM}#" $SCHEMA_REGISTRY_CONF_FILE

# Replace listeners placeholder with LISTENERS
perl -pi -e "s#\#listeners={{LISTENERS}}#listeners=${LISTENERS}#" $SCHEMA_REGISTRY_CONF_FILE

# Run Confluent Schema Registry
exec $SCHEMA_REGISTRY_HOME/bin/schema-registry-start $SCHEMA_REGISTRY_CONF_FILE
