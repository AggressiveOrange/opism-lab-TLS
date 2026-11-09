# TLS lab stand (ОПІСМ, Topic 5)

Same layout as the DNS stand: one Docker image, one generated compose file, one container per student.

    docker build -t tlslab:latest image/
    python3 gen.py students.csv --out stand
    cd stand && docker compose up -d && cd ..
    python3 check.py --stand stand --smoke

Student mode (Codespaces): `python3 gen.py --student <id> --salt opism-2026`, then `./up.sh`.
`up.sh` builds the image if needed and stops the DNS stand first: both use 10.53.0.0/16.

Files:
- image/        Dockerfile, entrypoint (roles: pki, auth, resolver, ca, web, student), pki-init, shell helpers
- templates/    Jinja2 templates for every config, the student zone, nginx configs and the variant card
- gen.py        students.csv -> stand/ (configs, compose.yaml, cards/, instructor/answers.csv)
- check.py      smoke test (--smoke) and grading of the certificate on each student's server
- up.sh         start + Codespaces iptables fix + smoke test
- лб2-TLS-методичка.md, лб2-TLS-бланк.md   for students

Stand:
- root, tld, resolver-a: DNS hierarchy as in the DNS lab; student zones are pre-filled.
- pki: one-shot container, creates the stand PKI in stand/pki/ once (OPISM Stand Root/Intermediate,
  a foreign CA nobody trusts, the HTTPS certificate of ca.lab, certificates of the remote server and of f1-f5).
- ca (10.53.0.10, ca.lab): Pebble, ACME test CA from Ubuntu packages. HTTP-01 on port 80.
  Its root and intermediate are regenerated at every start: certificates issued before a restart stop verifying.
- web (10.53.0.80): nginx; the remote server <remote>.<id>.lab and f1-f5.<id>.lab, one server block per name (SNI).
- student: own zone (BIND), nginx with a ready config, ttyd; netem delay of the variant on eth0
  (needs NET_ADMIN and sch_netem on the host; smoke test reports netem=NO otherwise).

Variants: gen.py variant(id, salt). Faults per student: 4 of {expired, wrongname, selfsigned, nochain, unknownca}
plus one healthy server, shuffled over f1-f5. Delay 20-50 ms. Instructor answers: stand/instructor/answers.csv.

Never edit files in stand/ by hand; regenerate instead. Student zone files, stand/students/*/tls, */work
and stand/pki are never overwritten. Delete stand/pki to get new stand certificates.
