#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

for i in {1..10}; do
    movie_id=movie_id_${i}_${hostname}
    movie_title=title_${i}
    
    curl -sS localhost:8080/wrk2-api/movie/register \
        -d "title=${movie_title}&movie_id=${movie_id}"
done
