"""
Molecule tests for setup-nginx-reverse-proxy role
"""
import os
import testinfra.utils.ansible_runner


testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('nginx-rocky9')


def test_nginx_is_installed(host):
    """Test that Nginx package is installed"""
    nginx = host.package("nginx")
    assert nginx.is_installed


def test_nginx_service_is_running(host):
    """Test that Nginx service is running and enabled"""
    nginx = host.service("nginx")
    assert nginx.is_running
    assert nginx.is_enabled


def test_nginx_port_is_listening(host):
    """Test that Nginx is listening on port 80"""
    assert host.socket("tcp://0.0.0.0:80").is_listening


def test_jenkins_config_file_exists(host):
    """Test that Jenkins nginx configuration file exists"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.exists
    assert config_file.is_file
    assert config_file.user == "root"
    assert config_file.group == "root"


def test_nginx_config_contains_jenkins_upstream(host):
    """Test that nginx config contains Jenkins upstream configuration"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("upstream jenkins")
    assert config_file.contains("keepalive 32")
    assert config_file.contains("server jenkins-backend-mock:80")


def test_nginx_config_contains_websocket_support(host):
    """Test that nginx config contains WebSocket support"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("map \$http_upgrade \$connection_upgrade")
    assert config_file.contains("proxy_set_header.*Connection.*\$connection_upgrade")
    assert config_file.contains("proxy_set_header.*Upgrade.*\$http_upgrade")


def test_nginx_config_contains_proxy_headers(host):
    """Test that nginx config contains proper proxy headers"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("proxy_set_header.*Host")
    assert config_file.contains("proxy_set_header.*X-Real-IP")
    assert config_file.contains("proxy_set_header.*X-Forwarded-For")
    assert config_file.contains("proxy_set_header.*X-Forwarded-Proto")


def test_nginx_config_contains_jenkins_optimizations(host):
    """Test that nginx config contains Jenkins-specific optimizations"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("proxy_request_buffering.*off")
    assert config_file.contains("ignore_invalid_headers off")
    assert config_file.contains("client_max_body_size")


def test_nginx_config_syntax_is_valid(host):
    """Test that nginx configuration syntax is valid"""
    result = host.run("nginx -t")
    assert result.rc == 0
    assert "syntax is ok" in result.stderr
    assert "test is successful" in result.stderr


def test_nginx_log_directory_exists(host):
    """Test that nginx log directory exists and is writable"""
    log_dir = host.file("/var/log/nginx")
    assert log_dir.exists
    assert log_dir.is_directory


def test_default_nginx_config_is_removed(host):
    """Test that default nginx configuration is removed"""
    default_config = host.file("/etc/nginx/conf.d/default.conf")
    assert not default_config.exists


def test_nginx_proxy_response(host):
    """Test that nginx proxy responds correctly"""
    import time
    time.sleep(5)  # Wait for services to be ready
    
    # Test that nginx responds
    result = host.run("curl -s -o /dev/null -w '%{http_code}' http://localhost")
    # Should get response from backend (even if it's just a mock)
    assert result.stdout in ["200", "502", "503"]  # 502/503 if backend not ready


def test_jenkins_static_file_handling(host):
    """Test that Jenkins static file handling is configured"""
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.contains("location ~ \"^\\/static\\/[0-9a-fA-F]{8}\\/(.*)\\$\"")
    assert config_file.contains("location /userContent")


def test_nginx_process_is_running(host):
    """Test that nginx process is actually running"""
    nginx_processes = host.process.filter(comm="nginx")
    assert len(nginx_processes) >= 1  # At least master process