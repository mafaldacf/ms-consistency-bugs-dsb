#!/usr/bin/env bash

range_start=5000
range_end=5999

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

for i in $(seq $range_start $range_end); do
    movie_id=movie_id_${i}_${hostname}
    movie_title=title_${i}

    curl -sS localhost:8080/wrk2-api/movie/register \
        -d "title=${movie_title}&movie_id=${movie_id}"
done
