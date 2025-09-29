# Jenkins Ansible Automation

A complete Ansible automation project for deploying Jenkins with Nginx reverse proxy and SSL certificates on Rocky Linux 9.

## 🏗️ Project Structure

```
jenkins-ansible-automation/
├── inventory                    # Ansible inventory with server definitions
├── ansible.cfg                  # Ansible configuration
├── Makefile                    # Easy deployment commands
├── README.md                   # This file
│
├── roles/                      # Ansible roles
│   ├── install-jenkins/        # Jenkins installation role
│   ├── setup-nginx-reverse-proxy/  # Nginx reverse proxy role
│   └── install-ssl-cert/       # SSL certificate role
│
└── playbooks/                  # Individual playbooks
    ├── install-jenkins.yml
    ├── setup-nginx-reverse-proxy.yml
    └── install-ssl-cert.yml
```

## 🖥️ Server Configuration

| Server | IP Address | Role | OS | Credentials |
|--------|------------|------|----| ------------|
| Jenkins Server | 192.168.92.224 | Jenkins Backend | Rocky Linux 9 | vagrant/vagrant |
| Nginx Server | 192.168.92.225 | Reverse Proxy + SSL | Rocky Linux 9 | vagrant/vagrant |

## 🚀 Quick Start

### 1. Complete Deployment (Jenkins + Nginx + SSL)
```bash
make deploy-all
```

### 2. Basic Deployment (Jenkins + HTTP Proxy only)
```bash
make deploy-basic
```

### 3. Step-by-Step Deployment
```bash
# Test connectivity first
make test-connection

# Install Jenkins
make install-jenkins

# Setup Nginx reverse proxy
make setup-nginx-proxy

# Add SSL certificate
make install-ssl-cert

# Validate deployment
make validate-deployment
```

## 📋 Available Commands

Run `make help` to see all available commands:

```bash
make help
```

### Key Commands:
- `make deploy-all` - Complete deployment with SSL
- `make deploy-basic` - HTTP-only deployment
- `make test-connection` - Test server connectivity
- `make validate-deployment` - Validate the setup
- `make show-info` - Show project information

## 🔧 Roles Overview

### 1. install-jenkins
- **Target**: Jenkins server (192.168.92.224)
- **Purpose**: Install Jenkins with all dependencies
- **Features**:
  - Java 17 OpenJDK installation
  - Jenkins repository setup
  - Service configuration
  - Idempotent installation

### 2. setup-nginx-reverse-proxy
- **Target**: Nginx server (192.168.92.225)
- **Purpose**: Configure Nginx as reverse proxy for Jenkins
- **Features**:
  - Nginx installation
  - Jinja2 templated configuration
  - WebSocket support for Jenkins agents
  - Proper proxy headers
  - Static file optimization

### 3. install-ssl-cert
- **Target**: Nginx server (192.168.92.225)
- **Purpose**: Generate and configure SSL certificates
- **Features**:
  - Self-signed SSL certificate generation
  - Diffie-Hellman parameters
  - HTTPS configuration
  - HTTP to HTTPS redirect
  - Security headers

## 📄 Configuration Templates

### Nginx Configuration (HTTP)
The `setup-nginx-reverse-proxy` role uses your specified template:

```nginx
upstream jenkins {
  keepalive 32;
  server 192.168.92.224:8080;
}

map $http_upgrade $connection_upgrade {
  default upgrade;
  '' close;
}

server {
  listen 80;
  server_name jenkins.example.com;
  # ... complete Jenkins-specific configuration
}
```

### Nginx Configuration (HTTPS)
The `install-ssl-cert` role extends the configuration with SSL:

```nginx
# HTTP redirect to HTTPS
server {
  listen 80;
  return 301 https://$server_name$request_uri;
}

# HTTPS server with SSL
server {
  listen 443 ssl http2;
  ssl_certificate /etc/nginx/tls/jenkins.crt;
  ssl_certificate_key /etc/nginx/tls/jenkins.key;
  # ... complete SSL configuration
}
```

## 🌐 Access URLs

After deployment, Jenkins will be accessible via:

| Access Method | URL | Notes |
|---------------|-----|-------|
| Direct Jenkins | http://192.168.92.224:8080 | Direct access to Jenkins |
| HTTP Proxy | http://192.168.92.225 | Via Nginx proxy |
| HTTPS Proxy | https://192.168.92.225 | With SSL certificate |
| Domain | https://jenkins.example.com | Configure DNS/hosts |

## 🔒 Security Features

