# Pre-commit Hooks Setup

This project uses [pre-commit](https://pre-commit.com/) to ensure code quality, security, and consistency before commits are made.

## What Pre-commit Checks

### 🔒 Security Checks
- **Vault file encryption**: Ensures all `vault.yml` files are encrypted
- **Vault password permissions**: Checks `.vault_pass` has secure 600 permissions
- **Large file detection**: Prevents accidentally committing large files (>500KB)

### 📝 Code Quality
- **YAML validation**: Ensures all YAML files are valid
- **JSON validation**: Ensures all JSON files are valid
- **Shell script linting**: Uses ShellCheck to catch shell script issues
- **Executable permissions**: Ensures executable files have proper shebangs

### 🎨 Formatting
- **Trailing whitespace**: Automatically removes trailing whitespace
- **End of file fixing**: Ensures files end with a newline
- **Mixed line endings**: Standardizes line endings
- **Merge conflicts**: Detects leftover merge conflict markers

## Installation

Pre-commit hooks are automatically configured for this project:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install the hooks for this repository
pre-commit install
```

## Usage

### Automatic Usage
Once installed, pre-commit hooks run automatically on every `git commit`:

```bash
git add .
git commit -m "Your commit message"
# Pre-commit hooks run automatically
```

### Manual Usage
You can also run hooks manually:

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run check-yaml --all-files
pre-commit run shellcheck --all-files
pre-commit run check-vault-encrypted --all-files

# Run hooks on specific files
pre-commit run --files path/to/file.yml
```

## Available Hooks

| Hook Name | Purpose | Auto-fix |
|-----------|---------|----------|
| `trailing-whitespace` | Remove trailing whitespace | ✅ |
| `end-of-file-fixer` | Ensure files end with newline | ✅ |
| `check-yaml` | Validate YAML syntax | ❌ |
| `check-json` | Validate JSON syntax | ❌ |
| `check-merge-conflict` | Detect merge conflicts | ❌ |
| `check-case-conflict` | Detect case conflicts | ❌ |
| `check-executables-have-shebangs` | Ensure executables have shebangs | ❌ |
| `check-shebang-scripts-are-executable` | Ensure scripts are executable | ❌ |
| `mixed-line-ending` | Standardize line endings | ❌ |
| `check-added-large-files` | Prevent large file commits | ❌ |
| `shellcheck` | Lint shell scripts | ❌ |
| `check-vault-encrypted` | Ensure vault files are encrypted | ❌ |
| `check-vault-permissions` | Check vault password permissions | ❌ |

## Vault-Specific Checks

### Vault File Encryption Check
Ensures all `vault.yml` files are properly encrypted with Ansible Vault:

```bash
# Manual check
./scripts/check-vault-encrypted.sh

# If a vault file is not encrypted, you'll see:
# ❌ ERROR: group_vars/all/vault.yml is not encrypted!
#    Run: ansible-vault encrypt group_vars/all/vault.yml
```

### Vault Password File Permissions
Ensures `.vault_pass` has secure permissions (600):

```bash
# Manual check
./scripts/check-vault-permissions.sh

# If permissions are wrong, you'll see:
# ❌ ERROR: .vault_pass should have 600 permissions!
#    Run: chmod 600 .vault_pass
```

## Common Issues and Solutions

### Hook Failed: Trailing Whitespace
**Issue**: Files have trailing whitespace
**Solution**: Pre-commit automatically fixes this. Just commit again.

### Hook Failed: End of File Fixer
**Issue**: Files don't end with a newline
**Solution**: Pre-commit automatically fixes this. Just commit again.

### Hook Failed: Check YAML
**Issue**: YAML syntax error
**Solution**: Fix the YAML syntax error in the indicated file.

### Hook Failed: ShellCheck
**Issue**: Shell script has style/syntax issues
**Solution**: Fix the issues reported by ShellCheck or ignore specific rules:

```bash
# To ignore a specific ShellCheck rule, add to the line:
# shellcheck disable=SC2181
```

### Hook Failed: Check Vault Encrypted
**Issue**: A vault file is not encrypted
**Solution**: Encrypt the vault file:

```bash
ansible-vault encrypt group_vars/all/vault.yml
# or use the Makefile
make vault-encrypt
```

### Hook Failed: Check Vault Permissions
**Issue**: Vault password file has wrong permissions
**Solution**: Fix permissions:

```bash
chmod 600 .vault_pass
```

## Skipping Hooks (Not Recommended)

In emergency situations, you can skip pre-commit hooks:

```bash
# Skip all hooks (NOT RECOMMENDED)
git commit --no-verify -m "Emergency commit"

# Skip specific hook
SKIP=check-yaml git commit -m "Skip YAML check"
```

**Warning**: Skipping hooks can introduce security vulnerabilities or code quality issues.

## Customizing Hooks

The pre-commit configuration is in `.pre-commit-config.yaml`. You can:

1. Add new hooks
2. Modify existing hook parameters
3. Update hook versions
4. Add file exclusions

After modifying the configuration:

```bash
# Update hook environments
pre-commit clean
pre-commit install
```

## CI/CD Integration

Pre-commit hooks also run in CI/CD pipelines to ensure code quality. If hooks fail locally, they will also fail in CI/CD.

## Files Excluded from Checks

The following files are automatically excluded:

- `.vault_pass` - Vault password file
- `group_vars/all/vault.yml` - Encrypted vault file (from YAML check)
- `.cache/`, `.pytest_cache/`, `__pycache__/` - Cache directories
- `.molecule/`, `molecule/*/.molecule/` - Molecule test artifacts
- `.secrets.baseline` - Secrets detection baseline

## Getting Help

```bash
# Show available hooks
pre-commit run --help

# Show hook-specific help
pre-commit run check-yaml --help

# Update hooks to latest versions
pre-commit autoupdate

# Run specific security checks
make vault-status
./scripts/check-vault-encrypted.sh
./scripts/check-vault-permissions.sh
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Install hooks | `pre-commit install` |
| Run all hooks | `pre-commit run --all-files` |
| Check YAML files | `pre-commit run check-yaml --all-files` |
| Check shell scripts | `pre-commit run shellcheck --all-files` |
| Check vault encryption | `./scripts/check-vault-encrypted.sh` |
| Check vault permissions | `./scripts/check-vault-permissions.sh` |
| Skip hooks (emergency) | `git commit --no-verify` |
| Update hook versions | `pre-commit autoupdate` |
