# nginx-keycloak-proxy

A clean, dedicated Ansible role for setting up Nginx as a reverse proxy for Keycloak with SSL termination.

## Features

- ✅ Clean SSL reverse proxy configuration for Keycloak
- ✅ Automatic HTTP to HTTPS redirects
- ✅ Self-signed certificate generation or custom certificate support
- ✅ Security headers and hardened SSL configuration
- ✅ Automatic cleanup of conflicting configurations
- ✅ Performance-optimized proxy settings
- ✅ Health check endpoint
- ✅ Comprehensive logging and error handling

## Requirements

- Nginx installed on target server
- OpenSSL for certificate generation
- Keycloak running on backend server
- Ansible 2.9 or later

## Role Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `keycloak_server_name` | Domain name for Keycloak | `keycloak.local` |
| `keycloak_backend_host` | Keycloak backend server IP/hostname | `192.168.201.12` |
| `keycloak_backend_port` | Keycloak backend port | `8080` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `keycloak_ssl_certificate_path` | `/etc/nginx/ssl/keycloak.crt` | Path to SSL certificate |
| `keycloak_ssl_certificate_key_path` | `/etc/nginx/ssl/keycloak.key` | Path to SSL private key |
| `nginx_keepalive_connections` | `32` | Upstream keepalive connections |
| `nginx_proxy_connect_timeout` | `60s` | Proxy connect timeout |
| `nginx_proxy_send_timeout` | `60s` | Proxy send timeout |
| `nginx_proxy_read_timeout` | `60s` | Proxy read timeout |
| `ssl_protocols` | `TLSv1.2 TLSv1.3` | Allowed SSL/TLS protocols |
| `backup_old_configs` | `true` | Backup existing configs before removal |

### Advanced Variables

```yaml
# Security headers (list of strings)
nginx_security_headers:
  - "Strict-Transport-Security \"max-age=63072000\" always"
  - "X-Frame-Options \"SAMEORIGIN\" always"
  - "X-Content-Type-Options \"nosniff\" always"

# Conflicting configuration files to clean up
conflicting_configs:
  - /etc/nginx/conf.d/dynamic-backends.conf
  - /etc/nginx/conf.d/keycloak.conf
  - /etc/nginx/conf.d/keycloak-redirect.conf
  - /etc/nginx/conf.d/freeipa.conf
  - /etc/nginx/conf.d/jenkins.conf
  - /etc/nginx/conf.d/sonarqube.conf
```

## Dependencies

None.

## Example Playbook

### Basic Usage with Self-Signed Certificates

```yaml
---
- hosts: nginx_servers
  become: yes
  vars:
    keycloak_server_name: keycloak.local
    keycloak_backend_host: 192.168.201.12
    keycloak_backend_port: 8080
  roles:
    - nginx-keycloak-proxy
```

### Using Custom SSL Certificates

```yaml
---
- hosts: nginx_servers
  become: yes
  vars:
    keycloak_server_name: keycloak.example.com
    keycloak_backend_host: 192.168.201.12
    keycloak_backend_port: 8080
    keycloak_ssl_certificate_path: /etc/ssl/certs/keycloak.crt
    keycloak_ssl_certificate_key_path: /etc/ssl/private/keycloak.key
  roles:
    - nginx-keycloak-proxy
```

### Performance Tuning Example

```yaml
---
- hosts: nginx_servers
  become: yes
  vars:
    keycloak_server_name: keycloak.local
    keycloak_backend_host: 192.168.201.12
    keycloak_backend_port: 8080
    nginx_keepalive_connections: 64
    nginx_proxy_connect_timeout: 30s
    nginx_proxy_send_timeout: 30s
    nginx_proxy_read_timeout: 30s
  roles:
    - nginx-keycloak-proxy
```

## Generated Files

The role creates the following configuration files:

- `/etc/nginx/conf.d/keycloak-https.conf` - Main HTTPS reverse proxy configuration
- `/etc/nginx/conf.d/keycloak-http-redirect.conf` - HTTP to HTTPS redirect
- `/etc/nginx/ssl/keycloak.crt` - SSL certificate (if auto-generated)
- `/etc/nginx/ssl/keycloak.key` - SSL private key (if auto-generated)

## Features in Detail

### SSL Configuration

The role supports both self-signed and custom SSL certificates:

- **Self-signed (default)**: Automatically generated with the server name as CN
- **Custom certificates**: Specify paths with `keycloak_ssl_certificate_path` and `keycloak_ssl_certificate_key_path`

### Security Features

- Modern TLS protocols (TLSv1.2, TLSv1.3)
- Strong cipher suites
- Security headers (HSTS, X-Frame-Options, etc.)
- Secure certificate file permissions (0600)

### Cleanup and Compatibility

The role automatically:
- Backs up existing conflicting configurations
- Removes old configurations to prevent conflicts
- Tests nginx configuration before applying changes

### Health Monitoring

Provides a health check endpoint at `/health` that returns a simple "healthy" response for monitoring purposes.

## Tags

The role supports the following tags for selective execution:

- `nginx` - All nginx-related tasks
- `install` - Package installation
- `ssl` - SSL certificate tasks
- `config` - Configuration deployment
- `cleanup` - Configuration cleanup
- `test` - Configuration testing
- `service` - Service management

Example usage:
```bash
ansible-playbook -i inventory playbook.yml --tags ssl,config
```

## Testing

### Manual Testing

1. Deploy the role:
   ```bash
   ansible-playbook -i inventory setup-nginx-keycloak-proxy.yml
   ```

2. Test HTTPS access:
   ```bash
   curl -k https://keycloak.local/
   ```

3. Verify redirect:
   ```bash
   curl -I http://keycloak.local/
   ```

4. Check health endpoint:
   ```bash
   curl -k https://keycloak.local/health
   ```

### Troubleshooting

**Nginx configuration test fails:**
```bash
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

**Certificate issues:**
```bash
openssl x509 -in /etc/nginx/ssl/keycloak.crt -text -noout
```

**Backend connectivity:**
```bash
curl http://192.168.201.12:8080/health/ready
```

## License

MIT

## Author Information

Created for Jenkins-SonarQube-Keycloak integration automation.
