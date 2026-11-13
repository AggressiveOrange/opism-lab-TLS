<!--
Бланк звіту до лабораторної роботи «TLS та сертифікати».
Скопіювати цей файл у власний публічний репозиторій звіту як README.md і заповнити.
Вивід команд вставляти текстом у блоки коду, а не знімками екрана.
Порожні поля не допускаються: якщо щось не вдалося, записати, що саме і чому.
-->

# Лабораторна робота 2. TLS та сертифікати

| Поле | Значення |
|---|---|
| ПІБ | Савчук Костянтин Андрійович |
| Група | ІПЗ-2.01 |
| Ідентифікатор | se-201-28 |
| Дата виконання | 13.11.26 |
| Середовище | GitHub Codespaces |
| Версія OpenSSL | OpenSSL 3.5.8 25 Aug 2026 |

## Параметри варіанта

<!-- Переписати з картки stand/cards/<id>.md. -->

| Параметр | Значення |
|---|---|
| Віддалений сервер | 10.53.0.80 |
| Імена для сертифіката | `www.se-201-28.lab`, `news.se-201-28.lab` |
| Ваш сервер (IP) | 10.53.1.1 |

<!-- Якщо стенд перезапускався під час роботи, вказати, після якого завдання. -->

## Завдання 1. HTTP і HTTPS у дампі трафіку

Вивід кроку 1.1:

```text
[1] 43
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
server: web
Host: vault.se-201-28.lab
SNI: 
protocol: HTTP/1.1 
client: 10.53.1.1
10 packets captured
10 packets received by filter
0 packets dropped by kernel
[1]+  Exit 124                timeout 8 tcpdump -ni eth0 -A -s0 -l 'host 10.53.0.80 and tcp port 80' > t1-http.txt
14:26:23.700292 IP 10.53.1.1.33162 > 10.53.0.80.80: Flags [P.], seq 1:83, ack 1, win 502, options [nop,nop,TS val 2088482448 ecr 2851576999], length 82: HTTP: GET / HTTP/1.1
|{......GET / HTTP/1.1
Host: vault.se-201-28.lab
server: web
Host: vault.se-201-28.lab
```

Вивід кроку 1.2:

```text
[1] 49
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
server: web
Host: vault.se-201-28.lab
SNI: vault.se-201-28.lab
protocol: HTTP/2.0 TLSv1.3
client: 10.53.1.1
22 packets captured
22 packets received by filter
0 packets dropped by kernel
[1]+  Exit 124                timeout 8 tcpdump -ni eth0 -A -s0 -l 'host 10.53.0.80 and tcp port 443' > t1-https.txt
0
1
```

| Що шукали в дампі | HTTP | HTTPS |
|---|---|---|
| рядок запиту `GET /` | GET / HTTP/1.1 | 0 |
| заголовок `Host` | vault.se-201-28.lab | vault.se-201-28.lab |
| тіло відповіді (`server: web`) | server: web | — |
| ім'я віддаленого сервера (кількість входжень) | vault.se-201-28.lab (2) | vault.se-201-28.lab (1) |

1. У якому повідомленні і в якому полі передається ім'я сервера, яке видно в дампі HTTPS?<br>
Ім'я сервера передається в TLS-повідомленні ClientHello в полі server_name.

2. Чому рядок `SNI:` у відповіді сервера порожній для HTTP і заповнений для HTTPS?<br>
Для HTTP не використовується TLS, тому SNI відсутній. Для HTTPS рядок SNI заповнений тому, що під час встановлення TLS-з'єднання браузер надсилає серверу ім'я потрібного домену.

3. Рядок `protocol:` показує HTTP/1.1 для запиту по HTTP і HTTP/2.0 для запиту по HTTPS, хоча обидва запити виконано однією командою `curl` без додаткових ключів. Що визначило версію HTTP у другому випадку?<br>
Під час TLS-з'єднання curl пропонує дві версії, де сервер обирає HTTP/2.0, чого не відбувається без TLS-з'єднання для протокола HTTP.

## Завдання 2. Рукостискання по записах

Вивід кроку 2.1 (TLS 1.3):

