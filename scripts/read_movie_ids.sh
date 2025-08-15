#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

for i in {5000..5999}; do
  movie_title=title_${i}
  curl -sS "http://localhost:8080/wrk2-api/movie/read?title=${movie_title}"
done
