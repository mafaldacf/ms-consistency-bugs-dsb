#!/usr/bin/env bash

range_start=0
range_end=999

for i in $(seq $range_start $range_end); do
  first_name=first_name_$i
  last_name=last_name_$i
  username=username_$i
  password=password_$i
  
  curl -sS localhost:8080/wrk2-api/user/register \
        -d "first_name="$first_name"&last_name="$last_name"&username="$username"&password="$password
done
