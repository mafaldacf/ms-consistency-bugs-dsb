#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

for i in {0..999}; do
    movie_id=movie_id_${i}_${hostname}
    movie_title=title_${i}

    curl -sS localhost:8080/wrk2-api/movie/register \
        -d "title=${movie_title}&movie_id=${movie_id}"
done

for i in {0..999}; do
    movie_id=movie_id_${i}_${hostname}
    movie_title=title_${i}
    plot_id=${i}

    curl -sS -X POST localhost:8080/wrk2-api/movie-info/write \
        -H "Content-Type: application/json" \
        -d "{\"movie_id\": \"${movie_id}\", \"title\": \"${movie_title}\", \"plot_id\": \"${plot_id}\"}"
done

for i in {0..999}; do
    cast_info_id=${i}
    cast_name=thename
    cast_gender=1
    cast_intro=theintro
    plot_id=${i}
    plot=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 25 | head -n 1)

    curl -sS -X POST localhost:8080/wrk2-api/cast-info/write \
        -H "Content-Type: application/json" \
        -d "{\"cast_info_id\": \"${cast_info_id}\", \"name\": \"${cast_name}\", \"gender\": \"${cast_gender}\", \"intro\": \"${cast_intro}\"}"

    curl -sS -X POST localhost:8080/wrk2-api/plot/write \
        -H "Content-Type: application/json" \
        -d "{\"plot_id\": \"${plot_id}\", \"plot\": \"${plot}\"}"
done
