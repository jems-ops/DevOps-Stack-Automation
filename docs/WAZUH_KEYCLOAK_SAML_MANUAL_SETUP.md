# Wazuh – Keycloak SAML SSO (Administrator Role)

Short, implementation-focused guide for integrating Keycloak as SAML IdP for Wazuh Dashboard administrator access.

---

## 1. Overview

| Item            | Value / Notes                                    |
|-----------------|--------------------------------------------------|
| IdP             | Keycloak (SAML)                                  |
| SP              | Wazuh Dashboard via Wazuh Indexer SAML plugin    |
| Role model      | Keycloak realm role `admin` → Wazuh `all_access` |
| Target audience | Wazuh / Keycloak admins                          |

Integration has three stages:

1. Keycloak configuration
2. Wazuh Indexer configuration
3. Wazuh Dashboard configuration

---

## 2. Keycloak Configuration

### 2.1 Realm and Client

| Step | Location                        | Setting                 | Value / Example                                |
|------|---------------------------------|-------------------------|-----------------------------------------------|
| 1    | Realms                          | Realm name              | `Wazuh` (or preferred realm name)             |
| 2    | Clients → **Create client**     | Client type             | `SAML`                                        |
|      |                                 | Client ID               | `wazuh-saml` (becomes `sp.entity_id`)         |
| 3    | Clients → `wazuh-saml` → Settings | Enabled               | ON                                            |
|      |                                 | Client ID               | `wazuh-saml`                                  |
|      |                                 | Name                    | `Wazuh SSO` (label only)                      |
|      |                                 | Valid redirect URIs     | `https://{{ WAZUH_DASHBOARD_URL }}/*`         |
|      |                                 | IDP-Initiated SSO URL   | `wazuh-dashboard`                             |
|      |                                 | IDP-Initiated Relay State | `wazuh-dashboard`                           |
|      |                                 | Name ID format          | `username`                                    |
|      |                                 | Force POST binding      | ON                                            |
|      |                                 | Include AuthnStatement  | ON                                            |
|      |                                 | Sign documents          | ON                                            |
|      |                                 | Signature algorithm     | `RSA_SHA256`                                  |
|      |                                 | SAML signature key name | `NONE`                                        |
|      |                                 | Canonicalization        | `EXCLUSIVE`                                   |
|      |                                 | Front channel logout    | ON                                            |
| 4    | Clients → `wazuh-saml` → Keys   | Client signature req.   | OFF                                           |
| 5    | Clients → `wazuh-saml` → Advanced → Fine Grain SAML Endpoints | Assertion Consumer URL | `https://<WAZUH_DASHBOARD_URL>/_opendistro/_security/saml/acs/idpinitiated` |
|      |                                  | Logout Redirect URL     | `https://<WAZUH_DASHBOARD_URL>`              |

Replace `<WAZUH_DASHBOARD_URL>` with your actual dashboard URL.

### 2.2 Roles, Users, Groups

| Step | Location                  | Setting      | Value / Notes                                      |
|------|---------------------------|--------------|----------------------------------------------------|
| 6    | Realm roles → **Add role** | Role name   | `admin` (backend role mapped on Wazuh side)        |
| 7    | Users → **Add user**     | User         | Create Wazuh admin user                            |
|      | Users → *user* → Credentials | Password | Set non-temporary password                         |
| 8    | Groups → **New group**   | Group name   | e.g. `Wazuh-admins`                                |
|      | Groups → `Wazuh-admins`  | Members      | Add the admin user                                 |
|      | Groups → `Wazuh-admins`  | Role mapping | Assign realm role `admin` to the group             |

### 2.3 Protocol Mapper (Role list)

| Step | Location                                      | Setting             | Value / Notes                          |
|------|-----------------------------------------------|---------------------|----------------------------------------|
| 9    | Client scopes → `role_list` → Mappers         | Mapper type         | `Role list`                            |
|      | → **Configure a new mapper**                  | Name                | `wazuhRoleKey` (any name)              |
|      |                                               | Role attribute name | `Roles` (used as `roles_key` in Wazuh) |
|      |                                               | SAML Attribute NameFormat | `Basic`                        |
|      |                                               | Single Role Attribute | ON                                   |

### 2.4 Export SAML Metadata & Note Parameters

| Step | Location / Output                   | Parameter      | Usage in Wazuh                        |
|------|-------------------------------------|----------------|---------------------------------------|
| 10   | Clients → `wazuh-saml` → **Action → Download adapter config** (Format: *Mod Auth Mellon files*) | Files | `idp.metadata.xml`, `sp.metadata.xml` |
|      | `idp.metadata.xml`                  | `idp.entityID` | Wazuh Indexer `idp.entity_id`         |
|      | Client ID                           | `wazuh-saml`   | Wazuh Indexer `sp.entity_id`          |
|      | Mapper output                       | `Roles`        | Wazuh Indexer `roles_key`             |
|      | Dashboard URL                       | `https://...`  | Wazuh Indexer `kibana_url`            |

