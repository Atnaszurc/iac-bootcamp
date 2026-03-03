#!/usr/bin/env python3
"""
audit-examples.py - Check that all training modules have examples and tests

Usage: python3 scripts/audit-examples.py
"""

import os
from pathlib import Path

def check_module(module_path, module_name):
    """Check if a module has examples and tests"""
    module_path = Path(module_path)
    
    # First check if the module itself has an example/ directory
    example_path = module_path / 'example'
    if example_path.exists():
        check_example(str(module_path), module_name)
    
    # Then check subdirectories for examples
    subdirs = [d for d in module_path.iterdir() if d.is_dir() and d.name != 'example']
    for subdir in sorted(subdirs):
        subname = subdir.name
        sub_example_path = subdir / 'example'
        if sub_example_path.exists():
            check_example(str(subdir), f'{module_name}/{subname}')

def check_example(base_path, display_name):
    """Check if an example has main.tf and tests"""
    example_path = Path(base_path) / 'example'
    
    has_main = (example_path / 'main.tf').exists()
    tests_path = example_path / 'tests'
    has_tests = tests_path.exists()
    test_count = len(list(tests_path.glob('*.tftest.hcl'))) if has_tests else 0
    
    if has_main and has_tests:
        print(f'✅ {display_name}: example/ + tests/ ({test_count} test files)')
    elif has_main:
        print(f'⚠️  {display_name}: example/ exists but NO tests/')
    elif has_tests:
        print(f'⚠️  {display_name}: tests/ exists but NO main.tf')
    else:
        print(f'❌ {display_name}: NO example/ or tests/')

def main():
    print('=== Training Module Audit: Examples and Tests ===')
    print()

    print('--- TF-100: Fundamentals ---')
    for module in sorted(Path('TF-100-fundamentals').glob('TF-*')):
        if module.is_dir():
            check_module(str(module), module.name)

    print()
    print('--- TF-200: Modules ---')
    for module in sorted(Path('TF-200-modules').glob('TF-*')):
        if module.is_dir():
            check_module(str(module), module.name)

    print()
    print('--- TF-300: Advanced ---')
    for module in sorted(Path('TF-300-advanced').glob('TF-*')):
        if module.is_dir():
            check_module(str(module), module.name)

    print()
    print('--- TF-400: HCP/Enterprise ---')
    for module in sorted(Path('TF-400-hcp-enterprise').glob('TF-*')):
        if module.is_dir():
            check_module(str(module), module.name)

    print()
    print('--- Cloud: AWS ---')
    for module in sorted(Path('cloud-modules/AWS-200-terraform').glob('AWS-*')):
        if module.is_dir():
            check_module(str(module), module.name)

    print()
    print('--- Cloud: Azure ---')
    for module in sorted(Path('cloud-modules/AZ-200-terraform').glob('AZ-*')):
        if module.is_dir():
            check_module(str(module), module.name)

    print()
    print('--- Cloud: Multi-Cloud ---')
    for module in sorted(Path('cloud-modules/MC-300-multi-cloud').glob('MC-*')):
        if module.is_dir():
            check_module(str(module), module.name)

if __name__ == '__main__':
    main()

# Made with Bob
