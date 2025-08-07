#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

for i in {1..50}; do
    curl localhost:8080/wrk2-api/movie/register \
        -d "title=title_${i}&movie_id=movie_id_${i}_${hostname}"
done