---

## 3. Wazuh Indexer Configuration

All paths below are on the Wazuh Indexer node.

### 3.1 Prepare keys and metadata

1. Generate exchange key (64 hex chars):

   ```bash
   openssl rand -hex 32
   ```

   Use the output as `exchange_key` in `config.yml`.

2. Copy SAML metadata to security directory:

   - Place `idp.metadata.xml` and `sp.metadata.xml` in `/etc/wazuh-indexer/opensearch-security/`.

3. Fix file ownership:

   ```bash
   chown wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/opensearch-security/idp.metadata.xml
   chown wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/opensearch-security/sp.metadata.xml
   ```

### 3.2 `config.yml` SAML authc

File: `/etc/wazuh-indexer/opensearch-security/config.yml`

1. In `authc.basic_internal_auth_domain` set:

   - `order: 0`
   - `http_authenticator.challenge: false`

2. Add / adjust `authc.saml_auth_domain` (example):

```yaml
authc:
  basic_internal_auth_domain:
    description: "Authenticate via HTTP Basic against internal users database"
    http_enabled: true
    transport_enabled: true
    order: 0
    http_authenticator:
      type: "basic"
      challenge: false
    authentication_backend:
      type: "intern"

  saml_auth_domain:
    http_enabled: true
    transport_enabled: false
    order: 1
    http_authenticator:
      type: saml
      challenge: true
      config:
        idp:
          metadata_file: '/etc/wazuh-indexer/opensearch-security/idp.metadata.xml'
          entity_id: 'http://<KEYCLOAK_HOST>/realms/Wazuh'
        sp:
          entity_id: wazuh-saml
          metadata_file: /etc/wazuh-indexer/opensearch-security/sp.metadata.xml
        kibana_url: https://<WAZUH_DASHBOARD_URL>
        roles_key: Roles
        exchange_key: '<OUTPUT_OF_OPENSSL>'
    authentication_backend:
      type: noop
```

Replace:

- `<KEYCLOAK_HOST>` with your Keycloak host.
- `<WAZUH_DASHBOARD_URL>` with your dashboard URL.
- `<OUTPUT_OF_OPENSSL>` with the hex string generated earlier.

3. Run `securityadmin` to apply `config.yml`:

```bash
export JAVA_HOME=/usr/share/wazuh-indexer/jdk/
bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -f /etc/wazuh-indexer/opensearch-security/config.yml \
  -icl \
  -key /etc/wazuh-indexer/certs/admin-key.pem \
  -cert /etc/wazuh-indexer/certs/admin.pem \
  -cacert /etc/wazuh-indexer/certs/root-ca.pem \
  -h 127.0.0.1 \
  -nhnv
```

### 3.3 `roles_mapping.yml`

File: `/etc/wazuh-indexer/opensearch-security/roles_mapping.yml`

Map Keycloak realm role `admin` to Wazuh `all_access`:

```yaml
all_access:
  reserved: false
  hidden: false
  backend_roles:
    - "admin"
```

Apply with `securityadmin`:

```bash
export JAVA_HOME=/usr/share/wazuh-indexer/jdk/
bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -f /etc/wazuh-indexer/opensearch-security/roles_mapping.yml \
  -icl \
  -key /etc/wazuh-indexer/certs/admin-key.pem \
  -cert /etc/wazuh-indexer/certs/admin.pem \
  -cacert /etc/wazuh-indexer/certs/root-ca.pem \
  -h 127.0.0.1 \
  -nhnv
```

---

## 4. Wazuh Dashboard Configuration

### 4.1 `wazuh.yml` run_as

File: `/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml`

```yaml
hosts:
  - default:
      url: https://127.0.0.1
      port: 55000
      username: wazuh-wui
      password: "<WAZUH_WUI_PASSWORD>"
      run_as: false
```

- If `run_as: false` → continue to 4.2.
- If `run_as: true` → create a role mapping in Wazuh Dashboard UI:
  - Role mapping name: any
  - Roles: `administrator`
  - User field: `backend_roles`
  - Search operation: `FIND`
  - Value: `admin` (Keycloak realm role)

### 4.2 `opensearch_dashboards.yml`

File: `/etc/wazuh-dashboard/opensearch_dashboards.yml`

```yaml
opensearch_security.auth.type: "saml"
server.xsrf.allowlist:
  - "/_opendistro/_security/saml/acs"
  - "/_opendistro/_security/saml/logout"
  - "/_opendistro/_security/saml/acs/idpinitiated"
opensearch_security.session.keepalive: false
```

### 4.3 Restart and Test

Restart Wazuh Dashboard:

```bash
systemctl restart wazuh-dashboard
# or
service wazuh-dashboard restart
```

Then test:

1. Open `https://<WAZUH_DASHBOARD_URL>`.
2. You should be redirected to Keycloak.
3. Log in with a user in group `Wazuh-admins` (role `admin`).
4. You should land in Wazuh Dashboard with administrator permissions.
