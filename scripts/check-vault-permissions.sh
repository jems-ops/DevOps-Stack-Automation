#!/bin/bash
# Check vault password file has correct permissions

set -e

echo "🔐 Checking vault password file permissions..."

if [ -f ".vault_pass" ]; then
    # Check permissions (should be 600)
    if [ "$(stat -f "%A" .vault_pass 2>/dev/null || stat -c "%a" .vault_pass 2>/dev/null)" != "600" ]; then
        echo "❌ ERROR: .vault_pass should have 600 permissions!"
        echo "   Run: chmod 600 .vault_pass"
        exit 1
    else
        echo "✅ .vault_pass has correct permissions (600)"
    fi
else
    echo "⚠️  WARNING: .vault_pass file not found"
    echo "   This is expected if you haven't set up Ansible Vault yet"
fi

echo "✅ Vault permissions check completed"
