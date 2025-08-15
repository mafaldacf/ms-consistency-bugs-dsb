#!/usr/bin/env bash
source .env
source hosts

set -euo pipefail

POSTGRESQL_TABLES=(movieid movieinfo moviereview reviewstorage plot castinfo)

compute_node_host() {
  case "$1" in
    0|1) echo "$NODE_01_HOST" ;;
    2) echo "$NODE_02_HOST" ;;
    *) echo "invalid node id: $1" >&2; exit 1 ;;
  esac
}

compute_node_port() {
  case "$1" in
    0) echo "10020" ;;
    1) echo "10021" ;;
    2) echo "10022" ;;
    *) echo "invalid node id: $1" >&2; exit 1 ;;
  esac
}

psql_cmd() {
  PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$1" -p "$2" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
    -v ON_ERROR_STOP=1 -tA
}

#wait_for_bdr_ready() {
#  local host="$1" port="$2" tries=1
#  echo "waiting for bdr to be active on ${host}:${port}..."
#  for ((i=1; i<=tries; i++)); do
#    # check that bdr is active in this db and we can see at least one node (self)
#    if out="$(psql_cmd "$host" "$port" -c "SELECT bdr.bdr_is_active_in_db(); SELECT count(*) FROM bdr.bdr_nodes;" 2>/dev/null)"; then
#      # out will be two lines: 't|f' and a number
#      local active peers
#      active="$(echo "$out" | sed -n '1p')"
#      peers="$(echo "$out" | sed -n '2p')"
#      if [[ "$active" == "t" && "${peers:-0}" -ge 1 ]]; then
#        echo "bdr active with ${peers} node(s)."
#        return 0
#      fi
#    fi
#    sleep 5
#  done
#  echo "bdr did not become ready in time." >&2
#  return 1
#}


# wait for bdr to be ready on the primary before issuing ddl
#wait_for_bdr_ready "$MASTER_HOST" "$MASTER_PORT"

for NODE_ID in 0; do
  HOST="$(compute_node_host "$NODE_ID")"
  PORT="$(compute_node_port "$NODE_ID")"
  echo "[INFO] creating movieid table (node $NODE_ID at $HOST:$PORT)"
  PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$HOST" -p "$PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
    -c "CREATE TABLE IF NOT EXISTS movieid (
          title VARCHAR(125) PRIMARY KEY,
          movie_id VARCHAR(125) UNIQUE
        );"

  echo "[INFO] creating movieinfo table (node $NODE_ID at $HOST:$PORT)"
  PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$HOST" -p "$PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
    -c "CREATE TABLE IF NOT EXISTS movieinfo (
          movie_id VARCHAR(125) PRIMARY KEY,
          title VARCHAR(125),
          plot_id INT
        );"

  echo "[INFO] creating moviereview table (node $NODE_ID at $HOST:$PORT)"
  PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$HOST" -p "$PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
    -c "CREATE TABLE IF NOT EXISTS moviereview (
          movie_id VARCHAR(125) PRIMARY KEY
        );"

  echo "[INFO] creating reviewstorage table (node $NODE_ID at $HOST:$PORT)"
  PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$HOST" -p "$PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
    -c "CREATE TABLE IF NOT EXISTS reviewstorage (
          movie_id VARCHAR(125) PRIMARY KEY
        );"

  echo "[INFO] creating plot table (node $NODE_ID at $HOST:$PORT)"
  PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$HOST" -p "$PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
    -c "CREATE TABLE IF NOT EXISTS plot (
          plot_id VARCHAR(125) PRIMARY KEY
        );"

  echo "[INFO] creating castinfo table (node $NODE_ID at $HOST:$PORT)"
  PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$HOST" -p "$PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
    -c "CREATE TABLE IF NOT EXISTS castinfo (
          cast_info_id VARCHAR(125) PRIMARY KEY
        );"
done
echo "done!"

echo ""
echo "waiting 30 seconds for tables to replicate..."
sleep 30
echo ""

for NODE_ID in 0 1 2; do
  HOST="$(compute_node_host "$NODE_ID")"
  PORT="$(compute_node_port "$NODE_ID")"
  echo "[INFO] checking tables for node $NODE_ID at $HOST:$PORT"
  PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$HOST" -p "$PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
    -c "\dt public.*; SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('${POSTGRESQL_TABLES[*]}');"
done

echo "done!"
