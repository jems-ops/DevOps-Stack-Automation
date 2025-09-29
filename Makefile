# Jenkins Ansible Automation Makefile
.PHONY: help install-jenkins setup-nginx-proxy install-ssl-cert test-connection deploy-all clean

# Colors
CYAN := \\033[36m
GREEN := \\033[32m
YELLOW := \\033[33m
RED := \\033[31m
RESET := \\033[0m

# Default target
.DEFAULT_GOAL := help
SHELL := /bin/bash
VAULT_SCRIPT := ./scripts/vault-manager.sh
help: ## Show available commands
	@echo "$(CYAN)Jenkins Ansible Automation - Available Commands$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(CYAN)%-25s$(RESET) %s\\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ Testing and Connectivity
test-connection: ## Test connection to all servers
	@echo "$(CYAN)🔗 Testing connection to Jenkins and Nginx servers...$(RESET)"
	@ansible -i inventory all -m ping

test-jenkins-connection: ## Test connection to Jenkins server only
	@echo "$(CYAN)🔗 Testing connection to Jenkins server (192.168.201.14)...$(RESET)"
	@ansible -i inventory jenkins -m ping

test-nginx-connection: ## Test connection to Nginx server only
	@echo "$(CYAN)🔗 Testing connection to Nginx server (192.168.201.15)...$(RESET)"
	@ansible -i inventory nginx -m ping

test-sonarqube-connection: ## Test connection to SonarQube server only
	@echo "$(CYAN)🔗 Testing connection to SonarQube server (192.168.201.16)...$(RESET)"
	@ansible -i inventory sonarqube -m ping

##@ Jenkins Installation
install-jenkins: ## Install Jenkins on Jenkins server (192.168.201.14)
	@echo "$(CYAN)🚀 Installing Jenkins on Jenkins server...$(RESET)"
	@ansible-playbook playbooks/install-jenkins.yml
	@echo "$(GREEN)✅ Jenkins installation completed!$(RESET)"

##@ SonarQube Installation
install-sonarqube: ## Install SonarQube on SonarQube server (192.168.201.16)
	@echo "$(CYAN)🔍 Installing SonarQube on SonarQube server...$(RESET)"
	@ansible-playbook playbooks/install-sonarqube.yml
	@echo "$(GREEN)✅ SonarQube installation completed!$(RESET)"

##@ Nginx Reverse Proxy Setup
setup-nginx-proxy: ## Setup Nginx reverse proxy for Jenkins on Nginx server (192.168.201.15)
	@echo "$(CYAN)🌐 Setting up Nginx reverse proxy for Jenkins...$(RESET)"
	@ansible-playbook playbooks/setup-nginx-reverse-proxy.yml
	@echo "$(GREEN)✅ Nginx reverse proxy setup completed!$(RESET)"

setup-sonarqube-proxy: ## Setup Nginx reverse proxy for SonarQube on Nginx server (192.168.201.15)
	@echo "$(CYAN)🌐 Setting up Nginx reverse proxy for SonarQube...$(RESET)"
	@ansible-playbook playbooks/setup-sonarqube-nginx-proxy.yml
	@echo "$(GREEN)✅ SonarQube reverse proxy setup completed!$(RESET)"

##@ SSL Certificate Installation
install-ssl-cert: ## Install SSL certificate on Nginx server (192.168.201.15)
	@echo "$(CYAN)🔒 Installing SSL certificate...$(RESET)"
	@ansible-playbook playbooks/install-ssl-cert.yml
	@echo "$(GREEN)✅ SSL certificate installation completed!$(RESET)"

##@ Complete Deployment
deploy-all: ## Deploy complete Jenkins + Nginx + SSL setup
	@echo "$(CYAN)🚀 Starting complete Jenkins automation deployment...$(RESET)"
	@echo "$(YELLOW)Step 1/3: Installing Jenkins...$(RESET)"
	@$(MAKE) install-jenkins
	@echo "$(YELLOW)Step 2/3: Setting up Nginx reverse proxy...$(RESET)"
	@$(MAKE) setup-nginx-proxy
	@echo "$(YELLOW)Step 3/3: Installing SSL certificate...$(RESET)"
	@$(MAKE) install-ssl-cert
	@echo "$(GREEN)✅ Complete deployment finished!$(RESET)"
	@echo ""
	@echo "$(GREEN)🎉 Jenkins is now accessible via HTTPS reverse proxy!$(RESET)"
	@echo "$(GREEN)📍 Access URLs:$(RESET)"
	@echo "  • Jenkins direct: http://192.168.201.14:8080"
	@echo "  • Via Nginx proxy: https://192.168.201.15"
	@echo "  • Domain: https://jenkins.example.com (configure DNS)"

deploy-basic: ## Deploy Jenkins + HTTP reverse proxy (no SSL)
	@echo "$(CYAN)🚀 Starting basic Jenkins deployment (HTTP only)...$(RESET)"
	@echo "$(YELLOW)Step 1/2: Installing Jenkins...$(RESET)"
	@$(MAKE) install-jenkins
	@echo "$(YELLOW)Step 2/2: Setting up Nginx reverse proxy...$(RESET)"
	@$(MAKE) setup-nginx-proxy
	@echo "$(GREEN)✅ Basic deployment finished!$(RESET)"
	@echo ""
	@echo "$(GREEN)🎉 Jenkins is now accessible via HTTP reverse proxy!$(RESET)"
	@echo "$(GREEN)📍 Access URLs:$(RESET)"
	@echo "  • Jenkins direct: http://192.168.201.14:8080"
	@echo "  • Via Nginx proxy: http://192.168.201.15"

deploy-sonarqube-basic: ## Deploy SonarQube + HTTP reverse proxy (no SSL)
	@echo "$(CYAN)🔍 Starting basic SonarQube deployment (HTTP only)...$(RESET)"
	@echo "$(YELLOW)Step 1/2: Installing SonarQube...$(RESET)"
	@$(MAKE) install-sonarqube
	@echo "$(YELLOW)Step 2/2: Setting up Nginx reverse proxy...$(RESET)"
	@$(MAKE) setup-sonarqube-proxy
	@echo "$(GREEN)✅ Basic SonarQube deployment finished!$(RESET)"
	@echo ""
	@echo "$(GREEN)🎉 SonarQube is now accessible via HTTP reverse proxy!$(RESET)"
	@echo "$(GREEN)📍 Access URLs:$(RESET)"
	@echo "  • SonarQube direct: http://192.168.201.16:9000"
	@echo "  • Via Nginx proxy: http://192.168.201.15"

deploy-all-services: ## Deploy both Jenkins and SonarQube with proxies
	@echo "$(CYAN)🚀 Starting complete multi-service deployment...$(RESET)"
	@echo "$(YELLOW)Step 1/4: Installing Jenkins...$(RESET)"
	@$(MAKE) install-jenkins
	@echo "$(YELLOW)Step 2/4: Installing SonarQube...$(RESET)"
	@$(MAKE) install-sonarqube
	@echo "$(YELLOW)Step 3/4: Setting up Jenkins proxy...$(RESET)"
	@$(MAKE) setup-nginx-proxy
	@echo "$(YELLOW)Step 4/4: Installing SSL certificate...$(RESET)"
	@$(MAKE) install-ssl-cert
	@echo "$(GREEN)✅ Complete multi-service deployment finished!$(RESET)"
	@echo ""
	@echo "$(GREEN)🎉 Both Jenkins and SonarQube are deployed!$(RESET)"
	@echo "$(GREEN)📍 Access URLs:$(RESET)"
	@echo "  • Jenkins: https://192.168.201.15 (SSL)"
	@echo "  • SonarQube: http://192.168.201.16:9000 (direct)"
	@echo "  • Note: Switch nginx proxy between services as needed"

##@ Validation and Testing
validate-deployment: ## Validate the complete deployment
	@echo "$(CYAN)🔍 Validating deployment...$(RESET)"
	@echo "Testing Jenkins server..."
	@curl -s -o /dev/null -w "Jenkins (direct): %{http_code}\\n" http://192.168.201.14:8080 || echo "Jenkins: ERROR"
	@echo "Testing Nginx proxy..."
	@curl -s -o /dev/null -w "Nginx proxy (HTTP): %{http_code}\\n" http://192.168.201.15 || echo "Nginx HTTP: ERROR"
	@curl -s -k -o /dev/null -w "Nginx proxy (HTTPS): %{http_code}\\n" https://192.168.201.15 || echo "Nginx HTTPS: ERROR (SSL may not be installed)"
	@echo "$(GREEN)✅ Validation completed!$(RESET)"

##@ Maintenance
restart-jenkins: ## Restart Jenkins service on Jenkins server
	@echo "$(CYAN)🔄 Restarting Jenkins service...$(RESET)"
	@ansible -i inventory jenkins -m systemd -a "name=jenkins state=restarted" -b

restart-nginx: ## Restart Nginx service on Nginx server
	@echo "$(CYAN)🔄 Restarting Nginx service...$(RESET)"
	@ansible -i inventory nginx -m systemd -a "name=nginx state=restarted" -b

##@ Information
show-info: ## Show deployment information
	@echo "$(CYAN)📋 Jenkins Ansible Automation Information$(RESET)"
	@echo ""
	@echo "$(YELLOW)Servers:$(RESET)"
	@echo "  • Jenkins Server: 192.168.201.14 (vagrant/vagrant)"
	@echo "  • Nginx Server:   192.168.201.15 (vagrant/vagrant)"
	@echo "  • SonarQube Server: 192.168.201.16 (vagrant/vagrant)"
	@echo ""
	@echo "$(YELLOW)Roles:$(RESET)"
	@echo "  • install-jenkins: Install Jenkins on Rocky Linux 9"
	@echo "  • setup-nginx-reverse-proxy: Configure Nginx reverse proxy"
	@echo "  • install-ssl-cert: Generate self-signed SSL certificates"
	@echo ""
	@echo "$(YELLOW)Deployment Workflow:$(RESET)"
	@echo "  1. make install-jenkins    → Install Jenkins on 192.168.201.14"
	@echo "  2. make setup-nginx-proxy  → Configure proxy on 192.168.201.15"
	@echo "  3. make install-ssl-cert   → Add SSL certificate"
	@echo "  4. make validate-deployment → Test the setup"
	@echo ""
	@echo "$(YELLOW)Quick Start:$(RESET)"
	@echo "  make deploy-all    → Complete deployment with SSL"
	@echo "  make deploy-basic  → HTTP-only deployment"

##@ Testing with Molecule
install-molecule: ## Install Molecule and testing dependencies
	@echo "$(CYAN)📦 Installing Molecule and testing dependencies...$(RESET)"
	@pip install -r requirements.txt
	@echo "$(GREEN)✅ Molecule installation completed!$(RESET)"

test-jenkins-role: ## Test install-jenkins role with Molecule
	@echo "$(CYAN)🧪 Testing install-jenkins role...$(RESET)"
	@cd roles/install-jenkins && molecule test
	@echo "$(GREEN)✅ Jenkins role test completed!$(RESET)"

test-nginx-role: ## Test setup-nginx-reverse-proxy role with Molecule
	@echo "$(CYAN)🧪 Testing setup-nginx-reverse-proxy role...$(RESET)"
	@cd roles/setup-nginx-reverse-proxy && molecule test
	@echo "$(GREEN)✅ Nginx proxy role test completed!$(RESET)"

test-ssl-role: ## Test install-ssl-cert role with Molecule
	@echo "$(CYAN)🧪 Testing install-ssl-cert role...$(RESET)"
	@cd roles/install-ssl-cert && molecule test
	@echo "$(GREEN)✅ SSL certificate role test completed!$(RESET)"

test-sonarqube-role: ## Test install-sonarqube role with Molecule
	@echo "$(CYAN)🧪 Testing install-sonarqube role...$(RESET)"
	@cd roles/install-sonarqube && molecule test
	@echo "$(GREEN)✅ SonarQube role test completed!$(RESET)"

test-integration: ## Run integration tests for complete workflow
	@echo "$(CYAN)🧪 Running integration tests...$(RESET)"
	@cd molecule/integration && molecule test
	@echo "$(GREEN)✅ Integration tests completed!$(RESET)"

test-all-roles: ## Test all individual roles
	@echo "$(CYAN)🧪 Testing all roles...$(RESET)"
	@$(MAKE) test-jenkins-role
	@$(MAKE) test-sonarqube-role
	@$(MAKE) test-nginx-role
	@$(MAKE) test-ssl-role
	@echo "$(GREEN)✅ All role tests completed!$(RESET)"

test-molecule-full: ## Run all Molecule tests including integration
	@echo "$(CYAN)🧪 Running complete Molecule test suite...$(RESET)"
	@$(MAKE) test-all-roles
	@$(MAKE) test-integration
	@echo "$(GREEN)🎉 Complete Molecule test suite passed!$(RESET)"

# Quick test commands
test-syntax: ## Test playbook syntax only
	@echo "$(CYAN)📝 Testing playbook syntax...$(RESET)"
	@ansible-playbook playbooks/install-jenkins.yml --syntax-check
	@ansible-playbook playbooks/install-sonarqube.yml --syntax-check
	@ansible-playbook playbooks/setup-nginx-reverse-proxy.yml --syntax-check
	@ansible-playbook playbooks/setup-sonarqube-nginx-proxy.yml --syntax-check
	@ansible-playbook playbooks/install-ssl-cert.yml --syntax-check
	@echo "$(GREEN)✅ Syntax check completed!$(RESET)"

test-lint: ## Run ansible-lint on all playbooks and roles
	@echo "$(CYAN)🔍 Running ansible-lint...$(RESET)"
	@command -v ansible-lint >/dev/null 2>&1 || { echo "Installing ansible-lint..."; pip install ansible-lint; }
	@ansible-lint playbooks/
	@ansible-lint roles/
	@echo "$(GREEN)✅ Linting completed!$(RESET)"

##@ Cleanup
clean: ## Remove temporary files and reset
	@echo "$(CYAN)🧹 Cleaning up temporary files...$(RESET)"
	@rm -f *.retry
	@rm -f ansible.log
	@rm -rf __pycache__
	@echo "$(GREEN)✅ Cleanup completed!$(RESET)"

clean-molecule: ## Clean up Molecule test containers and images
	@echo "$(CYAN)🧹 Cleaning up Molecule containers...$(RESET)"
	@cd roles/install-jenkins && molecule destroy || true
	@cd roles/setup-nginx-reverse-proxy && molecule destroy || true
	@cd roles/install-ssl-cert && molecule destroy || true
	@cd molecule/integration && molecule destroy || true
	@docker system prune -f || true
	@echo "$(GREEN)✅ Molecule cleanup completed!$(RESET)"

##@ Vault Management
vault-status: ## Show vault status and file information
	@echo "$(CYAN)🔐 Checking vault status...$(RESET)"
	@$(VAULT_SCRIPT) status

vault-edit: ## Edit the encrypted vault file
	@echo "$(CYAN)🔐 Opening vault for editing...$(RESET)"
	@$(VAULT_SCRIPT) edit

vault-view: ## View the decrypted vault file contents
	@echo "$(CYAN)🔐 Viewing vault contents...$(RESET)"
	@$(VAULT_SCRIPT) view

vault-encrypt: ## Encrypt the vault file
	@echo "$(CYAN)🔐 Encrypting vault file...$(RESET)"
	@$(VAULT_SCRIPT) encrypt

vault-decrypt: ## Decrypt the vault file (use with caution)
	@echo "$(YELLOW)⚠️  Decrypting vault file...$(RESET)"
	@$(VAULT_SCRIPT) decrypt

vault-rekey: ## Change the vault password
	@echo "$(CYAN)🔐 Changing vault password...$(RESET)"
	@$(VAULT_SCRIPT) rekey
