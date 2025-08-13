#!/usr/bin/env bash

if [ -z "${2-}" ]; then
  echo "Usage: $0 <hostname> <public_ip_ap>"
  exit 1
fi

hostname="$1"
public_ip_ap="$2"

if [ "$hostname" = "node_us" ]; then
  echo "[INFO] running writes on $hostname..."
  for i in {1000..1999}; do
    movie_id="movie_id_${i}_${hostname}"
    movie_title="title_${i}"
    cast_info_id="$i"
    cast_name="thename"
    cast_gender=1
    cast_intro="theintro"
    plot_id="$i"
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
  done

elif [ "$hostname" = "node_ap" ]; then
  echo "[INFO] running reads on $hostname..."
  COUCHDB_BASE="http://admin:admin@${public_ip_ap}:10011/movieid"
  echo "[INFO] CouchDB base: ${COUCHDB_BASE}"

  for i in {1000..1999}; do
    movie_id="movie_id_${i}_node_us"
    movie_title="title_${i}"

    echo -n "[INFO] waiting for ${movie_id} in CouchDB ... "
    start_time=$(date +%s)

    while :; do
      code="$(curl -s -o /dev/null -w "%{http_code}" "${COUCHDB_BASE}/${movie_title}")"
      if [ "$code" = "200" ]; then
          echo "found."
          break
      fi

      now=$(date +%s)
      elapsed=$(( now - start_time ))
      if [ $elapsed -ge 60 ]; then
          echo "NOT found after ${elapsed}s; exiting."
          exit 1
      fi
    done

    review_start=0
    review_stop=5
    curl -sS "http://localhost:8080/wrk2-api/page/read?movie_id=${movie_id}&review_start=${review_start}&review_stop=${review_stop}"
  done

else
  echo "[ERROR] unknown hostname: $hostname"
  exit 1
fi
