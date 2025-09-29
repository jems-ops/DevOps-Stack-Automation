# Contributing to Jenkins Ansible Automation

Thank you for your interest in contributing to the Jenkins Ansible Automation project! This document provides guidelines for contributing to this project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Issue Reporting](#issue-reporting)

## Getting Started

### Prerequisites

- Python 3.8+
- Ansible 2.9+
- Docker (for Molecule testing)
- Git

### Development Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd jenkins-ansible-automation
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Verify setup:**
   ```bash
   make help
   ```

## Testing

### Running Tests

- **Test all roles with Molecule:**
  ```bash
  make test-molecule-full
  ```

- **Test individual roles:**
  ```bash
  make test-jenkins-role
  make test-nginx-role
  make test-ssl-role
  make test-sonarqube-role
  ```

- **Run integration tests:**
  ```bash
  make test-integration
  ```

- **Syntax checking:**
  ```bash
  make test-syntax
  ```

- **Linting:**
  ```bash
  make test-lint
  ```

### Writing Tests

- All new roles should include Molecule tests
- Test files should be placed in `roles/<role-name>/molecule/default/test_*.py`
- Use TestInfra for infrastructure testing
- Follow existing test patterns and conventions

## Submitting Changes

### Branching Strategy

- `main` - Production ready code
- `develop` - Integration branch for features
- `feature/<feature-name>` - Feature development branches
- `bugfix/<bug-description>` - Bug fix branches

### Pull Request Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes and commit:**
   ```bash
   git add .
   git commit -m "feat: describe your changes"
   ```

3. **Run tests:**
   ```bash
   make test-syntax
   make test-molecule-full
   ```

4. **Push your branch:**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request**

### Commit Message Format

Use conventional commits format:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions or modifications
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

Example:
```
feat: add support for Jenkins plugin installation

- Add new variable jenkins_plugins for plugin management
- Update role to install plugins automatically
- Add tests for plugin installation verification
```

## Code Style

### Ansible Guidelines

- **YAML Style:**
  - Use 2 spaces for indentation
  - Use lowercase with underscores for variable names
  - Quote strings when necessary
  - Use `---` at the beginning of YAML files

- **Variable Naming:**
  - Use descriptive names: `jenkins_home_dir` not `home`
  - Prefix role variables with role name: `jenkins_port`, `nginx_server_name`
  - Use boolean variables: `jenkins_service_enabled: true`

- **Task Guidelines:**
  - Always name your tasks descriptively
  - Use handlers for service restarts and reloads
  - Include `changed_when` and `failed_when` when appropriate
  - Use `check_mode` compatible tasks where possible

### Example Task Format:
```yaml
- name: Install Jenkins package
  dnf:
    name: jenkins
    state: present
  notify: restart jenkins
  tags:
    - jenkins
    - install
```

### Directory Structure

```
roles/
├── role-name/
│   ├── defaults/
│   │   └── main.yml          # Default variables
│   ├── handlers/
│   │   └── main.yml          # Handlers
│   ├── meta/
│   │   └── main.yml          # Role metadata
│   ├── molecule/
│   │   └── default/          # Molecule tests
│   ├── tasks/
│   │   └── main.yml          # Main tasks
│   ├── templates/
│   │   └── *.j2              # Jinja2 templates
│   └── vars/
│       └── main.yml          # Role variables
```

## Issue Reporting

When reporting issues, please include:

1. **Environment information:**
   - OS version
   - Ansible version
   - Python version

2. **Reproduction steps:**
   - Clear steps to reproduce the issue
   - Expected vs actual behavior
   - Error messages and logs

3. **Configuration:**
   - Relevant variable values
   - Inventory configuration
   - Any custom modifications

### Issue Labels

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements to documentation
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed

## Development Guidelines

### Adding New Roles

1. Create role directory structure
2. Add role to playbooks
3. Create Molecule tests
4. Update documentation
5. Add Makefile targets if needed

### Modifying Existing Roles

1. Ensure backward compatibility
2. Update tests accordingly
3. Update documentation
4. Test thoroughly

### Security Considerations

- Never commit passwords, keys, or sensitive data
- Use Ansible Vault for secrets
- Follow security best practices
- Test with security scanning tools

## Getting Help

- Check existing issues and documentation
- Join project discussions
- Ask questions in pull request comments
- Contact maintainers for guidance

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain professional communication

Thank you for contributing to making Jenkins automation better! 🚀
