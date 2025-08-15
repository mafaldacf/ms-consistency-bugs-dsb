#!/usr/bin/env bash

curl -sS "http://localhost:8080/wrk2-api/user/register" \
    -d "first_name=first_name_500&last_name=last_name_500&username=username_500&password=password_500"

curl -sS localhost:8080/wrk2-api/movie/register \
    -d "title=title_test_500&movie_id=movie_id_test_500"

curl -sS "localhost:8080/wrk2-api/movie/read?title=title_test_500"

curl -sS -X POST "http://localhost:8080/wrk2-api/movie-info/write" \
  -H "Content-Type: application/json" \
  -d '{"movie_id": "movie_id_test_500", "title": "title_test_500", "plot_id": 500}'

curl -sS -X POST "http://localhost:8080/wrk2-api/cast-info/write" \
  -H "Content-Type: application/json" \
  -d '{"cast_info_id":500,"name":"thename","gender":1,"intro":"theintro"}'

curl -sS -X POST "http://localhost:8080/wrk2-api/plot/write" \
  -H "Content-Type: application/json" \
  -d '{"plot_id": 500, "plot": "theplot"}'

curl -sS "localhost:8080/wrk2-api/movie-info/read?movie_id=movie_id_test_500"

curl -sS "localhost:8080/wrk2-api/page/read?movie_id=movie_id_test_500&review_start=0&review_stop=1"

curl -sS localhost:8080/wrk2-api/review/compose \
    -d "text=${$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 25 | head -n 1)}&username=username_500&password=password_500&rating=5&title=title_test_500"

curl -sS localhost:8080/wrk2-api/review/compose \
    -d "text=thetext&username=username_500&password=password_500&rating=5&title=title_test_500"

curl -sS "localhost:8080/wrk2-api/page/read?movie_id=movie_id_test_500&review_start=0&review_stop=1"

curl -sS "localhost:8080/wrk2-api/page/read?movie_id=movie_id_500_node_ap&review_start=0&review_stop=1"
