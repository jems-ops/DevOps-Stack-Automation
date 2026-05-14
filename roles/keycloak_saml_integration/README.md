# keycloak_saml_integration
Ansible role that wires up Keycloak ↔ application SAML SSO (the SP-side
side of the stack: per-app SAML clients, protocol mappers, and on-host
SAML configuration). User and group federation from FreeIPA is owned by
a separate role, [`freeipa_keycloak_prep`](../freeipa_keycloak_prep/),
which both prepares IPA and configures Keycloak's LDAP federation.
Authorization is driven by FreeIPA-side groups synced into Keycloak
through the LDAP `group-ldap-mapper` provided by `freeipa_keycloak_prep`.
> **Read this first**: a one-page summary of the federation + cross-app
> SSO behavior is in
> [`docs/Freeipa-keycloak-sso-summary.md`](../../docs/Freeipa-keycloak-sso-summary.md).
> A longer implementation note is in
> [`docs/FREEIPA_KEYCLOAK_FEDERATION_NOTE.md`](../../docs/FREEIPA_KEYCLOAK_FEDERATION_NOTE.md).
## Currently enabled apps
Jenkins and SonarQube are deployed end-to-end on the
`keycloak-freeipa-template` branch. Task files for Artifactory, Nexus,
Security Center, and Wazuh are scaffolded but not part of the default
`deploy-saml-stack` flow.
## What it does
1. **Per-app Keycloak setup** (on the Keycloak host, against
   `http://localhost:8080`): obtains an admin token, ensures the realm
   exists, creates/updates the SAML client, configures protocol mappers,
   extracts the IdP certificate.
2. **Per-app application setup** (on the application host): pulls the
   SAML client UUID + IdP cert from the Keycloak host's facts, writes
   the app's SAML configuration, restarts the service.
