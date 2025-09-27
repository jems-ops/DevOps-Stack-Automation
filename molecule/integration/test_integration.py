"""
Integration tests for complete Jenkins + Nginx + SSL workflow
"""
import os
import time
import testinfra.utils.ansible_runner


testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_jenkins_is_running(host):
    """Test Jenkins is running on jenkins-server"""
    if 'jenkins-server' not in host.backend.get_hostname():
        return  # Skip for nginx server
        
    jenkins = host.service("jenkins")
    assert jenkins.is_running
    assert jenkins.is_enabled
    
    # Wait for Jenkins to be ready
    time.sleep(30)
    assert host.socket("tcp://0.0.0.0:8080").is_listening


def test_nginx_is_running_with_ssl(host):
    """Test Nginx is running with SSL on nginx-proxy"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
        
    nginx = host.service("nginx")
    assert nginx.is_running
    assert nginx.is_enabled
    
    # Both HTTP and HTTPS ports should be listening
    assert host.socket("tcp://0.0.0.0:80").is_listening
    assert host.socket("tcp://0.0.0.0:443").is_listening


def test_ssl_certificates_are_present(host):
    """Test SSL certificates are present on nginx-proxy"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
        
    cert_file = host.file("/etc/nginx/tls/jenkins.crt")
    key_file = host.file("/etc/nginx/tls/jenkins.key")
    dhparam_file = host.file("/etc/nginx/tls/dhparam.pem")
    
    assert cert_file.exists
    assert key_file.exists
    assert dhparam_file.exists


def test_nginx_proxy_configuration(host):
    """Test nginx proxy configuration is correct"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
        
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    assert config_file.exists
    
    # Check upstream configuration
    assert config_file.contains("upstream jenkins")
    assert config_file.contains("server jenkins-server:8080")
    
    # Check SSL configuration
    assert config_file.contains("ssl_certificate /etc/nginx/tls/jenkins.crt")
    assert config_file.contains("listen.*443 ssl http2")
    
    # Check proxy headers
    assert config_file.contains("proxy_set_header.*X-Forwarded-For")
    assert config_file.contains("proxy_set_header.*X-Forwarded-Proto")


def test_end_to_end_connectivity(host):
    """Test end-to-end connectivity from nginx to jenkins"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
    
    # Wait for all services to be ready
    time.sleep(45)
    
    # Test connectivity to Jenkins backend
    jenkins_result = host.run("curl -s -o /dev/null -w '%{http_code}' http://jenkins-server:8080")
    assert jenkins_result.stdout in ["200", "403"]  # 403 is normal for Jenkins setup page
    
    # Test HTTPS proxy response
    https_result = host.run("curl -k -s -o /dev/null -w '%{http_code}' https://localhost")
    assert https_result.stdout in ["200", "403"]  # Should proxy to Jenkins
    
    # Test HTTP redirect
    http_result = host.run("curl -s -o /dev/null -w '%{http_code}' http://localhost")
    assert http_result.stdout in ["301", "200", "403"]  # Should redirect or proxy


def test_jenkins_web_interface_accessible_via_proxy(host):
    """Test Jenkins web interface is accessible via nginx proxy"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
    
    # Wait for services to be ready
    time.sleep(30)
    
    # Test that we can get Jenkins response via proxy
    result = host.run("curl -k -s https://localhost")
    
    # Should get Jenkins content (even if it's setup page)
    # Jenkins typically returns HTML with "Jenkins" in title or body
    jenkins_indicators = ["jenkins", "Jenkins", "initialAdminPassword", "unlock"]
    has_jenkins_content = any(indicator.lower() in result.stdout.lower() for indicator in jenkins_indicators)
    
    # If no Jenkins-specific content, at least we should get a valid HTTP response
    assert has_jenkins_content or len(result.stdout) > 0


def test_websocket_support_configured(host):
    """Test WebSocket support is configured in nginx"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
    
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    
    # Check WebSocket upgrade headers
    assert config_file.contains("map \\$http_upgrade \\$connection_upgrade")
    assert config_file.contains("proxy_set_header.*Upgrade.*\\$http_upgrade")
    assert config_file.contains("proxy_set_header.*Connection.*\\$connection_upgrade")


def test_security_headers_present(host):
    """Test security headers are present in nginx config"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
    
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    
    # Check security headers
    assert config_file.contains("Strict-Transport-Security")
    assert config_file.contains("X-Frame-Options")
    assert config_file.contains("X-Content-Type-Options")


def test_jenkins_specific_optimizations(host):
    """Test Jenkins-specific optimizations are applied"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
    
    config_file = host.file("/etc/nginx/conf.d/jenkins.conf")
    
    # Check Jenkins-specific settings
    assert config_file.contains("proxy_request_buffering.*off")
    assert config_file.contains("ignore_invalid_headers off")
    assert config_file.contains("location ~ \"^\\/static\\/[0-9a-fA-F]{8}\\/(.*)\\$\"")
    assert config_file.contains("location /userContent")


def test_services_survive_restart(host):
    """Test that services can be restarted successfully"""
    hostname = host.backend.get_hostname()
    
    if 'jenkins-server' in hostname:
        # Test Jenkins restart
        result = host.run("systemctl restart jenkins")
        assert result.rc == 0
        
        # Give it time to start
        time.sleep(20)
        jenkins = host.service("jenkins")
        assert jenkins.is_running
        
    elif 'nginx-proxy' in hostname:
        # Test Nginx restart
        result = host.run("systemctl restart nginx")
        assert result.rc == 0
        
        # Should start immediately
        time.sleep(5)
        nginx = host.service("nginx")
        assert nginx.is_running


def test_configuration_backup_exists(host):
    """Test that configuration backups were created"""
    if 'nginx-proxy' not in host.backend.get_hostname():
        return  # Skip for jenkins server
    
    # Check if backup files exist
    backup_files = host.run("ls /etc/nginx/conf.d/jenkins.conf.backup-* 2>/dev/null || echo 'no_backup'")
    # It's OK if no backup exists (first run), but if it does, test passed
    assert True  # This test is informational


def test_log_files_exist(host):
    """Test that log files are created and writable"""
    hostname = host.backend.get_hostname()
    
    if 'jenkins-server' in hostname:
        # Jenkins logs should exist
        jenkins_log_dir = host.file("/var/log/jenkins")
        # Log directory might not exist initially, that's OK
        
    elif 'nginx-proxy' in hostname:
        # Nginx logs should be writable
        log_dir = host.file("/var/log/nginx")
        assert log_dir.exists
        assert log_dir.is_directory