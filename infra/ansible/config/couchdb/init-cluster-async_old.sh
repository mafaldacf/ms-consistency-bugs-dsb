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

echo "Creating databases on each standalone node..."
for NODE_ID in ${ALL_NODES}; do
  if [ "$NODE_ID" == "0" ]; then
    HOST=$NODE_01_HOST
  else
    HOST=$NODE_02_HOST
  fi

  curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/mydb"
  curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/movieinfo"
  curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/moviereview"
  curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/reviewstorage"
  curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/plot"
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

  echo -n "Waiting on node ${NODE_ID}..."
  until curl -s -o /dev/null -w "%{http_code}" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/movieinfo" | grep -q "200"; do
    sleep 1
    echo -n "."
  done

  echo -n "Waiting on node ${NODE_ID}..."
  until curl -s -o /dev/null -w "%{http_code}" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/moviereview" | grep -q "200"; do
    sleep 1
    echo -n "."
  done

  echo -n "Waiting on node ${NODE_ID}..."
  until curl -s -o /dev/null -w "%{http_code}" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/reviewstorage" | grep -q "200"; do
    sleep 1
    echo -n "."
  done

  echo -n "Waiting on node ${NODE_ID}..."
  until curl -s -o /dev/null -w "%{http_code}" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT_BASE}${NODE_ID}/plot" | grep -q "200"; do
    sleep 1
    echo -n "."
  done

  echo " ready"
done

echo "Setting up continuous async replication..."

echo "[INFO] replicate-to-node1"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_01_HOST}:${PORT_BASE}0/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-to-node1",
    "source": "http://admin:admin@54.211.161.89:10010/mydb",
    "target": "http://admin:admin@13.250.8.85:10011/mydb",
    "continuous": true
  }'

echo "[INFO] replicate-to-node0"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_02_HOST}:${PORT_BASE}1/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-to-node0",
    "source": "http://admin:admin@13.250.8.85:10011/mydb",
    "target": "http://admin:admin@54.211.161.89:10010/mydb",
    "continuous": true
  }'

echo "[INFO] replicate-movieinfo-to-node1"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_01_HOST}:${PORT_BASE}0/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-movieinfo-to-node1",
    "source": "http://admin:admin@54.211.161.89:10010/movieinfo",
    "target": "http://admin:admin@13.250.8.85:10011/movieinfo",
    "continuous": true
  }'

echo "[INFO] replicate-movieinfo-to-node0"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_02_HOST}:${PORT_BASE}1/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-movieinfo-to-node0",
    "source": "http://admin:admin@13.250.8.85:10011/movieinfo",
    "target": "http://admin:admin@54.211.161.89:10010/movieinfo",
    "continuous": true
  }'

echo "[INFO] replicate-moviereview-to-node1"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_01_HOST}:${PORT_BASE}0/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-moviereview-to-node1",
    "source": "http://admin:admin@54.211.161.89:10010/moviereview",
    "target": "http://admin:admin@13.250.8.85:10011/moviereview",
    "continuous": true
  }'

echo "[INFO] replicate-moviereview-to-node0"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_02_HOST}:${PORT_BASE}1/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-moviereview-to-node0",
    "source": "http://admin:admin@13.250.8.85:10011/moviereview",
    "target": "http://admin:admin@54.211.161.89:10010/moviereview",
    "continuous": true
  }'

echo "[INFO] replicate-reviewstorage-to-node1"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_01_HOST}:${PORT_BASE}0/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-reviewstorage-to-node1",
    "source": "http://admin:admin@54.211.161.89:10010/reviewstorage",
    "target": "http://admin:admin@13.250.8.85:10011/reviewstorage",
    "continuous": true
  }'

echo "[INFO] replicate-reviewstorage-to-node0"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_02_HOST}:${PORT_BASE}1/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-reviewstorage-to-node0",
    "source": "http://admin:admin@13.250.8.85:10011/reviewstorage",
    "target": "http://admin:admin@54.211.161.89:10010/reviewstorage",
    "continuous": true
  }'

echo "[INFO] replicate-plot-to-node1"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_01_HOST}:${PORT_BASE}0/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-plot-to-node1",
    "source": "http://admin:admin@54.211.161.89:10010/plot",
    "target": "http://admin:admin@13.250.8.85:10011/plot",
    "continuous": true
  }'

echo "[INFO] replicate-plot-to-node0"
curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_02_HOST}:${PORT_BASE}1/_replicator" \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "replicate-plot-to-node0",
    "source": "http://admin:admin@13.250.8.85:10011/plot",
    "target": "http://admin:admin@54.211.161.89:10010/plot",
    "continuous": true
  }'

echo "Async replication setup complete!"