This role does NOT create Keycloak-managed users, parent groups,
subgroups, client roles, or test users — user identities and group
membership all come from FreeIPA via
[`freeipa_keycloak_prep`](../freeipa_keycloak_prep/) (which also owns
the Keycloak-side `freeipa-ldap` UserStorageProvider, mappers, and the
IPA CA truststore wiring).
## Layout
Task files are organized into category subfolders so the entry points
at the root of `tasks/` are easy to find and the supporting tasks are
grouped by purpose.
```
roles/keycloak_saml_integration/
├── defaults/main.yml
├── handlers/main.yml
├── tasks/
│   ├── keycloak_setup.yml          # entry point: Keycloak-side per-app setup
│   ├── app_setup.yml               # entry point: app-side per-app setup
│   ├── main.yml                    # entry point: legacy single-host flow
│   ├── keycloak/                   # Keycloak admin REST helpers
│   │   ├── get_keycloak_token.yml
│   │   ├── create_keycloak_realm.yml
│   │   ├── create_saml_client.yml
│   │   ├── configure_protocol_mappers.yml
│   │   ├── get_keycloak_certificate.yml
│   │   └── preflight_checks.yml
│   ├── apps/                       # per-app SAML configuration on the app host
│   │   ├── configure_jenkins_saml.yml
│   │   ├── configure_sonarqube_saml.yml
│   │   ├── configure_artifactory_saml.yml
│   │   ├── configure_nexus_saml.yml
│   │   ├── configure_nessus_saml.yml
│   │   ├── configure_securitycenter_saml.yml
│   │   └── configure_wazuh_saml.yml
│   └── common/                     # shared helpers (e.g. backup_config)
│       ├── backup_config.yml
│       └── get_groups.yml
├── templates/
│   ├── jenkins-saml-config.xml.j2
│   ├── sonarqube-saml-config.properties.j2
│   └── artifactory-saml-config.xml.j2
└── vars/apps/
    ├── jenkins.yml
    ├── sonarqube.yml
    ├── artifactory.yml
    ├── nexus.yml
    ├── securitycenter.yml
    └── wazuh.yml
```
## Prerequisites
Vault keys (encrypt in `group_vars/all/vault.yml`; full reference in
`group_vars/all/vault.yml.example`):
- `vault_keycloak_admin_password`
- `vault_freeipa_admin_password`
- `vault_freeipa_ldap_bind_password`
- `vault_freeipa_keycloak_svc_password`
- `vault_keycloak_truststore_password`
Inventory groups in `inventory`:
- `[freeipa]`, `[keycloak]`, `[jenkins_servers]`, `[sonarqube_servers]`
## How to run — ansible-playbook
All commands assume the repo root as the working directory.
### 1. FreeIPA → Keycloak LDAP federation (run once)
Prepares the IPA bind user / admin groups / CA, then configures the
LDAP UserStorageProvider in Keycloak and triggers a sync.
```bash
ansible-playbook -i inventory playbooks/configure-keycloak-ldap-federation.yml
```
Tag-scoped variants:
```bash
# FreeIPA prep only (svc.ldap + svc.keycloak users, admin groups, CA export)
ansible-playbook -i inventory playbooks/configure-keycloak-ldap-federation.yml --tags freeipa_prep
# Keycloak LDAP federation only (truststore, provider, mappers, sync)
ansible-playbook -i inventory playbooks/configure-keycloak-ldap-federation.yml --tags ldap
```
### 2. Per-app SAML configuration
The playbook is two plays — Keycloak-side first (on the Keycloak host
against `http://localhost:8080`), then app-side on the application host.
Pass the app via `-e app=<name>`.
```bash
# Jenkins
ansible-playbook -i inventory playbooks/configure-keycloak-saml-integration.yml -e "app=jenkins"
# SonarQube
ansible-playbook -i inventory playbooks/configure-keycloak-saml-integration.yml -e "app=sonarqube"
```
## How to run — make
The Makefile wraps the same playbooks with shorter targets.
```bash
# FreeIPA prep + Keycloak LDAP federation, end-to-end
make configure-keycloak-ldap-federation
# Just FreeIPA prep, or just Keycloak LDAP federation:
make freeipa-prep
make keycloak-ldap
# Federation first, then per-app SAML for jenkins and sonarqube
make deploy-saml-stack
```
## Verifying the deployment
```bash
# Lint and syntax-check
ansible-lint playbooks/ roles/keycloak_saml_integration/
ansible-playbook -i inventory --syntax-check playbooks/configure-keycloak-ldap-federation.yml
ansible-playbook -i inventory --syntax-check playbooks/configure-keycloak-saml-integration.yml -e app=jenkins
# IdP descriptor reachable
curl -ks https://keycloak.local/realms/master/protocol/saml/descriptor | head -1
# IPA users imported into Keycloak (after federation)
ansible -i inventory keycloak -m shell -a \
  '/opt/keycloak-22.0.5/bin/kcadm.sh get users -r master --no-config --server http://localhost:8080 --realm master --user admin --password $KC_ADMIN | head'
# App SP login URLs
curl -kI https://jenkins.local/securityRealm/commenceLogin
curl -kI https://sonar.local
```
After `make deploy-saml-stack`, log in to Jenkins or SonarQube with a
FreeIPA user. Membership of `jenkins-administrators` /
`sonar-administrators` (groups created by `freeipa_keycloak_prep`)
grants admin in the respective app via the SAML `groups` attribute.
## Adding another app
1. Add a host group to `inventory` and a host var file under
   `group_vars/all/` (or extend `saml_integration.yml`) for
   `<app>_hostname` / `<app>_base_url`.
2. Drop a config file at `roles/keycloak_saml_integration/vars/apps/<app>.yml`
   following `vars/apps/jenkins.yml` as a template.
3. Add `tasks/configure_<app>_saml.yml` for the app-side SAML config
   (file edits + service restart on the app host).
4. If the app needs Keycloak admin API calls (e.g. fetching a metadata
   bundle), run them with `delegate_to: "{{ groups['keycloak'][0] }}"`
   and use `http://localhost:8080`, mirroring the Wazuh pattern in
   `tasks/configure_wazuh_saml.yml`.
5. Add `<app>` to the supported-apps assertion in
   `tasks/keycloak_setup.yml` (the validation step). Drop the new
   per-app file under `tasks/apps/configure_<app>_saml.yml`.
6. Create a FreeIPA admin group named after the app's built-in admin
   role (e.g. `myapp-administrators`) by appending it to
   `freeipa_app_admin_groups` in `group_vars/all/freeipa.yml`.
7. Run `ansible-playbook ... -e app=<app>` (or extend the
   `deploy-saml-stack` Makefile target's app loop).
## Further reading
- [`docs/Freeipa-keycloak-sso-summary.md`](../../docs/Freeipa-keycloak-sso-summary.md) — short reference describing the role's behavior, the SSO session flow across applications, sync details, and prerequisites.
- [`docs/FREEIPA_KEYCLOAK_FEDERATION_NOTE.md`](../../docs/FREEIPA_KEYCLOAK_FEDERATION_NOTE.md) — implementation note covering what was built, the verified end-to-end SSO flow with Jenkins and SonarQube, and pointers to the relevant playbooks / vars.
