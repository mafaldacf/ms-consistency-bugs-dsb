#!/usr/bin/env bash

for i in {1..100}; do
  first_name=first_name_$i
  last_name=last_name_$i
  username=username_$i
  password=password_$i
  
  curl -sS localhost:8080/wrk2-api/user/register \
        -d "first_name="$first_name"&last_name="$last_name"&username="$username"&password="$password
done
