#!/bin/bash

# This script clones the current repo twice (env1/env2), splits app generation evenly, and pushes to env1/env2 branches.
set -e

REPO_URL=$(git config --get remote.origin.url)
WORKDIR=$(pwd)
TMP_BASE=/tmp/argocd-monorepo
NUM_APPS=150
HALF=$((NUM_APPS / 2))

echo "Cloning repo for env1..."
rm -rf "$TMP_BASE-env1"
git clone "$REPO_URL" "$TMP_BASE-env1"
cd "$TMP_BASE-env1"
git checkout -B env1 || git checkout env1


# Clean and generate apps 1..75 in env1
find . -maxdepth 1 -type d -name 'app-*' ! -name '.app' -exec rm -rf {} +
for i in $(seq 1 $HALF); do
    cp -r .app "app-$i"
done
git add app-*
git commit -am "Generate apps 1..$HALF for env1"
git push -u origin env1

echo "Cloning repo for env2..."
rm -rf "$TMP_BASE-env2"
git clone "$REPO_URL" "$TMP_BASE-env2"
cd "$TMP_BASE-env2"
git checkout -B env2 || git checkout env2


# Clean and generate apps 76..150 in env2
find . -maxdepth 1 -type d -name 'app-*' ! -name '.app' -exec rm -rf {} +
for i in $(seq $((HALF+1)) $NUM_APPS); do
    cp -r .app "app-$i"
done
git add app-*
git commit -am "Generate apps $((HALF+1))..$NUM_APPS for env2"
git push -u origin env2

echo "Branches env1 and env2 initialized with split apps."
