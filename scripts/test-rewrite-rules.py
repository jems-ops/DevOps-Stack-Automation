#!/usr/bin/env python3
"""
Test script to validate the rewrite rule template logic
"""

import sys
from jinja2 import Template

# Test templates
global_rewrite_template = """{% if site_rewrite_rule is defined %}
# Global rewrite rule
rewrite {{ site_rewrite_rule }};
{% endif %}"""

per_backend_template = """{% if backend.rewrite_rule is defined %}
# Per-backend rewrite rule
rewrite {{ backend.rewrite_rule }};
{% endif %}"""

print("🧪 Testing Nginx Rewrite Rule Template Logic\n")

# Test cases for global rewrite rules
print("=== Global Rewrite Rule Tests ===")
global_template = Template(global_rewrite_template)

global_test_cases = [
    {
        'name': 'Global rewrite rule defined',
        'context': {'site_rewrite_rule': '^/api/v1/(.*) /api/v2/$1 permanent'},
        'expected_contains': 'rewrite ^/api/v1/(.*) /api/v2/$1 permanent;'
    },
    {
        'name': 'No global rewrite rule',
        'context': {},
        'expected_contains': None
    }
]

all_passed = True
for i, test_case in enumerate(global_test_cases, 1):
    print(f"Test {i}: {test_case['name']}")

    try:
        result = global_template.render(**test_case['context'])
        print(f"  Output: {repr(result.strip())}")

        if test_case['expected_contains']:
            if test_case['expected_contains'] in result:
                print("  ✅ PASS\n")
            else:
                print(f"  ❌ FAIL - Expected to contain: {test_case['expected_contains']}\n")
                all_passed = False
        else:
            # No content expected
            if result.strip() == "":
                print("  ✅ PASS (no output expected)\n")
            else:
                print("  ❌ FAIL - Expected no output\n")
                all_passed = False
    except Exception as e:
        print(f"  ❌ ERROR: {e}\n")
        all_passed = False

# Test cases for per-backend rewrite rules
print("=== Per-Backend Rewrite Rule Tests ===")
backend_template = Template(per_backend_template)

backend_test_cases = [
    {
        'name': 'Backend with rewrite rule',
        'context': {
            'backend': {
                'server_name': 'jenkins.example.com',
                'rewrite_rule': '^/jenkins/(.*) /$1 break'
            }
        },
        'expected_contains': 'rewrite ^/jenkins/(.*) /$1 break;'
    },
    {
        'name': 'Backend without rewrite rule',
        'context': {
            'backend': {
                'server_name': 'jenkins.example.com'
            }
        },
        'expected_contains': None
    },
    {
        'name': 'Complex rewrite rule',
        'context': {
            'backend': {
                'server_name': 'api.example.com',
                'rewrite_rule': '^/project-([^-]+)-([0-9]+) /job/$1/$2 permanent'
            }
        },
        'expected_contains': 'rewrite ^/project-([^-]+)-([0-9]+) /job/$1/$2 permanent;'
    }
]

for i, test_case in enumerate(backend_test_cases, 1):
    print(f"Test {i}: {test_case['name']}")

    try:
        result = backend_template.render(**test_case['context'])
        print(f"  Output: {repr(result.strip())}")

        if test_case['expected_contains']:
            if test_case['expected_contains'] in result:
                print("  ✅ PASS\n")
            else:
                print(f"  ❌ FAIL - Expected to contain: {test_case['expected_contains']}\n")
                all_passed = False
        else:
            # No content expected
            if result.strip() == "":
                print("  ✅ PASS (no output expected)\n")
            else:
                print("  ❌ FAIL - Expected no output\n")
                all_passed = False
    except Exception as e:
        print(f"  ❌ ERROR: {e}\n")
        all_passed = False

# Test combined scenario
print("=== Combined Global + Per-Backend Test ===")
combined_template = Template(global_rewrite_template + "\n" + per_backend_template)

combined_test = {
    'name': 'Both global and backend rules',
    'context': {
        'site_rewrite_rule': '^/health /status redirect',
        'backend': {
            'server_name': 'jenkins.example.com',
            'rewrite_rule': '^/jenkins/(.*) /$1 break'
        }
    }
}

print(f"Test: {combined_test['name']}")
try:
    result = combined_template.render(**combined_test['context'])
    print(f"  Output:\n{result}")

    if ('rewrite ^/health /status redirect;' in result and
        'rewrite ^/jenkins/(.*) /$1 break;' in result):
        print("  ✅ PASS - Both rules present\n")
    else:
        print("  ❌ FAIL - Missing one or both rules\n")
        all_passed = False
except Exception as e:
    print(f"  ❌ ERROR: {e}\n")
    all_passed = False

if all_passed:
    print("🎉 All rewrite rule tests passed! The template logic is working correctly.")
    sys.exit(0)
else:
    print("❌ Some tests failed. Please review the template logic.")
    sys.exit(1)
