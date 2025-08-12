#!/bin/bash

source .env
source hosts

IFS=","  # comma-separated string split
COORDINATOR_NODE="0"
ADDITIONAL_NODES="1"
ALL_NODES="${COORDINATOR_NODE},${ADDITIONAL_NODES}"

echo "Enabling standalone mode on all nodes..."
for NODE_ID in ${ALL_NODES}; do
  if [ "$NODE_ID" == "0" ]; then
    HOST=$NODE_01_HOST
  else
    HOST=$NODE_02_HOST
  fi

  echo "Configuring node $NODE_ID at $HOST:${PORT_BASE}${NODE_ID}..."

  curl -X POST -H "Content-Type: application/json" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/_cluster_setup" \
    -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "'"${COUCHDB_USER}"'", "password":"'"${COUCHDB_PASSWORD}"'", "node_count": "1"}'

  curl -X POST -H "Content-Type: application/json" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/_cluster_setup" \
    -d '{"action": "finish_cluster"}'

  curl "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/_membership"
  echo
done

echo "Creating database 'mydb' on each standalone node..."
for NODE_ID in ${ALL_NODES}; do
  if [ "$NODE_ID" == "0" ]; then
    HOST=$NODE_01_HOST
  else
    HOST=$NODE_02_HOST
  fi

  curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/mydb"
done

echo "Ensuring _replicator databases exist on all nodes..."
for NODE_ID in ${ALL_NODES}; do
  if [ "$NODE_ID" == "0" ]; then
    HOST=$NODE_01_HOST
  else
    HOST=$NODE_02_HOST
  fi

  curl -s -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/_replicator" > /dev/null
done

echo "Waiting for databases to be ready..."
for NODE_ID in ${ALL_NODES}; do
  if [ "$NODE_ID" == "0" ]; then
    HOST=$NODE_01_HOST
  else
    HOST=$NODE_02_HOST
  fi

  echo -n "Waiting on node ${NODE_ID}..."
  until curl -s -o /dev/null -w "%{http_code}" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/mydb" | grep -q "200"; do
    sleep 1
    echo -n "."
  done
  echo " ready"
done

echo "Setting up continuous async replication..."

curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_01_HOST}:${PORT_BASE}0/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-to-node1",
    "source": "http://admin:admin@couchdb_node_01:5984/mydb",
    "target": "http://admin:admin@couchdb_node_02:5984/mydb",
    "continuous": true
  }'

curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_02_HOST}:${PORT_BASE}1/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-to-node0",
    "source": "http://admin:admin@couchdb_node_02:5984/mydb",
    "target": "http://admin:admin@couchdb_node_01:5984/mydb",
    "continuous": true
  }'

echo "Async replication setup complete!"