```text
Sent Record
  Content Type = Handshake (22)
    ClientHello, Length=330
Received Record
  Content Type = Handshake (22)
    ServerHello, Length=118
Received Record
  Content Type = ChangeCipherSpec (20)
Received Record
  Content Type = ApplicationData (23)
  Inner Content Type = Handshake (22)
    EncryptedExtensions, Length=15
Received Record
  Content Type = ApplicationData (23)
  Inner Content Type = Handshake (22)
    Certificate, Length=986
Received Record
  Content Type = ApplicationData (23)
  Inner Content Type = Handshake (22)
    CertificateVerify, Length=74
Received Record
  Content Type = ApplicationData (23)
  Inner Content Type = Handshake (22)
    Finished, Length=48
Sent Record
  Content Type = ChangeCipherSpec (20)
Sent Record
  Content Type = ApplicationData (23)
  Inner Content Type = Handshake (22)
    Finished, Length=48
Sent Record
  Content Type = ApplicationData (23)
  Inner Content Type = Alert (21)
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
ALPN protocol: h2
Verify return code: 0 (ok)
```

Вивід кроку 2.2 (TLS 1.2):

```text
Sent Record
  Content Type = Handshake (22)
    ClientHello, Length=225
Received Record
  Content Type = Handshake (22)
    ServerHello, Length=74
Received Record
  Content Type = Handshake (22)
    Certificate, Length=981
Received Record
  Content Type = Handshake (22)
    ServerKeyExchange, Length=110
Received Record
  Content Type = Handshake (22)
    ServerHelloDone, Length=0
Sent Record
  Content Type = Handshake (22)
    ClientKeyExchange, Length=33
Sent Record
  Content Type = ChangeCipherSpec (20)
Sent Record
  Content Type = Handshake (22)
    Finished, Length=12
Received Record
  Content Type = Handshake (22)
    NewSessionTicket, Length=214
Received Record
  Content Type = ChangeCipherSpec (20)
Received Record
  Content Type = Handshake (22)
    Finished, Length=12
Received Record
  Content Type = ApplicationData (23)
Sent Record
  Content Type = Alert (21)
New, TLSv1.2, Cipher is ECDHE-ECDSA-AES256-GCM-SHA384
ALPN protocol: h2
    Verify return code: 0 (ok)
```

<!-- Один рядок на кожен запис з виводу 2.1, у тому самому порядку. Напрям: К→С або С→К. -->

| № | Напрям | `Content Type` | `Inner Content Type` | Повідомлення | `Length` |
|---|---|---|---|---|---|
| 1 | К→С | Handshake | — | ClientHello | 330 |
| 2 | С→К | Handshake | — | ServerHello | 118 |
| 3 | С→К | ChangeCipherSpec | — | — | — |
| 4 | С→К | ApplicationData | Handshake | EncryptedExtensions | 15 |
| 5 | С→К | ApplicationData | Handshake | Certificate | 986 |
| 6 | С→К | ApplicationData | Handshake | CertificateVerify | 74 |
| 7 | С→К | ApplicationData | Handshake | Finished | 48 |
| 8 | К→С | ChangeCipherSpec | — | — | — |
| 9 | К→С | ApplicationData | Handshake | Finished | 48 |
| 10 | К→С | ApplicationData | Alert | — | — |
| 11 | К→С | Handshake | — | ClientHello | 225 |
| 12 | С→К | Handshake | — | ServerHello | 74 |
| 13 | С→К | Handshake | — | Certificate | 981 |
| 14 | С→К | Handshake | — | ServerKeyExchange | 110 |
| 15 | С→К | Handshake | — | ServerHelloDone | 0 |
| 16 | К→С | Handshake | — | ClientKeyExchange | 33 |
| 17 | К→С | ChangeCipherSpec | — | — | — |
| 18 | К→С | Handshake | — | Finished | 12 |
| 19 | С→К | Handshake | — | NewSessionTicket | 214 |
| 20 | С→К | ChangeCipherSpec | — | — | — |
| 21 | С→К | Handshake | — | Finished | 12 |
| 22 | С→К | ApplicationData | — | — | — |
| 23 | К→С | Alert | — | — | — |

Вивід кроків 2.3 і 2.4:

```text
extension_type=server_name(0), length=24
  0000 - 00 16 00 00 13 76 61 75-6c 74 2e 73 65 2d 32   .....vault.se-2
  000f - 30 31 2d 32 38 2e 6c 61-62                     01-28.lab
extension_type=ec_point_formats(11), length=4

[1] 65
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
23 packets captured
23 packets received by filter
0 packets dropped by kernel
[1]+  Exit 124                timeout 6 tcpdump -ni eth0 -A -s0 -l 'host 10.53.0.80 and tcp port 443' > t2-dump-$v.txt
TLS 1.3: 0
[1] 71
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
21 packets captured
21 packets received by filter
0 packets dropped by kernel
[1]+  Exit 124                timeout 6 tcpdump -ni eth0 -A -s0 -l 'host 10.53.0.80 and tcp port 443' > t2-dump-$v.txt
TLS 1.2: 2
```

