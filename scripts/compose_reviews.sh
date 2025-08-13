#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

hostname="$1"

for i in {0..999}; do
  username="username_"$i
  password="password_"$i
  title="title_"$i
  random_part=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
  text="review_at_${hostname}_${random_part}"

  curl -sS localhost:8080/wrk2-api/review/compose \
    -d "text=${text}&username=${username}&password=${password}&rating=5&title=${title}"

done
