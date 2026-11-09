#!/bin/bash
# Stand PKI: created once, never overwritten (delete the pki/ folder to start over).
# Usage: pki-init <out dir> <sites.tsv>
#   sites.tsv: one line per HTTPS name served by "web":  <name> <kind> [<extra>]
#   kind: ok | expired | wrongname <SAN actually used> | selfsigned | nochain | unknownca
set -euo pipefail
OUT="$1"; SITES="$2"
mkdir -p "$OUT/web" "$OUT/public" "$OUT/.work"
cd "$OUT"
W=.work

key() { openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$1" 2>/dev/null; }

leaf_ext() {  # $1 = SAN value
  printf 'basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth\nsubjectAltName=%s\n' "$1"
}
ca_ext() {
  printf 'basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign\n'
}

root_ca() {  # $1 = file prefix, $2 = CN, $3 = O
  [ -s "$1.crt" ] && return
  key "$1.key"
  openssl req -x509 -new -key "$1.key" -sha256 -days 3650 -subj "/O=$3/CN=$2" -out "$1.crt"
}
int_ca() {  # $1 = prefix, $2 = CN, $3 = issuer prefix, $4 = O
  [ -s "$1.crt" ] && return
  key "$1.key"
  openssl req -new -key "$1.key" -subj "/O=$4/CN=$2" -out "$W/$1.csr"
  openssl x509 -req -in "$W/$1.csr" -CA "$3.crt" -CAkey "$3.key" -CAcreateserial -sha256 -days 1825 \
    -extfile <(ca_ext) -out "$1.crt" 2>/dev/null
}
leaf() {  # $1 = out cert, $2 = key, $3 = CN, $4 = SAN, $5 = issuer prefix, [$6 $7 = start end YYYYmmddHHMMSSZ]
  openssl req -new -key "$2" -subj "/CN=$3" -out "$W/leaf.csr"
  if [ -n "${6:-}" ]; then
    # openssl x509 cannot set arbitrary dates; openssl ca can.
    local db="$W/ca-$5"; mkdir -p "$db"; : > "$db/index.txt"
    printf '[ca]\ndefault_ca=x\n[x]\ndatabase=%s/index.txt\nnew_certs_dir=%s\nserial=%s/serial\npolicy=p\ndefault_md=sha256\nunique_subject=no\n[p]\ncommonName=supplied\n' \
      "$db" "$db" "$db" > "$db/cnf"
    [ -s "$db/serial" ] || openssl rand -hex 16 > "$db/serial"
    openssl ca -batch -notext -config "$db/cnf" -cert "$5.crt" -keyfile "$5.key" -in "$W/leaf.csr" \
      -startdate "$6" -enddate "$7" -extfile <(leaf_ext "$4") -out "$1" 2>/dev/null
  else
    openssl x509 -req -in "$W/leaf.csr" -CA "$5.crt" -CAkey "$5.key" -CAcreateserial -sha256 -days 90 \
      -extfile <(leaf_ext "$4") -out "$1" 2>/dev/null
  fi
}

# Trusted stand PKI and a foreign one that nobody trusts.
root_ca stand-root "OPISM Stand Root CA" "OPISM Lab"
int_ca  stand-int  "OPISM Stand Intermediate CA" stand-root "OPISM Lab"
root_ca foreign-root "Foreign Root CA" "Foreign Org"
int_ca  foreign-int  "Foreign Intermediate CA" foreign-root "Foreign Org"

# HTTPS certificate of the ACME server itself (ca.lab).
if [ ! -s ca.crt ]; then
  key ca.key
  leaf "$W/ca.leaf" ca.key ca.lab "DNS:ca.lab,IP:10.53.0.10" stand-int
  cat "$W/ca.leaf" stand-int.crt > ca.crt
fi

while read -r name kind extra; do
  [ -z "${name:-}" ] || [ "${name:0:1}" = "#" ] && continue
  crt="web/$name.crt"; k="web/$name.key"
  [ -s "$crt" ] && continue
  key "$k"
  case "$kind" in
    ok)        leaf "$W/l" "$k" "$name" "DNS:$name" stand-int; cat "$W/l" stand-int.crt > "$crt" ;;
    nochain)   leaf "$W/l" "$k" "$name" "DNS:$name" stand-int; cp "$W/l" "$crt" ;;
    wrongname) leaf "$W/l" "$k" "$extra" "DNS:$extra" stand-int; cat "$W/l" stand-int.crt > "$crt" ;;
    unknownca) leaf "$W/l" "$k" "$name" "DNS:$name" foreign-int; cat "$W/l" foreign-int.crt > "$crt" ;;
    expired)
      s=$(date -u -d '-200 days' +%Y%m%d%H%M%SZ); e=$(date -u -d '-20 days' +%Y%m%d%H%M%SZ)
      leaf "$W/l" "$k" "$name" "DNS:$name" stand-int "$s" "$e"; cat "$W/l" stand-int.crt > "$crt" ;;
    selfsigned)
      openssl req -x509 -new -key "$k" -sha256 -days 90 -subj "/CN=$name" \
        -addext "subjectAltName=DNS:$name" -addext "basicConstraints=critical,CA:FALSE" -out "$crt" ;;
    *) echo "unknown kind $kind for $name" >&2; exit 1 ;;
  esac
done < "$SITES"

cp stand-root.crt public/stand-root.crt

# Keys are readable by nginx worker processes only through the master (root); certs are public.
chmod 644 ./*.crt web/*.crt public/*.crt
chmod 600 ./*.key web/*.key
echo "pki ready: $(ls web/*.crt | wc -l) site certificates"
