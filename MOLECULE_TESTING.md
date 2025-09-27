# Molecule Testing Documentation

This document describes the comprehensive Molecule testing framework for the Jenkins Ansible Automation project.

## 🧪 Overview

We use Molecule with Docker to test all roles and integration scenarios:

- **Unit Tests**: Individual role testing
- **Integration Tests**: End-to-end workflow testing
- **Docker-based**: No need for real VMs
- **Comprehensive**: Tests functionality, configuration, and connectivity

## 🏗️ Test Architecture

```
molecule/
├── integration/              # End-to-end integration tests
│   ├── molecule.yml         # 2-server setup (jenkins + nginx)
│   ├── converge.yml         # Complete workflow deployment  
│   ├── prepare.yml          # Container preparation
│   └── test_integration.py  # Integration test suite
│
roles/
├── install-jenkins/molecule/default/
│   ├── molecule.yml         # Jenkins server container
│   ├── converge.yml         # Jenkins installation
│   ├── prepare.yml          # System preparation
│   └── test_jenkins.py      # Jenkins functionality tests
│
├── setup-nginx-reverse-proxy/molecule/default/
│   ├── molecule.yml         # Nginx + mock backend
│   ├── converge.yml         # Proxy configuration
│   ├── prepare.yml          # System preparation
│   └── test_nginx_proxy.py  # Proxy functionality tests
│
└── install-ssl-cert/molecule/default/
    ├── molecule.yml         # Nginx container
    ├── converge.yml         # SSL certificate setup
    ├── prepare.yml          # System preparation
    └── test_ssl_cert.py     # SSL certificate tests
```

## 🚀 Quick Start

### 1. Install Dependencies
```bash
make install-molecule
```

### 2. Run Individual Role Tests
```bash
make test-jenkins-role    # Test Jenkins installation
make test-nginx-role      # Test nginx reverse proxy
make test-ssl-role        # Test SSL certificate generation
```

### 3. Run Integration Tests
```bash
make test-integration     # Test complete workflow
```

### 4. Run All Tests
```bash
make test-molecule-full   # Complete test suite
```

## 🧪 Test Scenarios

### Jenkins Role Tests (`test-jenkins-role`)

**Container**: Rocky Linux 9 with systemd  
**Tests**:
- ✅ Java 17 OpenJDK installation
- ✅ Jenkins package installation from official repository
- ✅ Jenkins service running and enabled
- ✅ Port 8080 listening
- ✅ Jenkins user and home directory
- ✅ Web interface accessibility
- ✅ Initial admin password generation

**Key Validations**:
```python
def test_jenkins_is_accessible(host):
    response = host.run("curl -s -o /dev/null -w '%{http_code}' http://localhost:8080")
    assert response.stdout in ["200", "403"]  # 403 = setup required
```

### Nginx Proxy Role Tests (`test-nginx-role`)

**Containers**: 
- Rocky Linux 9 (nginx server)
- Alpine nginx (mock Jenkins backend)

**Tests**:
- ✅ Nginx installation and service
- ✅ Jenkins configuration deployment
- ✅ Upstream configuration with keepalive
- ✅ WebSocket support for Jenkins agents
- ✅ Proper proxy headers
- ✅ Jenkins-specific optimizations
- ✅ Configuration syntax validation

**Key Validations**:
```python
def test_nginx_config_contains_jenkins_upstream(host):
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("upstream jenkins")
    assert config_file.contains("keepalive 32")
    assert config_file.contains("server jenkins-backend-mock:80")
```

### SSL Certificate Role Tests (`test-ssl-role`)

**Container**: Rocky Linux 9 with nginx  
**Tests**:
- ✅ Self-signed SSL certificate generation
- ✅ Private key security (600 permissions)
- ✅ Diffie-Hellman parameters
- ✅ Certificate-key pair validation
- ✅ HTTPS nginx configuration
- ✅ Security headers
- ✅ HTTP to HTTPS redirect

**Key Validations**:
```python
def test_ssl_certificate_key_match(host):
    cert_result = host.run("openssl x509 -noout -modulus -in /etc/nginx/tls/jenkins.crt | openssl md5")
    key_result = host.run("openssl rsa -noout -modulus -in /etc/nginx/tls/jenkins.key | openssl md5")
    assert cert_result.stdout == key_result.stdout
```

### Integration Tests (`test-integration`)

**Containers**:
- Jenkins Server (Rocky Linux 9)
- Nginx Proxy (Rocky Linux 9)
- Networked together

