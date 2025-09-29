#!/bin/bash
# Ansible Vault Management Script
# Provides easy-to-use commands for vault operations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VAULT_FILE="$PROJECT_DIR/group_vars/all/vault.yml"
VAULT_PASS_FILE="$PROJECT_DIR/.vault_pass"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if vault password file exists
check_vault_password() {
    if [[ ! -f "$VAULT_PASS_FILE" ]]; then
        print_error "Vault password file not found at $VAULT_PASS_FILE"
        exit 1
    fi
}

# Function to edit vault file
edit_vault() {
    print_info "Opening vault file for editing..."
    check_vault_password
    if ansible-vault edit "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE"; then
        print_success "Vault file edited successfully"
    else
        print_error "Failed to edit vault file"
    fi
}

# Function to view vault file
view_vault() {
    print_info "Viewing vault file contents..."
    check_vault_password
    ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE"
}

# Function to decrypt vault file
decrypt_vault() {
    print_warning "This will decrypt the vault file permanently!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        check_vault_password
        if ansible-vault decrypt "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE"; then
            print_success "Vault file decrypted"
        else
            print_error "Failed to decrypt vault file"
        fi
    else
        print_info "Operation cancelled"
    fi
}

# Function to encrypt vault file
encrypt_vault() {
    print_info "Encrypting vault file..."
    check_vault_password
    if ansible-vault encrypt "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE"; then
        print_success "Vault file encrypted"
    else
        print_error "Failed to encrypt vault file"
    fi
}

# Function to change vault password
change_password() {
    print_info "Changing vault password..."
    print_warning "This will require both old and new passwords"
    if ansible-vault rekey "$VAULT_FILE"; then
        print_success "Vault password changed"
        print_warning "Remember to update .vault_pass file if needed"
    else
        print_error "Failed to change vault password"
    fi
}

# Function to check vault status
status() {
    print_info "Vault Status:"
    echo
    echo "📁 Vault file: $VAULT_FILE"
    echo "🔐 Password file: $VAULT_PASS_FILE"
    echo

    if [[ -f "$VAULT_FILE" ]]; then
        if ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE" >/dev/null 2>&1; then
            print_success "Vault file exists and is accessible"
        else
            print_error "Vault file exists but cannot be decrypted"
        fi
    else
        print_error "Vault file not found"
    fi

    if [[ -f "$VAULT_PASS_FILE" ]]; then
        print_success "Vault password file exists"
        ls -la "$VAULT_PASS_FILE"
    else
        print_error "Vault password file not found"
    fi
}

# Function to show usage
usage() {
    echo "🔐 Ansible Vault Manager"
    echo
    echo "Usage: $0 {edit|view|encrypt|decrypt|rekey|status|help}"
    echo
    echo "Commands:"
    echo "  edit     - Edit the vault file (opens in editor)"
    echo "  view     - View the vault file contents"
    echo "  encrypt  - Encrypt the vault file"
    echo "  decrypt  - Decrypt the vault file"
    echo "  rekey    - Change the vault password"
    echo "  status   - Show vault status and file information"
    echo "  help     - Show this help message"
    echo
    echo "Files:"
    echo "  Vault file: $VAULT_FILE"
    echo "  Password file: $VAULT_PASS_FILE"
}

# Main command handler
case "${1:-}" in
    edit)
        edit_vault
        ;;
    view)
        view_vault
        ;;
    encrypt)
        encrypt_vault
        ;;
    decrypt)
        decrypt_vault
        ;;
    rekey)
        change_password
        ;;
    status)
        status
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        print_error "Invalid command: ${1:-}"
        echo
        usage
        exit 1
        ;;
esac
