#!/usr/bin/env python3

import sys
import os
from jinja2 import Environment, FileSystemLoader

# Add the project root to Python path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

def test_default_rewrite_rules():
    """Test rewrite rule logic using defaults from the reverse proxy role"""

    # Set up Jinja2 environment
    template_dir = os.path.join(project_root, 'roles', 'setup-nginx-reverse-proxy', 'templates')
    env = Environment(loader=FileSystemLoader(template_dir))

    # Load the template
    template = env.get_template('dynamic-backends.conf.j2')

    print("Testing rewrite rules from defaults/main.yml...")
    print("=" * 60)

    # Common variables needed by template
    common_vars = {
        'ansible_date_time': {
            'iso8601': '2025-09-29T14:54:41Z'
        }
    }

    # Test 1: Default backends with commented rewrite rules (should have no rewrite rules)
    test_data_1 = {
        **common_vars,
        'site_backends': [
            {
                'server_name': 'jenkins.example.com',
                'ip': '192.168.201.14',
                'port': '8080'
                # No rewrite_rule defined
            },
            {
                'server_name': 'sonar.example.com',
                'ip': '192.168.201.16',
                'port': '9000'
                # No rewrite_rule defined
            }
        ]
        # No site_rewrite_rule defined
    }

    # Test 2: With global rewrite rule enabled
    test_data_2 = {
        **common_vars,
        'site_rewrite_rule': '^/old-path/(.*) /new-path/$1 permanent',
        'site_backends': [
            {
                'server_name': 'jenkins.example.com',
                'ip': '192.168.201.14',
                'port': '8080'
            },
            {
                'server_name': 'sonar.example.com',
                'ip': '192.168.201.16',
                'port': '9000'
            }
        ]
    }

    # Test 3: With per-backend rewrite rules (as shown in defaults comments)
    test_data_3 = {
        **common_vars,
        'site_backends': [
            {
                'server_name': 'jenkins.example.com',
                'ip': '192.168.201.14',
                'port': '8080',
                'rewrite_rule': '^/jenkins/(.*) /$1 break'
            },
            {
                'server_name': 'sonar.example.com',
                'ip': '192.168.201.16',
                'port': '9000',
                'rewrite_rule': '^/sonar/(.*) /$1 break'
            }
        ]
    }

    # Test 4: Mixed configuration - global + per-backend rewrite rules
    test_data_4 = {
        **common_vars,
        'site_rewrite_rule': '^/api/v1/(.*) /v2/api/$1 redirect',
        'site_backends': [
            {
                'server_name': 'jenkins.example.com',
                'ip': '192.168.201.14',
                'port': '8080',
                'rewrite_rule': '^/jenkins/(.*) /$1 break'
            },
            {
                'server_name': 'sonar.example.com',
                'ip': '192.168.201.16',
                'port': '9000'
                # No per-backend rewrite rule
            }
        ]
    }

    test_cases = [
        ("Default backends (no rewrite rules)", test_data_1),
        ("Global rewrite rule only", test_data_2),
        ("Per-backend rewrite rules only", test_data_3),
        ("Mixed global + per-backend rewrite rules", test_data_4)
    ]

    for test_name, test_data in test_cases:
        print(f"\n{test_name}:")
        print("-" * 40)

        try:
            rendered = template.render(test_data)
            print(rendered)
        except Exception as e:
            print(f"ERROR: {e}")

        print()

if __name__ == '__main__':
    test_default_rewrite_rules()
