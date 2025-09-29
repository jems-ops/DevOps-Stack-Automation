# Nginx Rewrite Rules Configuration

The dynamic nginx backend templates now support configurable rewrite rules, allowing you to modify request URLs before they're processed by your backend services.

## Overview

Rewrite rules can be configured at two levels:
1. **Global rewrite rules** - Applied to all backend services
2. **Per-backend rewrite rules** - Applied to specific backend services

## Configuration

### Global Rewrite Rules

Define a global rewrite rule that applies to all backends:

```yaml
# group_vars/all/main.yml
site_rewrite_rule: "^/api/v1/(.*) /api/v2/$1 permanent"

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

  # Global rewrite rule
  rewrite ^/api/v1/(.*) /api/v2/$1 permanent;

  # ... rest of configuration
}
```

### Per-Backend Rewrite Rules

Define specific rewrite rules for individual backends:

```yaml
# group_vars/all/main.yml
site_backends:
  - server_name: "jenkins.example.com"
    ip: "192.168.201.14"
    port: "8080"
    rewrite_rule: "^/jenkins/(.*) /$1 break"
  - server_name: "sonar.example.com"
    ip: "192.168.201.16"
    port: "9000"
    rewrite_rule: "^/sonar/(.*) /$1 break"
```

**Generated nginx config:**
```nginx
server {
  listen 80;
  server_name jenkins.example.com;

  location / {
    # Per-backend rewrite rule
    rewrite ^/jenkins/(.*) /$1 break;

    proxy_pass http://jenkins_backend;
    # ... rest of proxy configuration
  }
}
```

### Mixed Global and Per-Backend Rules

You can use both global and per-backend rules together:

```yaml
# Global rule applies to all backends
site_rewrite_rule: "^/health /status redirect"

site_backends:
  - server_name: "jenkins.example.com"
    ip: "192.168.201.14"
    port: "8080"
    # Specific rule for Jenkins only
    rewrite_rule: "^/ci/(.*) /$1 break"
  - server_name: "sonar.example.com"
    ip: "192.168.201.16"
    port: "9000"
    # No specific rule - only global rule applies
```

## Rewrite Rule Syntax

Nginx rewrite rules follow this syntax:
```
rewrite regex replacement [flag];
```

### Flags

| Flag | Description | Use Case |
|------|-------------|----------|
| `last` | Stop processing, search for new location | URL restructuring |
| `break` | Stop processing in current location | Path prefix removal |
| `redirect` | Return 302 temporary redirect | Temporary URL changes |
| `permanent` | Return 301 permanent redirect | SEO-friendly redirects |

### Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `$1`, `$2`, etc | Captured groups from regex | `^/api/v1/(.*) -> $1` |
| `$args` | Query string arguments | `?param=value` |
| `$uri` | Current URI | `/path/to/resource` |
| `$request_uri` | Original request URI with args | `/path?param=value` |

## Common Use Cases

### 1. Path Prefix Removal

Remove a path prefix before forwarding to backend:

```yaml
site_backends:
  - server_name: "jenkins.company.com"
    ip: "192.168.201.14"
    port: "8080"
    # /jenkins/job/test -> /job/test
    rewrite_rule: "^/jenkins/(.*) /$1 break"
```

### 2. Path Prefix Addition

Add a path prefix for backend routing:

```yaml
site_backends:
  - server_name: "api.company.com"
    ip: "192.168.201.14"
    port: "8080"
    # /users -> /v2/users
    rewrite_rule: "^/(?!v2/)(.*) /v2/$1 break"
```

### 3. API Versioning

Redirect old API versions to new ones:

```yaml
# Global rule for all services
site_rewrite_rule: "^/api/v1/(.*) /api/v2/$1 permanent"
```

### 4. Legacy URL Support

Handle old URL structures during migrations:

```yaml
site_backends:
  - server_name: "jenkins.company.com"
    ip: "192.168.201.14"
    port: "8080"
    # /build/project-name -> /job/project-name
    rewrite_rule: "^/build/(.*) /job/$1 permanent"
```

### 5. Environment-Specific Routing

Route to different backend paths based on environment:

```yaml
# Development
site_backends:
  - server_name: "jenkins.dev.company.com"
    ip: "192.168.201.14"
    port: "8080"
    # Add dev prefix: /api/test -> /dev/api/test
    rewrite_rule: "^/(.*) /dev/$1 break"
```

### 6. Complex Pattern Matching

Use regex groups for complex URL transformations:

```yaml
site_backends:
  - server_name: "jenkins.company.com"
    ip: "192.168.201.14"
    port: "8080"
    # /project-NAME-123 -> /job/NAME/123
    rewrite_rule: "^/project-([^-]+)-([0-9]+) /job/$1/$2 break"
```

## Template Implementation

### Global Rewrite Rules

Implemented in the server block before specific locations:

```jinja2
{% if site_rewrite_rule is defined %}
  # Global rewrite rule
  rewrite {{ site_rewrite_rule }};
{% endif %}
```

