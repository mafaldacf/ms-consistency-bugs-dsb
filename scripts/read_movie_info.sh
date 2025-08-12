#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

for i in {1..10}; do
  movie_id="movie_id_${i}_${host}"
  curl -sS "http://localhost:8080/wrk2-api/movie-info/read?movie_id=${movie_id}"
done
