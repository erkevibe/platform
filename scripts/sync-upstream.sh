#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
MIRROR_BRANCH="${MIRROR_BRANCH:-master}"
INTEGRATION_BRANCH="${INTEGRATION_BRANCH:-develop}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Run this script inside the platform fork." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit or stash changes first." >&2
  exit 1
fi

if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
  echo "Remote '$UPSTREAM_REMOTE' is not configured." >&2
  echo "Add it with: git remote add upstream https://github.com/lsfusion/platform.git" >&2
  exit 1
fi

START_BRANCH="$(git branch --show-current)"
if [[ -z "$START_BRANCH" ]]; then
  echo "Detached HEAD is not supported." >&2
  exit 1
fi

git fetch "$UPSTREAM_REMOTE" --prune --tags

git switch "$MIRROR_BRANCH"
git merge --ff-only "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"

git switch "$INTEGRATION_BRANCH"
git merge --no-ff "$MIRROR_BRANCH" -m "Merge upstream/$UPSTREAM_BRANCH into $INTEGRATION_BRANCH"

git switch "$START_BRANCH"

echo "Upstream synchronization completed locally. Review and test before pushing."
