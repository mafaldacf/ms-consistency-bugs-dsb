#!/usr/bin/env bash
set -euo pipefail

source .env
source hosts

COUCHDB_DATABASES=(movieid movieinfo moviereview reviewstorage plot castinfo)

compute_node_host() {
  case "$1" in
    0) echo "$NODE_01_HOST" ;;
    1) echo "$NODE_02_HOST" ;;
    *) echo "invalid node id: $1" >&2; exit 1 ;;
  esac
}

compute_node_port() {
  case "$1" in
    0) echo "10010" ;;
    1) echo "10011" ;;
    *) echo "invalid node id: $1" >&2; exit 1 ;;
  esac
}

echo "initializing each node as single-node..."
for NODE_ID in 0 1; do
  HOST="$(compute_node_host "$NODE_ID")"
  PORT="$(compute_node_port "$NODE_ID")"
  echo "configuring node $NODE_ID at $HOST:$PORT"

  curl -sS -X POST \
    -H "content-type: application/json" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT}/_cluster_setup" \
    -d '{"action":"enable_single_node","bind_address":"0.0.0.0","username":"'"${COUCHDB_USER}"'","password":"'"${COUCHDB_PASSWORD}"'"}' >/dev/null || true

  curl -sS -X POST \
    -H "content-type: application/json" \
    "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT}/_cluster_setup" \
    -d '{"action":"finish_cluster"}' >/dev/null || true

  for sysdb in _users _replicator _global_changes; do
    curl -sS -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT}/${sysdb}" >/dev/null || true
  done

  echo -n "waiting on _up for node $NODE_ID "
  until curl -s "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT}/_up" | grep -q '"status":"ok"'; do
    sleep 1; echo -n "."
  done
  echo " ok"
done

echo "creating databases on each node (idempotent)..."
for NODE_ID in 0 1; do
  HOST="$(compute_node_host "$NODE_ID")"
  PORT="$(compute_node_port "$NODE_ID")"
  for DB in "${COUCHDB_DATABASES[@]}"; do
    curl -sS -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT}/${DB}" >/dev/null || true
  done
done

echo "waiting for all COUCHDB_DATABASES to be ready..."
for NODE_ID in 0 1; do
  HOST="$(compute_node_host "$NODE_ID")"
  PORT="$(compute_node_port "$NODE_ID")"
  for DB in "${COUCHDB_DATABASES[@]}"; do
    echo -n "  node ${NODE_ID} db=${DB} "
    until [ "$(curl -s -o /dev/null -w '%{http_code}' "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT}/${DB}")" = "200" ]; do
      sleep 1; echo -n "."
    done
    echo " ready"
  done
done

post_rep() {
  local node_host="$1" node_port="$2" rep_id="$3" src="$4" dst="$5"
  curl -sS -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${node_host}:${node_port}/_replicator" \
    -H "content-type: application/json" \
    -d '{"_id":"'"${rep_id}"'","source":"'"${src}"'","target":"'"${dst}"'","continuous":true}' \
    | grep -E '"ok":true|"conflict"' || true
}

# use external ips and not docker swarm internal hosts
# because when using AWS with one VPC per region
# workers advertize their public ips in docker swarm
SRC0="http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_01_HOST}:$(compute_node_port 0)"
SRC1="http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_02_HOST}:$(compute_node_port 1)"

echo "setting up continuous replications both ways for each db..."
for DB in "${COUCHDB_DATABASES[@]}"; do
  echo "  ${DB}: node0 -> node1"
  post_rep "$(compute_node_host 0)" "$(compute_node_port 0)" "replicate-${DB}-to-node1" "${SRC0}/${DB}" "${SRC1}/${DB}"
  echo "  ${DB}: node1 -> node0"
  post_rep "$(compute_node_host 1)" "$(compute_node_port 1)" "replicate-${DB}-to-node0" "${SRC1}/${DB}" "${SRC0}/${DB}"
done

echo "verifying scheduler state (node0 and node1)..."
for NODE_ID in 0 1; do
  HOST="$(compute_node_host "$NODE_ID")"; PORT="$(compute_node_port "$NODE_ID")"
  echo "  node ${NODE_ID} (_scheduler/docs):"
  curl -sS "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${HOST}:${PORT}/_scheduler/docs" || true
  echo
done

echo "done."
