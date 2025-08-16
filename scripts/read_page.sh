#!/usr/bin/env bash

range_start=0
range_end=999

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

for i in $(seq $range_start $range_end); do
  review_start=0
  review_stop=5
  
  movie_id="movie_id_${i}_node_us"
  curl -sS "http://localhost:8080/wrk2-api/page/read?movie_id=${movie_id}&review_start=${review_start}=&review_stop=${review_stop}"

  movie_id="movie_id_${i}_node_ap"
  curl -sS "http://localhost:8080/wrk2-api/page/read?movie_id=${movie_id}&review_start=${review_start}=&review_stop=${review_stop}"
  
  echo "--------------------------"
done
