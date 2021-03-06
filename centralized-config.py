#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
    centralized-config
    Copyright (C) 2019 Andreas Harter

    This library is free software: you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 3 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see
    <https://www.gnu.org/licenses/>.
'''

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


def _setup_symlink(src, dst, remove=os.remove, makedirs=os.makedirs, symlink=os.symlink):
    try:
        if os.path.exists(dst):
            remove(dst)
        dst_dir = os.path.dirname(dst)
        if os.path.exists(dst_dir) and not os.path.isdir(dst_dir):
            print('%s exists, but is not a dir. Cannot setup link %s => %s' %
                  (dst_dir, src, dst))
            return
        makedirs(dst_dir, exist_ok=True)
        symlink(src, dst)
    except PermissionError as e:
        print(e)


def _setup_symlinks(symlinks):
    for symlink in symlinks:
        _setup_symlink(symlink[0], symlink[1])


def _dry_run(symlinks):
    def dry_remove(path):
        print('Remove %s' % path)

    def dry_makedirs(path, **kwargs):
        print('Makedirs: %s' % path)

    def dry_symlink(src, dst):
        print('Symlink %s => %s' % (src, dst))

    for symlink in symlinks:
        _setup_symlink(symlink[0], symlink[1],
                       dry_remove, dry_makedirs, dry_symlink)
        print()


parser = argparse.ArgumentParser()
parser.add_argument('-lc', '--list-configs', dest='list_configs', action='store_true',
                    help='List all available configurations.')
parser.add_argument('-d', '--dry-run', dest='dry_run', action='store_true',
                    help='Dry run. Only display symlinks that will be created')
parser.add_argument('configs', nargs='*', help='Configurations to use.')

args = parser.parse_args()

if args.list_configs:
    print('Available configurations:')
    for config in _get_config():
        print(config)
    exit(0)

if len(args.configs) == 0:
    parser.print_usage()
    exit(1)

for c in args.configs:
    if c not in _get_config():
        print('"%s" is not a valid config' % c)
        exit(1)

symlinks = []

for config in set(args.configs):
    symlinks.extend(_generate_symlinks_config(config))

if args.dry_run:
    _dry_run(symlinks)
    exit(0)

_setup_symlinks(symlinks)