| Показник | TLS 1.3 | TLS 1.2 |
|---|---|---|
| Довжина ClientHello, байт | 330 | 225 |
| Номер першого запису, тип якого спостерігач не бачить | 4 | 8 |
| Кількість RTT від ClientHello до першого HTTP-запиту | 1 | 2 |
| Чи видно сертифікат у дампі (результат 2.4) | Ні (0) | Так (2) |
| Обраний протокол ALPN | h2 | h2 |

1. За якими рядками виводу 2.1 визначено, з якого запису починається шифрування? Що бачить спостерігач замість типу кожного наступного запису?<br>
Початок шифрування визначено за рядком Received Record. Спостерігач замість типу кожного наступного запису бачить зовнішній тип, наприклад ApplicationData.

2. Чому ClientHello у TLS 1.3 довший, ніж у TLS 1.2? Назвіть розширення, яке за рахунок цього скорочує рукостискання на один RTT.<br>
ClientHello у TLS 1.3 довший тому, що він містить додаткові розширення для параметрів шифрування і ключів. Розширення key_share скоросує рукостискання на один RTT.

3. Довжина розширення `server_name` у виводі 2.3 становить 17 байт для імені з 12 символів. З яких частин складається це значення і яким воно буде для вашого імені?<br>
Довжина розширення server_name складається зі: списку імен (2 байти), типу імені (1 байт), довжини імені (2 байти) та з довжини самого імені. Для мого імені сервера, vault.se-201-28.lab, яке складається з 19 символів, довжина буде дорівнювати 24 байти.

4. Навіщо в TLS 1.3 передається запис ChangeCipherSpec, якщо в рукостисканні він нічого не змінює?<br>
У TLS 1.3 запис ChangeCipherSpec передається для сумісності зі старими мережевими пристроями і програмним забезпеченням.

## Завдання 3. Сертифікат для власного сервера

Вивід кроків 3.1 і 3.2:

```text
збережено /lab/tls/acme-root.crt
subject=CN = Pebble Root CA 747649
notBefore=Nov 11 14:14:55 2026 GMT
notAfter=Nov 11 14:14:55 2056 GMT

curl: (60) SSL certificate problem: self-signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

Вивід кроку 3.3 (останні рядки `lego` і рядки журналу nginx):

```text

2026/11/11 15:12:32 [INFO] [www.se-201-28.lab] acme: Trying to solve HTTP-01
2026/11/11 15:12:35 [INFO] [www.se-201-28.lab] The server validated our request
2026/11/11 15:12:35 [INFO] [www.se-201-28.lab, news.se-201-28.lab] acme: Validations succeeded; requesting certificates
2026/11/11 15:12:35 [INFO] Wait for certificate [timeout: 30s, interval: 500ms]
2026/11/11 15:12:35 [INFO] [www.se-201-28.lab] Server responded with a certificate.
10.53.0.10 - - [11/Nov/2026:15:12:25 +0000] "GET /.well-known/acme-challenge/kRVDEi7otpfkvoiDONx9f8jbHNFDpd1W0ER0gHCVYKI HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
10.53.0.10 - - [11/Nov/2026:15:12:25 +0000] "GET /.well-known/acme-challenge/kRVDEi7otpfkvoiDONx9f8jbHNFDpd1W0ER0gHCVYKI HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
10.53.0.10 - - [11/Nov/2026:15:12:25 +0000] "GET /.well-known/acme-challenge/kRVDEi7otpfkvoiDONx9f8jbHNFDpd1W0ER0gHCVYKI HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
10.53.0.10 - - [11/Nov/2026:15:12:32 +0000] "GET /.well-known/acme-challenge/wabFpUwa0GgFD35xNEu0FKyaoOA9lzlqF2Rn-cLfOiY HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
10.53.0.10 - - [11/Nov/2026:15:12:32 +0000] "GET /.well-known/acme-challenge/wabFpUwa0GgFD35xNEu0FKyaoOA9lzlqF2Rn-cLfOiY HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
10.53.0.10 - - [11/Nov/2026:15:12:32 +0000] "GET /.well-known/acme-challenge/wabFpUwa0GgFD35xNEu0FKyaoOA9lzlqF2Rn-cLfOiY HTTP/1.1" 200 87 "-" "LetsEncrypt-Pebble-VA (linux; amd64)"
```

Вивід кроку 3.4:

```text
subject=CN = www.se-201-28.lab
issuer=CN = Pebble Intermediate CA 224b7a
notBefore=Nov 11 15:12:35 2026 GMT
notAfter=Nov 11 15:12:34 2031 GMT
serial=3A388027D0CAC107
X509v3 Subject Alternative Name: 
    DNS:www.se-201-28.lab, DNS:news.se-201-28.lab
