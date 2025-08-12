#!/usr/bin/env bash

for i in {1..10}; do
  username="username_"$i
  password="password_"$i
  title="title_"$i
  text=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 25 | head -n 1)

  curl -sS -X POST localhost:8080/wrk2-api/review/compose \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "text=${text}&username=${username}&password=${password}&rating=5&title=${title}"

done
 
