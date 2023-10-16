#!/usr/bin/env python3

from github import Github

import requests

import hashlib
import os
import re
import sys

def download_and_sha256(url):
    response = requests.get(url)
    return hashlib.sha256(response.content).hexdigest()

if len(sys.argv) < 2:
    print("Usage: {} [GitHub pat]".format(sys.argv[0]))
    sys.exit(1)

formula_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../Formula'))
repos_to_formula = {
        'jrl-umi3218/eigen-qld': 'eigen-qld.rb',
        'jrl-umi3218/eigen-quadprog': 'eigen-quadprog.rb',
        'jrl-umi3218/SpaceVecAlg': 'spacevecalg.rb',
        'jrl-umi3218/RBDyn': 'rbdyn.rb',
        'jrl-umi3218/sch-core': 'sch-core.rb',
        'jrl-umi3218/Tasks': 'tasks.rb',
        'jrl-umi3218/tvm': 'tvm.rb',
        'jrl-umi3218/state-observation': 'state-observation.rb',
        'jrl-umi3218/mc_rtc_data': 'mc_rtc_data.rb',
        'jrl-umi3218/mc_rtc': 'mc_rtc.rb',
}

g = Github(sys.argv[1])

revision = re.compile(".*? revision ([0-9]+).*?", re.M | re.S)
url = re.compile('.*? url "(.*?)"', re.M | re.S)
sha = re.compile('.*? sha256 "(.*?)"', re.M | re.S)

for stub, formula in repos_to_formula.items():
    repo = g.get_repo(stub)
    release = repo.get_latest_release()
    tag = release.tag_name
    asset = [a.browser_download_url for a in release.get_assets() if a.browser_download_url.endswith('.tar.gz')][0]
    formula_data = open(os.path.join(formula_dir, formula)).read()
    prev_asset = url.match(formula_data).group(1)
    if prev_asset == asset:
        continue
    formula_data = formula_data.replace(prev_asset, asset)
    prev_sha = sha.match(formula_data).group(1)
    new_sha = download_and_sha256(asset)
    formula_data = formula_data.replace(prev_sha, new_sha)
    revision_match = revision.match(formula_data)
    if revision_match:
        formula_data = formula_data.replace("revision {}".format(revision_match.group(1)), "")
    open(os.path.join(formula_dir, formula), 'w').write(formula_data)
    os.system('cd {} && git add {} && git commit -m "[{}] Update to {}"'.format(formula_dir, formula, formula.replace('.rb', ''), tag.replace('v', '')))