**Complete Workflow Tests**:
- ✅ Jenkins installation on backend server
- ✅ Nginx proxy configuration pointing to Jenkins
- ✅ SSL certificate generation and configuration
- ✅ End-to-end connectivity (nginx → jenkins)
- ✅ HTTPS proxy functionality
- ✅ WebSocket support verification
- ✅ Security headers validation
- ✅ Service restart resilience

**Key Validations**:
```python
def test_end_to_end_connectivity(host):
    # Test connectivity to Jenkins backend
    jenkins_result = host.run("curl -s -o /dev/null -w '%{http_code}' http://jenkins-server:8080")
    assert jenkins_result.stdout in ["200", "403"]
    
    # Test HTTPS proxy response
    https_result = host.run("curl -k -s -o /dev/null -w '%{http_code}' https://localhost")
    assert https_result.stdout in ["200", "403"]
```

## 📊 What Gets Tested

### ✅ Functionality Tests
- Service installation and configuration
- Port availability and listening
- Configuration file generation
- Service startup and enablement

### ✅ Security Tests
- SSL certificate generation and validation
- File permissions (certificates, keys)
- Security headers configuration
- HTTPS redirect functionality

### ✅ Integration Tests
- Inter-service communication
- Network connectivity
- End-to-end request flow
- WebSocket upgrade support

### ✅ Resilience Tests
- Service restart capability
- Configuration syntax validation
- Idempotency verification
- Error handling

## 🛠️ Available Commands

| Command | Description |
|---------|-------------|
| `make install-molecule` | Install Molecule and testing dependencies |
| `make test-jenkins-role` | Test Jenkins installation role |
| `make test-nginx-role` | Test nginx reverse proxy role |
| `make test-ssl-role` | Test SSL certificate role |
| `make test-integration` | Test complete workflow integration |
| `make test-all-roles` | Test all individual roles |
| `make test-molecule-full` | Run complete Molecule test suite |
| `make test-syntax` | Validate Ansible playbook syntax |
| `make test-lint` | Run ansible-lint on playbooks and roles |
| `make clean-molecule` | Clean up test containers and images |

## 🔍 Test Output

Each test provides detailed output:

```bash
$ make test-jenkins-role

🧪 Testing install-jenkins role...
PLAY [Converge] ********************************************************
TASK [install-jenkins : Display Jenkins installation information] ******
ok: [jenkins-rocky9]

TASK [install-jenkins : Install Java OpenJDK] *************************
changed: [jenkins-rocky9]

# ... (installation tasks)

PLAY [Verify] **********************************************************
TASK [Execute Testinfra tests] *****************************************
========================= test session starts =========================
test_jenkins.py::test_java_is_installed PASSED              [ 12%]
test_jenkins.py::test_jenkins_package_is_installed PASSED   [ 25%]
test_jenkins.py::test_jenkins_service_is_running PASSED     [ 37%]
test_jenkins.py::test_jenkins_port_is_listening PASSED      [ 50%]
test_jenkins.py::test_jenkins_is_accessible PASSED         [ 75%]
========================= 8 passed in 45.2s =========================

✅ Jenkins role test completed!
```

## 🐳 Container Requirements

- **Docker**: Required for running test containers
- **Python 3**: For Molecule and testing framework
- **Privileges**: Docker containers run with systemd privileges

## 📈 Benefits

1. **Fast Feedback**: Tests run in containers, no VM overhead
2. **Comprehensive**: Tests all aspects of functionality
3. **Consistent**: Same environment every test run
4. **Automated**: Integrates with CI/CD pipelines
5. **Reliable**: Tests actual service behavior, not just configuration

## 🚨 Troubleshooting

### Common Issues

1. **Docker Permission Issues**:
   ```bash
   sudo chmod 666 /var/run/docker.sock
   ```

2. **Container Cleanup**:
   ```bash
   make clean-molecule
   ```

3. **Molecule Installation Issues**:
   ```bash
   pip install --upgrade pip
   make install-molecule
   ```

## 📝 Test Development

To add new tests, modify the respective `test_*.py` files:

```python
def test_new_functionality(host):
    """Test description"""
    # Test implementation
    result = host.run("your_command")
    assert result.rc == 0
    assert "expected_output" in result.stdout
```

## 🎯 Success Criteria

All tests pass when:
- ✅ Jenkins installs and runs correctly
- ✅ Nginx proxy routes requests to Jenkins
- ✅ SSL certificates are generated and configured
- ✅ HTTPS redirection works
- ✅ WebSocket connections are supported
- ✅ Security headers are present
- ✅ Services survive restarts

---

**🧪 Ready to test? Run `make test-molecule-full` to execute the complete test suite!**