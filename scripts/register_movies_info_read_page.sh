#!/usr/bin/env bash

range_start=11000
range_end=11999

if [ -z "${2-}" ]; then
  echo "Usage: $0 <hostname> <public_ip_ap>"
  exit 1
fi

hostname="$1"
public_ip_ap="$2"

write_movie() {
  movie_id=$1
  movie_title=$2
  cast_info_id=$3
  plot_id=$3
  cast_name="thename"
  cast_gender=1
  cast_intro="theintro"
  plot="$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 25 | head -n 1)"

  curl -sS localhost:8080/wrk2-api/movie/register \
    -d "title=${movie_title}&movie_id=${movie_id}"

  curl -sS -X POST localhost:8080/wrk2-api/movie-info/write \
    -H "Content-Type: application/json" \
    -d "{\"movie_id\":\"${movie_id}\",\"title\":\"${movie_title}\",\"plot_id\":\"${plot_id}\"}"

  curl -sS -X POST localhost:8080/wrk2-api/cast-info/write \
    -H "Content-Type: application/json" \
    -d "{\"cast_info_id\":\"${cast_info_id}\",\"name\":\"${cast_name}\",\"gender\":\"${cast_gender}\",\"intro\":\"${cast_intro}\"}"

  curl -sS -X POST localhost:8080/wrk2-api/plot/write \
    -H "Content-Type: application/json" \
    -d "{\"plot_id\":\"${plot_id}\",\"plot\":\"${plot}\"}"
}

find_movie_id() {
  title=$1
  start_time=$(date +%s)
  tries=0
  echo -n "[MOVIE_ID] waiting for ${title} ... "
  while :; do
    tries=$((tries + 1))
    if curl -s "localhost:8080/wrk2-api/movie/read?title=${title}" | grep -q "successfully"; then
      echo "found."
      break
    fi

    now=$(date +%s)
    elapsed=$(( now - start_time ))
    if [ $elapsed -ge 30 ]; then
        echo "NOT found after ${elapsed}s; exiting."
        exit 1
    fi
  done
}

find_movie_info() {
  movie_id=$1
  start_time=$(date +%s)
  tries=0
  echo -n "[MOVIE_INFO] waiting for ${movie_id} ... "

  while :; do
    tries=$((tries + 1))
    output=$(curl -s "localhost:8080/wrk2-api/movie-info/read?movie_id=${movie_id}")

    if echo "$output" | grep -q "successfully"; then
      elapsed=$(( $(date +%s) - start_time ))
      echo "found after ${tries} tries."
      break
    fi

    elapsed=$(( $(date +%s) - start_time ))
    if [ $elapsed -ge 30 ]; then
      echo "NOT found after ${elapsed}s; exiting."
      exit 1
    fi
  done
}

find_page() {
  movie_id=$1
  review_start=0
  review_stop=5
  start_time=$(date +%s)
  tries=0

  echo -n "[PAGE] "
  curl -sS "http://localhost:8080/wrk2-api/page/read?movie_id=${movie_id}&review_start=${review_start}&review_stop=${review_stop}"
}

if [ "$hostname" = "node_us" ]; then
  echo "[INFO] running writes on $hostname..."
  for i in $(seq $range_start $range_end); do
    movie_id="movie_id_${i}_${hostname}"
    movie_title="title_${i}"
    write_movie $movie_id $movie_title $i
  done

elif [ "$hostname" = "node_ap" ]; then
  echo "[INFO] running reads on $hostname..."

  for i in $(seq $range_start $range_end); do
    movie_id="movie_id_${i}_node_us"
    title="title_${i}"
    find_movie_id $title
    find_movie_info $movie_id
    find_page $movie_id
    echo "----------------------------------------------------"
  done

else
  echo "[ERROR] unknown hostname: $hostname"
  exit 1
fi
