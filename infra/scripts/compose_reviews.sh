#!/usr/bin/env bash

# curl -sS localhost:8080/wrk2-api/review/compose -d "text="mytext"&username="username_1"&password="password_1"&rating=5&title="title_1

for i in {1..10}; do
  username="username_"$i
  password="password_"$i
  title="title_"$i
  text=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 256 | head -n 1)
  curl -sS localhost:8080/wrk2-api/review/compose \
        -d "text="$text"&username="$username"&password="$password"&rating=5&title="$title
done
 
