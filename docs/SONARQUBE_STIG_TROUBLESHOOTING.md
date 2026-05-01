# SonarQube hangs / loads forever after STIG hardening — diagnostics
SonarQube doesn't use httpd / Apache — it ships an embedded Java web tier
(Jetty) plus an Elasticsearch index process and a Compute Engine, all
launched by `/opt/sonarqube`. When the browser tab loads forever, it's
usually one of these four post-STIG culprits:
| Culprit | What it breaks | Quick check |
|---|---|---|
| `vm.max_map_count < 262144` | Elasticsearch refuses to start (or thrashes) | `sysctl vm.max_map_count` |
| File-descriptor limits lowered | Java processes hit *Too many open files* | `cat /proc/$(pgrep -f sonar.web)/limits \| grep -i open` |
| SELinux enforcing + sonar relabel | Java can't read its own dirs or open its ports | `getenforce` + `ausearch -m AVC -ts recent` |
| firewalld blocking 9000 / 9001 / ES dynamic port | Web ↔ ES loopback or external `:9000` is dropped | `firewall-cmd --list-all` |
The web log is the source of truth — when the page hangs forever,
`web.log` shows exactly where it's stuck (waiting for ES, DB schema
migration, SAML init, etc).
## Run these on the SonarQube host
### Web server / sibling logs
```bash
ls -la /opt/sonarqube/logs/
tail -n 200 /opt/sonarqube/logs/web.log     # Jetty / web tier
tail -n 100 /opt/sonarqube/logs/sonar.log   # supervisor (orchestrates ES + web + ce)
tail -n 100 /opt/sonarqube/logs/es.log      # Elasticsearch
tail -n 100 /opt/sonarqube/logs/ce.log      # Compute Engine
```
### Common failure-mode filter
```bash
grep -iE 'error|exception|fail|timeout|stuck|out of memory|too many open files|max_map_count|tls|saml|migration' \
  /opt/sonarqube/logs/*.log | tail -50
```
### Process / port health
```bash
systemctl is-active sonarqube
ps -ef | grep -E '[s]onar|[e]lasticsearch'      # expect 3 java procs
ss -lnt  | grep -E ':9000|:9001|:9092'          # web=9000, es-http=9001, h2=9092
```
### Resource ceilings (STIG often tightens these)
```bash
sysctl vm.max_map_count fs.file-max
ulimit -n
cat /proc/$(pgrep -f sonar.web)/limits 2>/dev/null \
  | grep -E 'open files|processes|locked memory'
```
### Sandboxing layers STIG flips on
```bash
getenforce
ausearch -m AVC -ts recent 2>/dev/null | tail -50
journalctl -u firewalld -n 20 --no-pager
firewall-cmd --list-all 2>/dev/null
journalctl -u fapolicyd -n 30 --no-pager 2>/dev/null    # only if fapolicyd is in the STIG profile
```
### Reachability / readiness
```bash
curl -kI  https://sonar.local                                # what the proxy says
curl -sI  http://127.0.0.1:9000/api/system/status            # backend readiness:
                                                             # UP / STARTING / DOWN / DB_MIGRATION_NEEDED / …
```
That last `curl` is the most decisive:
- `UP` → backend is fine; the hang is in the proxy / TLS layer.
- `STARTING` / `DB_MIGRATION_NEEDED` / `DOWN` → backend isn't ready; root cause is in `web.log` / `es.log`.
## Likely fixes once you've identified the cause
| Cause | Fix |
|---|---|
| `vm.max_map_count` too low | `sysctl -w vm.max_map_count=262144` (and persist in `/etc/sysctl.d/99-sonarqube.conf`) |
| File-descriptor limit too low | systemd drop-in for `sonarqube.service`: `[Service]\nLimitNOFILE=65536` |
| SELinux blocking | Either `setenforce 0` (test only) or write the right policy and `restorecon -R /opt/sonarqube` |
| firewalld blocking 9000 | `firewall-cmd --add-port=9000/tcp --permanent && firewall-cmd --reload` (loopback 9001/9092 must always be reachable from the host) |
| Stale SAML SP private key (PKCS#8 error) | Empty `sonar.auth.saml.sp.privateKey.secured` and `sonar.auth.saml.sp.certificate.secured` in `/opt/sonarqube/conf/sonar.properties`, or generate a real PKCS#8 keypair if signing is required |
## What the role expects to be true
The `keycloak_saml_integration` role assumes a working SonarQube web
backend on `127.0.0.1:9000`. It rewrites `sonar.properties` and restarts
SonarQube but does NOT manage host-level OS hardening. Anything in the
table above lives outside SAML and is the operator's responsibility on
each STIG'd host.