subject=CN = Pebble Intermediate CA 224b7a
issuer=CN = Pebble Root CA 747649
```

Вивід кроку 3.5:

```text
nginx: the configuration file /lab/nginx.conf syntax is ok
nginx: configuration file /lab/nginx.conf test is successful
2026/11/11 15:16:30 [notice] 111#111: signal process started
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
Certificate chain
 0 s:CN = www.se-201-28.lab
   i:CN = Pebble Intermediate CA 224b7a
   a:PKEY: id-ecPublicKey, 256 (bit); sigalg: RSA-SHA256
   v:NotBefore: Nov 11 15:12:35 2026 GMT; NotAfter: Nov 11 15:12:34 2031 GMT
---
Verify return code: 21 (unable to verify the first certificate)
```

Вивід кроку 3.6:

```text
nginx: the configuration file /lab/nginx.conf syntax is ok
nginx: configuration file /lab/nginx.conf test is successful
2026/11/11 15:17:31 [notice] 119#119: signal process started

server: se-201-28 (https)
Host: www.se-201-28.lab
SNI: www.se-201-28.lab
protocol: TLSv1.3
Certificate chain
 0 s:CN = www.se-201-28.lab
   i:CN = Pebble Intermediate CA 224b7a
   a:PKEY: id-ecPublicKey, 256 (bit); sigalg: RSA-SHA256
   v:NotBefore: Nov 11 15:12:35 2026 GMT; NotAfter: Nov 11 15:12:34 2031 GMT
 1 s:CN = Pebble Intermediate CA 224b7a
   i:CN = Pebble Root CA 747649
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Nov 11 14:14:55 2026 GMT; NotAfter: Nov 11 14:14:55 2056 GMT
---
Verify return code: 0 (ok)
server: se-201-28 (https)
Host: news.se-201-28.lab
SNI: news.se-201-28.lab
protocol: TLSv1.3
```

| Параметр | Значення |
|---|---|
| Видавець сертифіката сервера | Pebble Intermediate CA 224b7a |
| Видавець сертифіката видавця | Pebble Root CA 747649 |
| Імена в SAN | www.se-201-28.lab, news.se-201-28.lab |
| Строк дії (від – до) | 11.11.2026 15:12:35 – 11.11.2031 15:12:34 GMT |
| Тип ключа сервера і алгоритм підпису | EC, 256 біт; RSA-SHA256 |
| Кількість сертифікатів, які надсилає сервер, у кроці 3.5 і в кроці 3.6 | 3.5 — 1 сертифікат; 3.6 — 2 сертифікати |

1. Хто і як перевірив, що ви контролюєте обидва імена? Вкажіть рядки виводу, які це підтверджують.<br>
Контроль перевірив центр сертифікації Pebble через ACME-протокол методом HTTP-01.

2. Чому в кроці 3.5 перевірка не пройшла, хоча корінь центру сертифікації вказано в `--cacert`, а сертифікат виданий правильно?<br>
У кроці 3.5 сервер надсилав лише кінцевий сертифікат сайту, але не надсилав проміжний сертифікат Pebble Intermediate CA 224b7a.

3. У виводі ланцюжка для сертифіката сервера вказано `id-ecPublicKey` і `RSA-SHA256`. Що означає кожне з цих значень і чому вони не суперечать одне одному?<br>
id-ecPublicKey це тип відкритого ключа сервера, RSA-SHA256 це алгоритм, яким видавець підписав сертифікат. Значення не суперечать одне одному тому, що  ключ сервера і ключ видавця сертифіката можуть використовувати різні криптографічні алгоритми.

4. Що станеться з перевіркою вашого сервера після перезапуску стенда і чому? Що в реальній інфраструктурі відповідає цій ситуації?<br>
Після перезапуску стенда сертифікат стане недоступним для перевірки. У реальній інфраструктурі ситуація відповідає втраті TLS-сертифіката і його приватного ключа під час відновлення сервера.

## Завдання 4. Діагностика несправностей

Вивід кроку 4.1:

```text
=== f1.se-201-28.lab
curl: (60) SSL: no alternative certificate subject name matches target host name 'f1.se-201-28.lab'
Certificate chain
 0 s:CN = intra.se-201-28.lab
   i:O = OPISM Lab, CN = OPISM Stand Intermediate CA
   v:NotBefore: Nov 11 14:14:54 2026 GMT; NotAfter: Feb  9 14:14:54 2027 GMT
 1 s:O = OPISM Lab, CN = OPISM Stand Intermediate CA
   i:O = OPISM Lab, CN = OPISM Stand Root CA
   v:NotBefore: Nov 11 14:14:53 2026 GMT; NotAfter: Nov 10 14:14:53 2031 GMT
