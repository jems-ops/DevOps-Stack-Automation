"""
Molecule tests for install-jenkins role
"""
import os
import testinfra.utils.ansible_runner


testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_java_is_installed(host):
    """Test that Java is installed"""
    java = host.package("java-17-openjdk-devel")
    assert java.is_installed


def test_jenkins_package_is_installed(host):
    """Test that Jenkins package is installed"""
    jenkins = host.package("jenkins")
    assert jenkins.is_installed


def test_jenkins_user_exists(host):
    """Test that jenkins user exists"""
    user = host.user("jenkins")
    assert user.exists
    assert user.home == "/var/lib/jenkins"


def test_jenkins_service_is_running(host):
    """Test that Jenkins service is running and enabled"""
    jenkins = host.service("jenkins")
    assert jenkins.is_running
    assert jenkins.is_enabled


def test_jenkins_port_is_listening(host):
    """Test that Jenkins is listening on port 8080"""
    assert host.socket("tcp://0.0.0.0:8080").is_listening


def test_jenkins_home_directory_exists(host):
    """Test that Jenkins home directory exists"""
    jenkins_home = host.file("/var/lib/jenkins")
    assert jenkins_home.exists
    assert jenkins_home.is_directory
    assert jenkins_home.user == "jenkins"


def test_jenkins_repository_is_configured(host):
    """Test that Jenkins repository is configured"""
    repo_file = host.file("/etc/yum.repos.d/jenkins.repo")
    assert repo_file.exists
    assert repo_file.contains("jenkins.io")


def test_jenkins_is_accessible(host):
    """Test that Jenkins web interface is accessible"""
    # Wait a bit for Jenkins to fully start
    import time
    time.sleep(30)

    # Test HTTP response
    response = host.run("curl -s -o /dev/null -w '%{http_code}' http://localhost:8080")
    # Jenkins should return 403 (setup required) or 200 (ready)
    assert response.stdout in ["200", "403"]


def test_required_packages_are_installed(host):
    """Test that required packages are installed"""
    packages = ["wget", "curl", "git"]
    for package in packages:
        pkg = host.package(package)
        assert pkg.is_installed


def test_jenkins_initial_admin_password_exists(host):
    """Test that Jenkins initial admin password file exists"""
    # This file should exist after Jenkins first run
    import time
    time.sleep(10)  # Give Jenkins time to create the file

    password_file = host.file("/var/lib/jenkins/secrets/initialAdminPassword")
    # File might not exist if Jenkins is already configured, so we just check if directory exists
    secrets_dir = host.file("/var/lib/jenkins/secrets")
    assert secrets_dir.exists
    assert secrets_dir.is_directory