### Per-Backend Rewrite Rules

Implemented within the main location block:

```jinja2
location / {
{% if backend.rewrite_rule is defined %}
    # Per-backend rewrite rule
    rewrite {{ backend.rewrite_rule }};
{% endif %}
    proxy_pass http://{{ service_name }}_backend;
    # ... rest of proxy configuration
}
```

## Files Modified

### Templates Updated
1. **`roles/setup-nginx-reverse-proxy/templates/dynamic-backends.conf.j2`**
   - Added global rewrite rule support (server level)
   - Added per-backend rewrite rule support (location level)

2. **`roles/install-ssl-cert/templates/dynamic-backends-ssl.conf.j2`**
   - Added global rewrite rule support (server level)
   - Added per-backend rewrite rule support (location level)

### Configuration Files
1. **`roles/setup-nginx-reverse-proxy/defaults/main.yml`**
   - Added rewrite rule documentation and examples

2. **`roles/install-ssl-cert/defaults/main.yml`**
   - Added rewrite rule documentation and examples

3. **`group_vars/all/main.yml`**
   - Added rewrite rule examples and usage patterns

### Examples and Testing
1. **`examples/rewrite-rules-examples.yml`**
   - Comprehensive examples for various use cases

2. **`scripts/test-rewrite-rules.py`**
   - Automated testing of template logic

## Testing

### Automated Testing
```bash
# Test template logic
python3 scripts/test-rewrite-rules.py
```

### Manual Testing
```bash
# Test without rewrite rules (current setup)
ansible-playbook playbooks/setup-nginx-reverse-proxy.yml --check

# Test with rewrite rules - add rules to group_vars first
# Then run:
ansible-playbook playbooks/setup-nginx-reverse-proxy.yml

# Verify nginx config
ssh vagrant@192.168.201.15 "nginx -t"

# Test rewrite functionality
curl -I -H "Host: jenkins.example.com" http://192.168.201.15/jenkins/test
```

### Validation Commands
```bash
# Check generated configuration
ssh vagrant@192.168.201.15 "cat /etc/nginx/conf.d/dynamic-backends.conf"

# Test specific rewrites
curl -v -H "Host: jenkins.example.com" http://192.168.201.15/jenkins/api/json
```

## Production Considerations

### Performance
- **Minimize rewrites**: Too many rewrite rules can impact performance
- **Use appropriate flags**: `break` is faster than `last` for simple transformations
- **Avoid regex overhead**: Simple string matches are faster than complex regex

### SEO and URLs
- **Use permanent redirects (301)**: For SEO-friendly URL changes
- **Maintain URL structure**: Avoid breaking existing bookmarks and links
- **Test thoroughly**: Verify all URL patterns work as expected

### Monitoring
- **Log rewrite activity**: Monitor nginx access logs for rewrite behavior
- **Track redirects**: Ensure redirects don't create loops
- **Performance monitoring**: Watch for increased response times

## Troubleshooting

### Common Issues

#### Rewrite Loops
```bash
# Problem: Infinite redirect loop
rewrite_rule: "^/(.*) /app/$1 redirect"

# Solution: Use more specific patterns
rewrite_rule: "^/(?!app/)(.*) /app/$1 redirect"
```

#### Regex Syntax Errors
```bash
# Check nginx configuration
nginx -t

# Common issue: Unescaped special characters
# Wrong: ^/api/v1.0/(.*) /api/v2/$1
# Right: ^/api/v1\.0/(.*) /api/v2/$1
```

#### Rules Not Applied
```bash
# Verify template syntax
ansible-playbook playbooks/setup-nginx-reverse-proxy.yml --check --diff

# Check variable definition
ansible all -m debug -a "var=site_rewrite_rule"
ansible all -m debug -a "var=site_backends"
```

### Debug Tips

1. **Test incrementally**: Add one rewrite rule at a time
2. **Use curl with -v**: See full request/response flow
3. **Check nginx logs**: Look for rewrite activity in access logs
4. **Validate regex**: Test regex patterns separately before using in nginx

---

## Quick Reference

| Scenario | Configuration | Generated Rule |
|----------|---------------|----------------|
| Remove prefix | `rewrite_rule: "^/jenkins/(.*) /$1 break"` | `rewrite ^/jenkins/(.*) /$1 break;` |
| Add prefix | `rewrite_rule: "^/(.*) /v2/$1 break"` | `rewrite ^/(.*) /v2/$1 break;` |
| Permanent redirect | `rewrite_rule: "^/old/(.*) /new/$1 permanent"` | `rewrite ^/old/(.*) /new/$1 permanent;` |
| Temporary redirect | `rewrite_rule: "^/temp/(.*) /new/$1 redirect"` | `rewrite ^/temp/(.*) /new/$1 redirect;` |
| Global rule | `site_rewrite_rule: "^/health /status redirect"` | Applied to all backends |

The rewrite rules feature provides powerful URL transformation capabilities while maintaining the flexibility and dynamic nature of the existing backend configuration system.
