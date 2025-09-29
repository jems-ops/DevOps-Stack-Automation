#!/bin/bash
# Check that vault files are properly encrypted

set -e

echo "🔐 Checking vault file encryption..."

for file in group_vars/*/vault.yml; do
    if [ -f "$file" ]; then
        if ! head -1 "$file" | grep -q "\$ANSIBLE_VAULT"; then
            echo "❌ ERROR: $file is not encrypted!"
            echo "   Run: ansible-vault encrypt $file"
            exit 1
        else
            echo "✅ $file is properly encrypted"
        fi
    fi
done

echo "✅ All vault files are encrypted"
