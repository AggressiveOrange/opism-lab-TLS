# Shell helpers for the TLS lab (students' ttyd sessions).
if [ -n "$STUDENT_ID" ]; then
  export ZONE="$STUDENT_ID.lab"
  export STAND_CA=/lab/pki/stand-root.crt
  export ACME_DIR=https://ca.lab:14000/dir
  # lego must trust the HTTPS certificate of the ACME server itself.
  export LEGO_CA_CERTIFICATES="$STAND_CA"
  alias web-reload='nginx -c /lab/nginx.conf -t && nginx -c /lab/nginx.conf -s reload'
  alias web-log='tail -f /var/log/nginx/access.log'
  alias acme-root='curl -s --cacert "$STAND_CA" https://ca.lab:15000/roots/0 > /lab/tls/acme-root.crt && echo "збережено /lab/tls/acme-root.crt"'
  [[ $- == *i* ]] && cat <<EOF

  Стенд TLS. Ідентифікатор: $STUDENT_ID   Зона: $ZONE   Ваш сервер: $STUDENT_IP
  Резолвер: 10.53.0.53   ACME-сервер: ca.lab (10.53.0.10)   Віддалений сервер: 10.53.0.80

  \$STAND_CA     корінь стенда: /lab/pki/stand-root.crt
  \$ACME_DIR     каталог ACME:  https://ca.lab:14000/dir
  acme-root     зберегти поточний корінь ACME-сервера у /lab/tls/acme-root.crt
  web-reload    перевірити конфігурацію nginx і перезавантажити його
  web-log       журнал запитів до вашого nginx (Ctrl+C для виходу)

  Сертифікат вашого сервера: /lab/tls/server.crt   ключ: /lab/tls/server.key
  Робочий каталог (зберігається між перезапусками): /lab/work

EOF
fi
