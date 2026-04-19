#!/usr/bin/env bash
# verify-images.sh — Compare locally-cached Docker images against the
# SHA-256 content digests recorded in digests.lock.
#
# Usage:
#   scripts/verify-images.sh [LOCK_FILE]
#
# Arguments:
#   LOCK_FILE  Path to the digest lock file.
#              Defaults to digests.lock in the repository root.
#
# Exit codes:
#   0  All images match their pinned digests.
#   1  One or more images are missing locally, could not be inspected,
#      or do not match their expected digest (possible imposter).
#
# Typical workflow:
#   1. Run scripts/pin-digests.sh once to create digests.lock.
#   2. Commit digests.lock to version control.
#   3. Run scripts/verify-images.sh before every `docker compose up` to
#      confirm that nothing has been tampered with.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCK_FILE="${1:-"$REPO_ROOT/digests.lock"}"

if [[ ! -f "$LOCK_FILE" ]]; then
  echo "ERROR: digest lock file not found: $LOCK_FILE" >&2
  echo "       Run scripts/pin-digests.sh to create it." >&2
  exit 1
fi

# get_digest IMAGE — extract the registry SHA-256 content digest for an image
# that is already present in the local Docker cache.
# Prefers RepoDigests (registry-authoritative); falls back to the image ID
# for local builds or mirrors that do not populate RepoDigests.
get_digest() {
  local img="$1"
  local digest
  digest=$(
    docker inspect --format \
      '{{range .RepoDigests}}{{.}}{{"\n"}}{{end}}' \
      "$img" 2>/dev/null \
      | grep -oE 'sha256:[a-f0-9]{64}' \
      | head -1
  )
  if [[ -z "$digest" ]]; then
    digest=$(
      docker inspect --format '{{.Id}}' "$img" 2>/dev/null \
        | grep -oE 'sha256:[a-f0-9]{64}' \
        | head -1
    )
  fi
  echo "$digest"
}

PASS=0
FAIL=0
SKIP=0

echo "Verifying images against $LOCK_FILE ..."
echo ""

while IFS= read -r line; do
  # Skip blank lines and comments.
  [[ -z "$line" || "$line" == \#* ]] && continue

  image="${line%% *}"
  expected="${line##* }"

  if [[ -z "$image" || -z "$expected" || "$image" == "$expected" ]]; then
    echo "  WARN  malformed lock entry, skipping: $line"
    SKIP=$((SKIP + 1))
    continue
  fi

  printf "  %-60s " "$image"

  # Check whether the image exists in the local cache.
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "NOT PULLED — run: docker pull $image"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Prefer registry-signed RepoDigests; fall back to the image ID.
  actual=$(get_digest "$image")

  if [[ -z "$actual" ]]; then
    echo "DIGEST NOT FOUND"
    FAIL=$((FAIL + 1))
    continue
  fi

  if [[ "$actual" == "$expected" ]]; then
    echo "OK"
    PASS=$((PASS + 1))
  else
    echo "MISMATCH — possible imposter!"
    echo "           expected: $expected"
    echo "           actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
done < "$LOCK_FILE"

echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped."

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "VERIFICATION FAILED — do not start the stack until all images are verified." >&2
  exit 1
fi

echo "All images verified. Safe to start the stack."
