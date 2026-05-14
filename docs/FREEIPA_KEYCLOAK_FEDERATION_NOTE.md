# FreeIPA → Keycloak federation + SAML SSO (implementation note)
Branch: `keycloak-freeipa-template`
Apps deployed end-to-end: **Jenkins** and **SonarQube**
## What was built
1. **FreeIPA prep** — new role `freeipa_keycloak_prep`. On the IPA master,
   it ensures two dedicated IPA service users exist — `svc.ldap` (LDAP
   bind account) and `svc.keycloak` (Keycloak app service user) —
   creates canonical app admin groups (`jenkins-administrators`,
   `sonar-administrators`), and exports the IPA CA cert to a known path.
2. **Keycloak LDAP federation** — new submodule of the existing
   `keycloak_saml_integration` role under `tasks/ldap/`. It imports the
   IPA CA into Keycloak's JKS truststore, wires the SPI truststore
   options into `keycloak.conf`, restarts Keycloak, then via the admin
   REST API creates / updates the `freeipa-ldap` UserStorageProvider
   plus its mappers (username, email, firstName, lastName, full-name,
   group) and triggers a full sync.
3. **Per-app SAML config (SP side)** — leveraged the existing
   `keycloak_saml_integration` role with two new tasks_from entry
   points (`keycloak_setup.yml`, `app_setup.yml`) so the admin REST
   calls run on the Keycloak host (against `http://localhost:8080`)
   and the app-side file edits run on the application host.
4. **Var consolidation** — all FreeIPA / Keycloak LDAP federation
   variables were lifted into one file, `group_vars/all/freeipa.yml`.
   Inventory IPs/DNS were aligned with the reference setup
   (freeipa.local 192.168.56.14, keycloak.local .12, sonar.local .18,
   jenkins.local .13). Three new vault keys:
   `vault_freeipa_admin_password`, `vault_freeipa_ldap_bind_password`,
   `vault_freeipa_keycloak_svc_password`, `vault_keycloak_truststore_password`.
## How to run
```bash
# One-shot: FreeIPA prep + Keycloak LDAP federation + sync
ansible-playbook -i inventory playbooks/configure-keycloak-ldap-federation.yml
# Per-app SAML configuration
ansible-playbook -i inventory playbooks/configure-keycloak-saml-integration.yml -e app=jenkins
ansible-playbook -i inventory playbooks/configure-keycloak-saml-integration.yml -e app=sonarqube
# Or the make wrapper that does federation, then jenkins, then sonarqube
make deploy-saml-stack
```
## User and group sync from FreeIPA
Keycloak's `freeipa-ldap` UserStorageProvider is configured READ_ONLY
with `importEnabled=true` and full sync every 24h (changed-user sync
hourly). On `triggerFullSync` Keycloak walks
`cn=users,cn=accounts,dc=…` and writes a Keycloak user record for each
IPA account; the group LDAP mapper walks `cn=groups,cn=accounts,dc=…`
and imports the IPA groups (flat, since
`preserve.group.inheritance=false` to avoid the
`GroupsMultipleParents` 400 from nested IPA groups).
End-state on the working server:
```text
LDAP provider 'freeipa-ldap' (ID: 9a0d15d1-…) status: updated
FreeIPA full sync result:
  {'ignored': False, 'added': 0, 'updated': 7, 'removed': 0, 'failed': 0,
   'status': '0 imported users, 7 updated users'}
```
Authorization model going forward: **no Keycloak-managed parent
groups, subgroups, client roles, or test users**. App-level admin
elevation is granted by membership of an IPA group whose name matches
the app's built-in admin group:
- IPA `jenkins-administrators` → Jenkins admins
- IPA `sonar-administrators`   → SonarQube admins
The SAML `groups` attribute carries those names through to each app.
## Federated SAML SSO — verified
Both Jenkins and SonarQube share the same Keycloak `master` realm.
Once a user signs into either app with FreeIPA credentials, Keycloak
holds the realm session in the browser; clicking SAML SSO on the
other app(s) completes silently without re-prompting for credentials.
Verified flow:
1. Open `https://sonar.local` (or `https://jenkins.local`) in a fresh
   browser session.
2. Click *Log in with SSO*.
3. Keycloak shows its login page → enter a FreeIPA username and
   password (the user is in the IPA database, never created in
   Keycloak directly).
4. Lands in SonarQube (or Jenkins).
5. In the *same* browser, navigate to the other app and click its
   SSO button → no login prompt, you're in.
That single Keycloak realm session is the SSO glue. Adding a third
SAML SP (Wazuh, Artifactory, Nexus, …) to the same realm makes them
participate in the same session — login once, access them all until
the realm session expires.
## Pointers
- Role README: `roles/keycloak_saml_integration/README.md`
- Federation playbook: `playbooks/configure-keycloak-ldap-federation.yml`
- Per-app playbook: `playbooks/configure-keycloak-saml-integration.yml`
- Variables: `group_vars/all/freeipa.yml`,
  `group_vars/all/saml_integration.yml`, `group_vars/all/vault.yml`
  (encrypted; see `group_vars/all/vault.yml.example`).
- Vault key reference: `VAULT_USAGE.md`.
