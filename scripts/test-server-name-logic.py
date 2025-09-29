#!/usr/bin/env python3
"""
Test script to validate the Jinja2 server_name template logic
"""

import sys
from jinja2 import Template

# Template logic to test
template_str = "server_name {{ backend.server_name | join(' ') if backend.server_name is iterable and backend.server_name is not string else backend.server_name }};"

template = Template(template_str)

# Test cases
test_cases = [
    {
        'name': 'Single string server name',
        'backend': {'server_name': 'jenkins.example.com'},
        'expected': 'server_name jenkins.example.com;'
    },
    {
        'name': 'Multiple server names (list)',
        'backend': {'server_name': ['jenkins.example.com', 'jenkins.local', 'ci.example.com']},
        'expected': 'server_name jenkins.example.com jenkins.local ci.example.com;'
    },
    {
        'name': 'Single item list',
        'backend': {'server_name': ['jenkins.example.com']},
        'expected': 'server_name jenkins.example.com;'
    },
    {
        'name': 'Empty list (edge case)',
        'backend': {'server_name': []},
        'expected': 'server_name ;'
    }
]

print("🧪 Testing Jinja2 server_name template logic\n")

all_passed = True
for i, test_case in enumerate(test_cases, 1):
    print(f"Test {i}: {test_case['name']}")
    print(f"  Input: {test_case['backend']['server_name']}")

    try:
        result = template.render(backend=test_case['backend'])
        print(f"  Output: {result}")
        print(f"  Expected: {test_case['expected']}")

        if result == test_case['expected']:
            print("  ✅ PASS\n")
        else:
            print("  ❌ FAIL\n")
            all_passed = False
    except Exception as e:
        print(f"  ❌ ERROR: {e}\n")
        all_passed = False

if all_passed:
    print("🎉 All tests passed! The template logic is working correctly.")
    sys.exit(0)
else:
    print("❌ Some tests failed. Please review the template logic.")
    sys.exit(1)
