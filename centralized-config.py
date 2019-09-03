#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import getpass
import os
from pathlib import Path

HOME_DIR = os.path.dirname(os.path.realpath(__file__))

EXCLUDE_DIRS = ['.git']


def _get_config():
    for _, dirs, _ in os.walk(HOME_DIR):
        return [d for d in dirs if d not in EXCLUDE_DIRS]


def _generate_symlinks_config(config_name):
    root_path = os.path.join(HOME_DIR, config_name)
    symlinks = []
    for root, _, files in os.walk(root_path):
        for file in files:
            src = os.path.join(root, file)
            dst = src.replace(os.path.os.path.commonpath((root_path, src)), '')

            dst_split = Path(dst).parts
            # Add username, if home dir is processed
            if dst_split[1] == 'home':
                dst = os.path.join(
                    *dst_split[:2] + (getpass.getuser(), ) + dst_split[2:])
            symlinks.append((src, dst))
    return symlinks


def _setup_symlink(src, dst):
    try:
        if os.path.exists(dst):
            os.remove(dst)
        os.symlink(src, dst)
    except PermissionError as e:
        print(e)


def _setup_symlinks(symlinks):
    for symlink in symlinks:
        _setup_symlink(symlink[0], symlink[1])


def _dry_run(symlinks):
    print('Create symlinks:')
    for symlink in symlinks:
        print('%s => %s' % symlink)


parser = argparse.ArgumentParser()
parser.add_argument('-lc', '--list-configs', dest='list_configs', action='store_true',
                    help='List all available configurations.')
parser.add_argument('-d', '--dry-run', dest='dry_run', action='store_true',
                    help='Dry run. Only display symlinks that will be created')
parser.add_argument('configs', nargs='*',
                    choices=_get_config(), help='Configurations to use.')

args = parser.parse_args()

if args.list_configs:
    print('Available configurations:')
    for config in _get_config():
        print(config)
    exit(0)

if len(args.configs) == 0:
    parser.print_usage()
    exit(1)

symlinks = []

for config in set(args.configs):
    symlinks.extend(_generate_symlinks_config(config))

if args.dry_run:
    _dry_run(symlinks)
    exit(0)

_setup_symlinks(symlinks)
