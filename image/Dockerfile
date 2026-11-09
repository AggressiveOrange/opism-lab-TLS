# One image for every role on the TLS stand: pki, root, TLD, resolver, ca, web, student.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bind9 bind9-utils bind9-dnsutils unbound nginx ttyd \
      openssl pebble lego \
      curl tcpdump iproute2 nano vim-tiny less ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && rndc-confgen -a -k rndc-key -c /etc/bind/rndc.key \
 && chown bind:bind /etc/bind/rndc.key \
 && mkdir -p /var/log/named /run/named /var/www/acme \
 && chown bind:bind /var/log/named /run/named
COPY entrypoint.sh /usr/local/bin/lab-entry
COPY pki-init.sh /usr/local/bin/pki-init
COPY lab-profile.sh /etc/profile.d/lab.sh
RUN chmod +x /usr/local/bin/lab-entry /usr/local/bin/pki-init
ENTRYPOINT ["/usr/local/bin/lab-entry"]
