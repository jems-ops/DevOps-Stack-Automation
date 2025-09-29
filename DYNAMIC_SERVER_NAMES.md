# Enhanced Server Names Support

The Nginx dynamic backend templates now support both single server names and multiple server name aliases for each backend service.

## Template Enhancement

The enhanced Jinja2 template logic automatically handles both single strings and lists of server names:

```jinja2
server_name {{ backend.server_name | join(' ') if backend.server_name is iterable and backend.server_name is not string else backend.server_name }};
```

### How It Works

The template logic checks:
1. **Is iterable?** - Can we loop through it? (lists, tuples)
2. **Is NOT string?** - Strings are iterable in Python, but we want to treat them as single values
3. **If both true**: Join list elements with spaces
4. **Otherwise**: Use the value directly

## Configuration Examples

### Single Server Name (Current Usage)
```yaml
site_backends:
  - server_name: "jenkins.example.com"
    ip: "192.168.201.14"
    port: "8080"
  - server_name: "sonar.example.com"
    ip: "192.168.201.16"
    port: "9000"
```

**Generated nginx config:**
```nginx
server {
  listen 80;
  server_name jenkins.example.com;
  # ... rest of config
}
```

### Multiple Server Names (Aliases)
```yaml
site_backends:
  - server_name:
      - "jenkins.example.com"
      - "jenkins.local"
      - "ci.example.com"
      - "build.company.com"
    ip: "192.168.201.14"
    port: "8080"
  - server_name:
      - "sonar.example.com"
      - "sonar.local"
      - "quality.example.com"
    ip: "192.168.201.16"
    port: "9000"
```

**Generated nginx config:**
```nginx
server {
  listen 80;
  server_name jenkins.example.com jenkins.local ci.example.com build.company.com;
  # ... rest of config
}

server {
  listen 80;
  server_name sonar.example.com sonar.local quality.example.com;
  # ... rest of config
}
```

### Mixed Configuration
```yaml
site_backends:
  - server_name: "jenkins.example.com"  # Single name
    ip: "192.168.201.14"
    port: "8080"
  - server_name:  # Multiple names
      - "sonar.example.com"
      - "sonar.local"
      - "code-quality.internal"
    ip: "192.168.201.16"
    port: "9000"
```

## Benefits

### 1. **Backward Compatibility**
- Existing configurations with single server names continue to work unchanged
- No migration required for current deployments

### 2. **Flexible Domain Management**
- Support for multiple domains per service
- Easy to add development, staging, or regional domains
- Internal and external domain support

### 3. **SSL Certificate Management**
- Works with both HTTP and HTTPS templates
- Each backend can have multiple certificate Subject Alternative Names (SANs)

### 4. **Use Cases**

#### Development Environments
```yaml
- server_name:
    - "jenkins.dev.company.com"
    - "jenkins-dev.internal"
    - "ci-dev.local"
```

#### Multi-Region Support
```yaml
- server_name:
    - "jenkins.us.company.com"
    - "jenkins.eu.company.com"
    - "jenkins.asia.company.com"
```

#### Brand Migration
```yaml
- server_name:
    - "jenkins.newbrand.com"  # New domain
    - "jenkins.oldbrand.com"  # Legacy domain for transition
```

## Files Updated

### Templates Enhanced
1. **`roles/setup-nginx-reverse-proxy/templates/dynamic-backends.conf.j2`**
   - HTTP-only template with enhanced server_name logic

2. **`roles/install-ssl-cert/templates/dynamic-backends-ssl.conf.j2`**
   - HTTPS template with enhanced server_name logic
   - Both HTTP redirect and HTTPS server blocks updated

### Configuration Files
- **`group_vars/all/main.yml`** - Added documentation and examples
- **`examples/multiple-server-names-example.yml`** - Complete usage examples

### Testing
- **`scripts/test-server-name-logic.py`** - Automated testing of template logic
- All test cases pass for single strings, lists, and edge cases

## Testing the Enhancement

### Automated Testing
```bash
# Run the template logic tests
python3 scripts/test-server-name-logic.py
```

### Manual Testing
```bash
# Test with current configuration (single names)
ansible-playbook playbooks/setup-nginx-reverse-proxy.yml --check

# Test with multiple names - modify group_vars/all/main.yml first
# Then run the playbook
```

### Validation
```bash
# Check generated nginx config
ssh vagrant@192.168.201.15 "cat /etc/nginx/conf.d/dynamic-backends.conf"

# Test nginx config syntax
ssh vagrant@192.168.201.15 "nginx -t"
```

## Implementation Details

### Jinja2 Filter Breakdown
```jinja2
{{ backend.server_name | join(' ') if backend.server_name is iterable and backend.server_name is not string else backend.server_name }}
```

1. **`backend.server_name`** - The variable to process
2. **`is iterable`** - Check if it's a list/array
3. **`is not string`** - Exclude strings (which are technically iterable)
4. **`join(' ')`** - Join list elements with spaces
5. **`else backend.server_name`** - Use original value if not a list

### Edge Cases Handled
- ✅ Single string: `"jenkins.example.com"`
- ✅ List of strings: `["jenkins.example.com", "jenkins.local"]`
- ✅ Single-item list: `["jenkins.example.com"]`
- ✅ Empty list: `[]` (generates empty server_name)

### SSL Certificate Considerations

When using multiple server names, ensure your SSL certificates include all domains:

#### Self-signed Certificates
The dynamic SSL role automatically uses the first server name as the certificate CN and includes all names as SANs.

#### Production Certificates
For production, obtain certificates that include all server names as Subject Alternative Names (SANs).

## Migration Guide

### From Single to Multiple Names
1. **Current configuration:**
   ```yaml
   server_name: "jenkins.example.com"
   ```

2. **New configuration with aliases:**
   ```yaml
   server_name:
     - "jenkins.example.com"      # Keep existing
     - "jenkins.internal"         # Add aliases
     - "ci.company.com"
   ```

3. **Deploy and test:**
   ```bash
   ansible-playbook playbooks/setup-nginx-reverse-proxy.yml
   curl -H "Host: jenkins.internal" http://192.168.201.15
   ```

## Troubleshooting

### Common Issues

#### Syntax Errors in YAML
```yaml
# ❌ Wrong - missing dash for list items
server_name:
  "jenkins.example.com"
  "jenkins.local"

# ✅ Correct - proper YAML list syntax
server_name:
  - "jenkins.example.com"
  - "jenkins.local"
```

#### Nginx Configuration Test Failure
```bash
# Check syntax
nginx -t

# Common issue: too many server_name entries
# Nginx limit: ~64KB for server_name directive
```

#### SSL Certificate Mismatch
```bash
# Ensure certificate includes all server names
openssl x509 -in /etc/nginx/tls/jenkins.example.com.crt -text -noout | grep -A 5 "Subject Alternative Name"
```

### Validation Commands
```bash
# Test all server names work
for name in jenkins.example.com jenkins.local ci.company.com; do
  echo "Testing $name:"
  curl -I -H "Host: $name" http://192.168.201.15
done
```

---

## Quick Reference

| Configuration Type | YAML Syntax | Generated nginx |
|-------------------|-------------|-----------------|
| Single name | `server_name: "jenkins.example.com"` | `server_name jenkins.example.com;` |
| Multiple names | `server_name: ["jenkins.example.com", "jenkins.local"]` | `server_name jenkins.example.com jenkins.local;` |
| Mixed single/multiple | Both in same configuration | Each generates appropriate syntax |

The enhancement provides maximum flexibility while maintaining full backward compatibility with existing configurations.
