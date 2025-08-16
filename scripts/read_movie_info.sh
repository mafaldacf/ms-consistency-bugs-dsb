#!/usr/bin/env bash

range_start=0
range_end=999

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

for i in {0..999}; do
  movie_id="movie_id_${i}_${hostname}"
  curl -sS "http://localhost:8080/wrk2-api/movie-info/read?movie_id=${movie_id}"
done
