#!/bin/bash
# Usage: lab-entry <pki|auth|resolver|ca|web|student>
set -e
role="$1"

# Point the container at the lab resolver instead of Docker's embedded DNS (127.0.0.11).
if [ -n "$RESOLVER" ]; then
  printf 'nameserver %s\n' "$RESOLVER" > /etc/resolv.conf
fi

# Artificial latency on everything this container sends. Needs cap_add: NET_ADMIN and sch_netem.
if [ -n "$NETEM_DELAY" ]; then
  tc qdisc replace dev eth0 root netem delay "$NETEM_DELAY" \
    || echo "WARNING: netem not applied (missing NET_ADMIN or sch_netem module)" >&2
fi

case "$role" in
  pki)
    exec pki-init /pki /lab/sites.tsv
    ;;
  auth)
    exec named -f -u bind -c /lab/named.conf
    ;;
  resolver)
    exec unbound -d -c /lab/unbound.conf
    ;;
  ca)
    # Pebble: ACME test CA. Its root and intermediate are generated in memory at every start.
    export PEBBLE_VA_NOSLEEP=1 PEBBLE_WFE_NONCEREJECT=0
    exec pebble -config /lab/pebble.json -dnsserver "${RESOLVER}:53"
    ;;
  web)
    exec nginx -c /lab/nginx.conf -g 'daemon off;'
    ;;
  student)
    named -u bind -c /lab/named.conf || echo "WARNING: named failed to start, see /var/log/named/named.log" >&2
    # Until the student installs a certificate, HTTPS uses a placeholder so that nginx can start.
    if [ ! -s /lab/tls/server.crt ] || [ ! -s /lab/tls/server.key ]; then
      openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 \
        -keyout /lab/tls/server.key -out /lab/tls/server.crt \
        -subj "/CN=placeholder" -addext "subjectAltName=DNS:placeholder.invalid" 2>/dev/null
    fi
    nginx -c /lab/nginx.conf || echo "WARNING: nginx failed to start, run: nginx -c /lab/nginx.conf -t" >&2
    cd /lab/work
    exec ttyd -W -p 7681 -c "$TTYD_CRED" -t titleFixed="$STUDENT_ID" bash -l
    ;;
  *)
    echo "unknown role: $role" >&2; exit 1
    ;;
esac