---
Verify return code: 0 (ok)
=== f2.se-201-28.lab
server: web, f2
Certificate chain
 0 s:CN = f2.se-201-28.lab
   i:O = OPISM Lab, CN = OPISM Stand Intermediate CA
   v:NotBefore: Nov 11 14:14:54 2026 GMT; NotAfter: Feb  9 14:14:54 2027 GMT
 1 s:O = OPISM Lab, CN = OPISM Stand Intermediate CA
   i:O = OPISM Lab, CN = OPISM Stand Root CA
   v:NotBefore: Nov 11 14:14:53 2026 GMT; NotAfter: Nov 10 14:14:53 2031 GMT
---
Verify return code: 0 (ok)
=== f3.se-201-28.lab
curl: (60) SSL certificate problem: unable to get local issuer certificate
Certificate chain
 0 s:CN = f3.se-201-28.lab
   i:O = Foreign Org, CN = Foreign Intermediate CA
   v:NotBefore: Nov 11 14:14:54 2026 GMT; NotAfter: Feb  9 14:14:54 2027 GMT
 1 s:O = Foreign Org, CN = Foreign Intermediate CA
   i:O = Foreign Org, CN = Foreign Root CA
   v:NotBefore: Nov 11 14:14:53 2026 GMT; NotAfter: Nov 10 14:14:53 2031 GMT
---
Verify return code: 20 (unable to get local issuer certificate)
=== f4.se-201-28.lab
curl: (60) SSL certificate problem: certificate has expired
Certificate chain
 0 s:CN = f4.se-201-28.lab
   i:O = OPISM Lab, CN = OPISM Stand Intermediate CA
   v:NotBefore: Apr 25 14:14:54 2026 GMT; NotAfter: Oct 22 14:14:54 2026 GMT
 1 s:O = OPISM Lab, CN = OPISM Stand Intermediate CA
   i:O = OPISM Lab, CN = OPISM Stand Root CA
   v:NotBefore: Nov 11 14:14:53 2026 GMT; NotAfter: Nov 10 14:14:53 2031 GMT
---
Verify return code: 10 (certificate has expired)
=== f5.se-201-28.lab
curl: (60) SSL certificate problem: unable to get local issuer certificate
Certificate chain
 0 s:CN = f5.se-201-28.lab
   i:O = OPISM Lab, CN = OPISM Stand Intermediate CA
   v:NotBefore: Nov 11 14:14:54 2026 GMT; NotAfter: Feb  9 14:14:54 2027 GMT
