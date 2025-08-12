#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

# curl -sS localhost:8080/wrk2-api/page/read -d "movie_id="movie_id_1_node_us"&review_start="0"&review_stop="1
for i in {1..10}; do
  movie_id="movie_id_${i}_${hostname}"
  review_start=0
  review_stop=5
  
  curl -sS localhost:8080/wrk2-api/page/read \
        -d "movie_id="$movie_id"&review_start="$review_start"&review_stop="$review_stop
done
 