- **SSL/TLS**: TLS 1.2 and 1.3 support
- **Certificates**: Self-signed SSL certificates
- **Security Headers**: HSTS, X-Frame-Options, CSP
- **Ciphers**: Strong cipher suites only
- **Redirect**: Automatic HTTP → HTTPS redirect
- **Ansible Vault**: Encrypted sensitive data storage

## 🔐 Vault Management

This project uses Ansible Vault to securely store sensitive information like passwords, API keys, and certificates.

### Quick Vault Commands
```bash
# View vault status
make vault-status

# Edit encrypted vault file
make vault-edit

# View vault contents
make vault-view
```

### Vault Variables
Sensitive variables are encrypted in `group_vars/all/vault.yml`:
- SSH credentials (`vault_ansible_user`, `vault_ansible_password`)
- Database passwords (`vault_postgresql_db_password`)
- SSL certificate configuration (`vault_ssl_organization`, `vault_ssl_email`)
- Application passwords (`vault_jenkins_admin_password`)
- API tokens (`vault_github_api_token`)

For detailed vault usage, see [VAULT_USAGE.md](VAULT_USAGE.md).

## 🔍 Validation

Test your deployment:

```bash
# Validate complete setup
make validate-deployment

# Test specific components
curl -I http://192.168.92.224:8080    # Jenkins direct
curl -I http://192.168.92.225         # HTTP proxy
curl -k -I https://192.168.92.225     # HTTPS proxy
```

## 🧪 Molecule Testing

Comprehensive testing with Molecule and Docker:

### Quick Testing Commands
```bash
# Install testing dependencies
make install-molecule

# Test individual roles
make test-jenkins-role    # Test Jenkins installation
make test-nginx-role      # Test nginx reverse proxy
make test-ssl-role        # Test SSL certificates

# Test complete integration
make test-integration     # End-to-end workflow test

# Run all tests
make test-molecule-full   # Complete test suite
```

### What Gets Tested
- ✅ **Jenkins Role**: Installation, service, web interface, security
- ✅ **Nginx Role**: Proxy config, upstream, WebSocket, headers
- ✅ **SSL Role**: Certificate generation, HTTPS config, security
- ✅ **Integration**: End-to-end connectivity, complete workflow

### Test Benefits
- **Fast**: Docker containers, no VM overhead
- **Comprehensive**: Tests functionality, not just syntax
- **Reliable**: Real service behavior validation
- **Automated**: CI/CD ready

See [MOLECULE_TESTING.md](MOLECULE_TESTING.md) for detailed documentation.

## 🛠️ Customization

### Variables Override

Create group or host variables to customize deployment:

```yaml
# group_vars/all.yml
nginx_server_name: jenkins.company.com
ssl_common_name: jenkins.company.com
jenkins_backend_port: 8080
```

### Template Customization

Modify the Jinja2 templates in:
- `roles/setup-nginx-reverse-proxy/templates/jenkins.conf.j2`
- `roles/install-ssl-cert/templates/jenkins-ssl.conf.j2`

## 📊 Workflow

```
1. make install-jenkins
   └── Installs Jenkins on 192.168.92.224
       └── Java 17, Jenkins, service configuration

2. make setup-nginx-proxy
   └── Configures Nginx on 192.168.92.225
       └── Proxy to Jenkins, WebSocket support

3. make install-ssl-cert
   └── Adds SSL to Nginx
       └── Self-signed cert, HTTPS redirect
```

## 🎯 Expected Result

After running `make deploy-all`:
- ✅ Jenkins running on 192.168.92.224:8080
- ✅ Nginx reverse proxy on 192.168.92.225
- ✅ SSL certificate with HTTPS access
- ✅ HTTP automatically redirects to HTTPS
- ✅ WebSocket support for Jenkins agents
- ✅ All services enabled and running

## 🔧 Troubleshooting

### Connection Issues
```bash
make test-connection  # Test SSH connectivity
```

### Service Issues
```bash
make restart-jenkins  # Restart Jenkins
make restart-nginx    # Restart Nginx
```

### SSL Issues
```bash
# Check certificate
openssl x509 -in /etc/nginx/tls/jenkins.crt -text -noout

# Test SSL
curl -k -v https://192.168.92.225
```

## 📚 Requirements

- Ansible 2.9+
- Two Rocky Linux 9 servers
- SSH access with vagrant/vagrant credentials
- Python 3 on target servers

## 🎉 Success Criteria

Jenkins is successfully accessible via HTTPS reverse proxy when:
1. Jenkins web interface loads at https://192.168.92.225
2. WebSocket connections work (Jenkins agents can connect)
3. SSL certificate is valid (self-signed)
4. HTTP requests redirect to HTTPS
5. All services are running and enabled

---

**🚀 Ready to deploy? Run `make deploy-all` to get started!**