---
Verify return code: 21 (unable to verify the first certificate)
```

| Сервер | Помилка `curl` | `Verify return code` | Яка перевірка не пройшла | Рядок виводу, що це доводить | Що має змінити власник сервера |
|---|---|---|---|---|---|
| f1 | 60 | 0 | відповідність SAN | no alternative certificate subject name matches target host name 'f1.se-201-28.lab' | встановити відповідний сертифікат сервера |
| f2 | — | 0 | — | server: web, f2 | — |
| f3 | 60 | 10 | довіра до центру сертифікації | i:O = Foreign Org, CN = Foreign Root CA | отримати сертифікат від центру сертифікації, якому довіряє клієнт |
| f4 | 60 | 20 | строк дії сертифікати | NotAfter: Nov 10 14:14:53 2031 GMT | встановити новий сертифікат |
| f5 | 60 | 21 | повнота сертифіката | Certificate chain не містить запису 1 | налаштувати сервер для надсилання проміжного сертифікату |

1. Для сервера з помилкою `unable to get local issuer certificate` визначте, яка це несправність: сервер не надсилає проміжний сертифікат чи сертифікат виданий центром, якому клієнт не довіряє. Чим ці дві несправності відрізняються у виводі `openssl s_client`? <br>
Для сервера f3 це недовіра клієнту до сертифіката, для сервера f5 це відсутність проміжного сертифіката. Відмінність несправносей заключається в тому, що для сервера f3 сервер надсилайє проміжний сертифікат але веде до непідтвердженого центру, в той час як сервер f5 взагалі не містить проміжного сертифіката в ланцюгу.

2. Якщо серед ваших серверів є сервер з невідповідним ім'ям, чому `openssl s_client` повертає для нього `Verify return code: 0 (ok)`, а `curl` повідомляє про помилку? Якщо такого сервера немає, дайте відповідь для загального випадку.<br>
openssl s_client перевіряє ланцюг довіри сертифіката, але не перевіряє, чи відповідає ім'я сервера імені в сертифікаті на відміну від curl.

3. Які з п'яти серверів відповіли б на запит `curl -k`? Що при цьому втрачається порівняно з `--cacert`?<br>
На запит curl -k відповіли б усі п'ять серверів. Порівняно з флагом --cecert клієнт перестає перевіряти сертифікати.

## Завдання 5. Ціна нового з'єднання

**Прогноз** (записати до вимірювання). Скільки RTT мине до завершення кожного етапу:

| Етап | TLS 1.3, нове з'єднання | TLS 1.2, нове з'єднання | Повторне використання з'єднання |
|---|---|---|---|
| `time_connect` | 1 | 1 | 0 |
| `time_appconnect` | 2 | 3 | 0 |
| `time_starttransfer` | 3 | 4 | 1 |

Вивід кроків 5.2 і 5.3:

```text
=== TLS 1.3: три нові з'єднання
0.063426 0.103680 0.143856 0.164352 0.164461 2 1
0.020430 0.040877 0.064239 0.084519 0.084579 2 1
0.020447 0.040569 0.063923 0.084197 0.084254 2 1
=== TLS 1.2: три нові з'єднання
0.020468 0.040583 0.084170 0.104479 0.104548 2 1
0.020506 0.040629 0.083978 0.104327 0.104395 2 1
0.020478 0.040642 0.085518 0.105790 0.105854 2 1

0.041000 0.061163 0.087098 0.107665 0.107714 2 1
0.000017 0.000000 0.000000 0.020639 0.020705 2 0
0.000018 0.000000 0.000000 0.021544 0.021606 2 0
```

<!-- Значення в мілісекундах. Для нових з'єднань — медіана трьох вимірювань. -->

| Запит | `namelookup` | `connect` | `appconnect` | `starttransfer` | `total` | `num_connects` |
|---|---|---|---|---|---|---|
| TLS 1.3, нове | 20.447 | 40.877 | 64.239 | 84.519 | 84.579 | 1 |
| TLS 1.2, нове | 20.478 | 40.629 | 84.170 | 104.479 | 104.548	| 1 |
| 5.3, перший запит | 41.000 | 61.163 | 87.098 | 107.665 | 107.714 | 1 |
| 5.3, другий запит | 0.017	| 0 | 0 | 20.639 | 20.705	| 0 |
| 5.3, третій запит | 0.018 | 0 | 0 | 21.544 | 21.606 | 0 |

RTT, визначений вимірюванням, і з якого значення його визначено:

1. Виразіть кожне виміряне значення через RTT. Де вимірювання відрізняється від цілого числа RTT і чим це пояснюється?<br>


2. Чому `time_namelookup` не близький до нуля, хоча резолвер уже має ім'я в кеші? За яких умов він був би приблизно вдвічі більшим?<br>


3. Сервіс виконує 200 послідовних запитів до цього сервера. Розрахуйте, скільки часу займе лише очікування мережі, якщо кожен запит встановлює нове з'єднання TLS 1.3, нове з'єднання TLS 1.2 і якщо всі запити йдуть через одне з'єднання.<br>


## Висновки

**Що виявилося несподіваним.** Результат, який не збігся з очікуванням, і рядок виводу, де це видно:

**Яке питання залишилося без відповіді.** Що саме не вдалося пояснити; до якого рядка виводу це стосується; що вже перевірено і що з'ясувати не вдалося:

## Декларація використання ШІ

Використовувалися інструменти ШІ: так

<!-- Якщо так, заповнити таблицю: один рядок на кожне звернення, що вплинуло на звіт. Промпт наводити дослівно. -->

| № | Інструмент | Промпт (дослівно) | Що використано у звіті і що змінено самостійно |
|---|---|---|---|
| 1 | | | |
