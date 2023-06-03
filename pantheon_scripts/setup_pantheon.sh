#!/usr/bin/env bash

git clone https://github.com/StanfordSNR/pantheon.git
cd pantheon
git submodule update --init --recursive  # or tools/fetch_submodules.sh

./tools/install_deps.sh

src/experiments/setup.py --install-deps --all
src/experiments/setup.py --setup --all
