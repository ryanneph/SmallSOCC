#!/usr/bin/env python
"""Prepare build for commit, including version number updating"""

import sys, os
from os.path import join as pjoin
from string import Template
from subprocess import check_output
from smallsocc.version import VERSION_FULL

cdir = pjoin(os.path.dirname(os.path.abspath(__file__)), 'smallsocc')

def commits_since_tag():
    return int(check_output('git rev-list $(git rev-list --tags --no-walk --max-count=1)..HEAD --count', shell=True, cwd=cdir).decode('utf-8'))

def git_hash():
    if commits_since_tag() > 0:
        return check_output('git rev-parse --verify --short=7 HEAD', shell=True, cwd=cdir).decode('utf-8').strip(' \n')
    else: return ''


if __name__ == '__main__':
    f = pjoin(cdir, "version")
    with open(f+'.in', "r") as fd:
        temp = Template(fd.read())

    with open(f+'.py', 'w') as fd:
        fd.writelines(temp.substitute({'version_hash': git_hash()}))

    print("Setting version to: {}".format(VERSION_FULL))
