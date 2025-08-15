#!/usr/bin/env bash
source .env
source hosts

set -euo pipefail

SCYLLA_KEYSPACE=mediamicroservices

compute_node_host() {
  case "$1" in
    0|1|2) echo "$NODE_01_HOST" ;;
    3|4|5) echo "$NODE_02_HOST" ;;
    *) echo "invalid node id: $1" >&2; exit 1 ;;
  esac
}

compute_node_port() {
  case "$1" in
    0) echo "10030" ;;
    1) echo "10031" ;;
    2) echo "10032" ;;
    3) echo "10033" ;;
    4) echo "10034" ;;
    5) echo "10035" ;;
    *) echo "invalid node id: $1" >&2; exit 1 ;;
  esac
}

compute_node_host() {
  case "$1" in
    0|1|2) echo "$NODE_01_HOST" ;;
    3|4|5) echo "$NODE_02_HOST" ;;
    *)   echo "invalid node id: $1" >&2; exit 1 ;;
  esac
}

compute_node_port() { echo "${PORT_BASE}$1"; }

MASTER_HOST="${NODE_01_HOST}"
MASTER_PORT="${PORT_BASE}0"

echo "[info] creating keyspace and tables on $MASTER_HOST:$MASTER_PORT"

cql=$(cat <<'CQL'
CREATE KEYSPACE IF NOT EXISTS mediamicroservices
  WITH replication = {'class': 'NetworkTopologyStrategy', 'DC1':3, 'DC2':3};`

USE mediamicroservices;

CREATE TABLE IF NOT EXISTS movieid_by_title (
  title text PRIMARY KEY,
  movie_id text
);

-- application-enforced uniqueness for movie_id:
CREATE TABLE IF NOT EXISTS movieid_by_movie_id (
  movie_id text PRIMARY KEY,
  title text
);

CREATE TABLE IF NOT EXISTS movieinfo (
  movie_id text PRIMARY KEY,
  title text,
  plot_id int
);

CREATE TABLE IF NOT EXISTS moviereview (
  movie_id text PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS reviewstorage (
  movie_id text PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS plot (
  plot_id text PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS castinfo (
  cast_info_id text PRIMARY KEY
);
CQL
)

echo "$cql" | cqlsh_cmd "$MASTER_HOST" "$MASTER_PORT"


echo ""
echo "waiting 20 seconds for tables to replicate..."
sleep 20
echo ""

for NODE_ID in 0 1 2 3 4 5; do
  HOST="$(compute_node_host "$NODE_ID")"
  PORT="$(compute_node_port "$NODE_ID")"
  echo "[info] verifying tables in keyspace $SCYLLA_KEYSPACE on $HOST:$PORT"
  cqlsh_cmd "$HOST" "$PORT" -e "DESCRIBE TABLES IN $SCYLLA_KEYSPACE;"
done

echo "done!"
