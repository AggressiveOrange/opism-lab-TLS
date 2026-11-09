#!/usr/bin/env python3
"""Smoke-test the TLS stand and check students' HTTPS servers.

Run next to the generated directory:
    python3 check.py --stand stand --smoke     # after start: DNS, ACME server, remote server, student nginx
    python3 check.py --stand stand             # grading: certificate installed on each student's server
    python3 check.py --stand stand --only s01,s02

Commands run inside the root container (docker compose exec), so nothing is needed on the host.
Grading checks the CURRENT ACME root: Pebble generates a new root at every start, so a certificate
issued before a stand restart fails verification and has to be re-issued.
"""
import argparse
import csv
import json
import shlex
import subprocess
import sys
from pathlib import Path


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--stand", default="stand")
    ap.add_argument("--smoke", action="store_true")
    ap.add_argument("--only", default="")
    args = ap.parse_args()

    stand = Path(args.stand)
    vfile = stand / "instructor/variants.json"
    if not vfile.exists():
        vfile = stand / "students.json"
    students = json.loads(vfile.read_text())
    if args.only:
        keep = set(args.only.split(","))
        students = [s for s in students if s["id"] in keep]
    compose = ["docker", "compose", "-f", str(stand / "compose.yaml")]

    def sh(cmd: str, service: str = "root") -> str:
        p = subprocess.run(compose + ["exec", "-T", service, "bash", "-c", cmd], capture_output=True, text=True)
        return p.stdout + p.stderr

    stand_ca = "/stand-pki/stand-root.crt"  # path inside the root container

    if args.smoke:
        bad = 0
        acme = "newOrder" in sh(f"curl -s --max-time 5 --cacert {stand_ca} https://ca.lab:14000/dir")
        print(f"{'OK  ' if acme else 'FAIL'} ACME server https://ca.lab:14000/dir")
        bad += not acme
        for s in students:
            z = f"{s['id']}.lab"
            res = {
                "dns": sh(f"dig @10.53.0.53 www.{z} A +short +time=2 +tries=2").strip().splitlines()[-1:] == [s["ip"]],
                "remote": "server: web" in sh(f"curl -s --max-time 5 --cacert {stand_ca} https://{s['remote']}.{z}/"),
                "nginx": f"server: {s['id']}" in sh(f"curl -sk --max-time 5 https://www.{z}/"),
                "netem": "netem" in sh("tc qdisc show dev eth0", service=s["id"]),
            }
            ok = all(res.values())
            bad += not ok
            print(f"{'OK  ' if ok else 'FAIL'} {s['id']:<10} " + " ".join(f"{k}={'yes' if v else 'NO'}" for k, v in res.items()))
        sys.exit(1 if bad else 0)

    sh(f"curl -s --cacert {stand_ca} https://ca.lab:15000/roots/0 > /tmp/acme-root.crt")
    rows = []
    for s in students:
        z = f"{s['id']}.lab"
        checks = {}
        for label, name in (("www", f"www.{z}"), ("alias", f"{s['alias']}.{z}")):
            out = sh(f"openssl s_client -connect {s['ip']}:443 -servername {name} -CAfile /tmp/acme-root.crt "
                     f"-showcerts </dev/null 2>&1")
            leaf = sh(f"openssl s_client -connect {s['ip']}:443 -servername {name} </dev/null 2>/dev/null "
                      f"| openssl x509 -noout -issuer -ext subjectAltName 2>&1")
            checks[f"{label}_acme_issuer"] = "Pebble Intermediate" in leaf
            checks[f"{label}_san_both"] = f"DNS:www.{z}" in leaf and f"DNS:{s['alias']}.{z}" in leaf
            checks[f"{label}_chain_sent"] = out.count("BEGIN CERTIFICATE") >= 2
            checks[f"{label}_verify_ok"] = "Verify return code: 0 (ok)" in out
        passed = sum(checks.values())
        rows.append({"id": s["id"], "passed": f"{passed}/{len(checks)}", **{k: int(v) for k, v in checks.items()}})
        print(f"{s['id']:<10} {passed:>2}/{len(checks)}  " + " ".join(("+" if v else "-") + k for k, v in checks.items()))

    if (stand / "instructor").is_dir():
        report = stand / "instructor/check-report.csv"
        with open(report, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
        print(f"\nreport: {report}")


if __name__ == "__main__":
    main()
