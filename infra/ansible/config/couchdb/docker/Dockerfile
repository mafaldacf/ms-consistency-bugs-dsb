FROM couchdb:3

RUN apt-get update && apt-get install -y iproute2 dnsutils && rm -rf /var/lib/apt/lists/*

COPY delay.sh /usr/local/bin/delay.sh
RUN chmod +x /usr/local/bin/delay.sh
