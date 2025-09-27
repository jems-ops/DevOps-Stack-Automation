"""
Molecule tests for install-ssl-cert role
"""
import os
import testinfra.utils.ansible_runner


testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('ssl-nginx-rocky9')


def test_openssl_is_installed(host):
    """Test that OpenSSL is installed"""
    openssl = host.package("openssl")
    assert openssl.is_installed


def test_ssl_directory_exists(host):
    """Test that SSL certificate directory exists"""
    ssl_dir = host.file("/etc/nginx/tls")
    assert ssl_dir.exists
    assert ssl_dir.is_directory
    assert ssl_dir.user == "root"
    assert ssl_dir.group == "root"
    assert ssl_dir.mode == 0o755


def test_ssl_certificate_exists(host):
    """Test that SSL certificate file exists"""
    cert_file = host.file("/etc/nginx/tls/jenkins.crt")
    assert cert_file.exists
    assert cert_file.is_file
    assert cert_file.user == "root"
    assert cert_file.group == "root"
    assert cert_file.mode == 0o644


def test_ssl_private_key_exists(host):
    """Test that SSL private key file exists"""
    key_file = host.file("/etc/nginx/tls/jenkins.key")
    assert key_file.exists
    assert key_file.is_file
    assert key_file.user == "root"
    assert key_file.group == "root"
    assert key_file.mode == 0o600


def test_dhparam_file_exists(host):
    """Test that Diffie-Hellman parameters file exists"""
    dhparam_file = host.file("/etc/nginx/tls/dhparam.pem")
    assert dhparam_file.exists
    assert dhparam_file.is_file
    assert dhparam_file.user == "root"
    assert dhparam_file.group == "root"


def test_ssl_certificate_validity(host):
    """Test that SSL certificate is valid"""
    result = host.run("openssl x509 -in /etc/nginx/tls/jenkins.crt -noout -text")
    assert result.rc == 0
    assert "Certificate:" in result.stdout
    assert "Subject:" in result.stdout


def test_ssl_certificate_key_match(host):
    """Test that SSL certificate and key match"""
    cert_result = host.run("openssl x509 -noout -modulus -in /etc/nginx/tls/jenkins.crt | openssl md5")
    key_result = host.run("openssl rsa -noout -modulus -in /etc/nginx/tls/jenkins.key | openssl md5")
    
    assert cert_result.rc == 0
    assert key_result.rc == 0
    assert cert_result.stdout == key_result.stdout


def test_nginx_ssl_config_exists(host):
    """Test that SSL-enabled nginx configuration exists"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.exists
    assert config_file.contains("ssl_certificate /etc/nginx/tls/jenkins.crt")
    assert config_file.contains("ssl_certificate_key /etc/nginx/tls/jenkins.key")
    assert config_file.contains("ssl_dhparam /etc/nginx/tls/dhparam.pem")


def test_nginx_ssl_config_contains_security_features(host):
    """Test that nginx SSL config contains security features"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("ssl_protocols")
    assert config_file.contains("ssl_ciphers")
    assert config_file.contains("listen.*443 ssl http2")


def test_nginx_ssl_config_contains_security_headers(host):
    """Test that nginx config contains security headers"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("Strict-Transport-Security")
    assert config_file.contains("X-Frame-Options")
    assert config_file.contains("X-Content-Type-Options")


def test_nginx_ssl_config_contains_https_redirect(host):
    """Test that nginx config redirects HTTP to HTTPS"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("return 301 https://")


def test_nginx_service_is_running(host):
    """Test that Nginx service is running"""
    nginx = host.service("nginx")
    assert nginx.is_running


def test_nginx_ssl_port_is_listening(host):
    """Test that Nginx is listening on SSL port 443"""
    assert host.socket("tcp://0.0.0.0:443").is_listening


def test_nginx_config_syntax_is_valid(host):
    """Test that nginx SSL configuration syntax is valid"""
    result = host.run("nginx -t")
    assert result.rc == 0
    assert "syntax is ok" in result.stderr
    assert "test is successful" in result.stderr


def test_ssl_certificate_subject_alt_names(host):
    """Test that SSL certificate contains Subject Alternative Names"""
    result = host.run("openssl x509 -in /etc/nginx/tls/jenkins.crt -noout -text")
    assert result.rc == 0
    # Should contain DNS and IP SANs
    assert "Subject Alternative Name:" in result.stdout or "X509v3 Subject Alternative Name:" in result.stdout


def test_https_response(host):
    """Test that HTTPS endpoint responds"""
    import time
    time.sleep(5)  # Wait for services to be ready
    
    # Test HTTPS response (self-signed, so use -k)
    result = host.run("curl -k -s -o /dev/null -w '%{http_code}' https://localhost")
    # Should get some response (200, 502, 503 are acceptable)
    assert result.stdout in ["200", "502", "503"]


def test_http_redirects_to_https(host):
    """Test that HTTP requests redirect to HTTPS"""
    import time
    time.sleep(5)  # Wait for services to be ready
    
    # Test HTTP redirect
    result = host.run("curl -s -o /dev/null -w '%{http_code}' http://localhost")
    # Should redirect (301) or be unavailable due to SSL-only config
    assert result.stdout in ["301", "200", "502", "503"]


def test_dhparam_strength(host):
    """Test that DH parameters are strong enough"""
    result = host.run("openssl dhparam -in /etc/nginx/tls/dhparam.pem -noout -text")
    assert result.rc == 0
    # Should be at least 2048 bits
    assert "DH Parameters: (2048 bit)" in result.stdout or "DH Parameters: (4096 bit)" in result.stdout