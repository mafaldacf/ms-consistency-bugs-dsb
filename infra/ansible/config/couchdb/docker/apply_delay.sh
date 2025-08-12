#!/bin/bash

echo "Applying delay to aspw-dev-couchdb_node_01-1..."
docker exec -it aspw-dev-couchdb_node_01-1 bash -c '/usr/local/bin/delay.sh "couchdb_node_02" 500ms 1000ms 10% normal'

echo "Applying delay to aspw-dev-couchdb_node_02-1..."
docker exec -it aspw-dev-couchdb_node_02-1 bash -c '/usr/local/bin/delay.sh "couchdb_node_01" 500ms 1000ms 10% normal'
