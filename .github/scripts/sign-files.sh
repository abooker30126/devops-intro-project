#!/usr/bin/env bash
# sign-files.sh — Sign a list of files with GPG and store detached signatures.
#
# Usage:
#   sign-files.sh "file1.sh file2.py ..."
#   sign-files.sh  (reads file paths from CHANGED_FILES env variable)
#
# Each file is signed with a detached armored signature stored alongside the
# original as <file>.gpg.sig.  Existing signatures are overwritten so they
# stay current with the file contents.
#
# Environment variables:
#   GPG_PASSPHRASE   — passphrase for the GPG key (required in CI)
#   GPG_KEY_ID       — (optional) specific key fingerprint/ID to use for signing

set -euo pipefail

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

log()  { echo "[sign-files] $*"; }
warn() { echo "[sign-files] WARNING: $*" >&2; }
die()  { echo "[sign-files] ERROR: $*" >&2; exit 1; }

# --------------------------------------------------------------------------- #
# Determine which files to sign
# --------------------------------------------------------------------------- #

# Prefer the first positional argument (newline-separated list), then fall back
# to the CHANGED_FILES environment variable.
if [[ $# -gt 0 ]]; then
  INPUT="$1"
else
  INPUT="${CHANGED_FILES:-}"
fi

if [[ -z "$INPUT" ]]; then
  log "No files provided — nothing to sign."
  exit 0
fi

# Convert the input into an array, skipping blank lines.
mapfile -t FILES < <(echo "$INPUT" | tr ' ' '\n' | sed '/^$/d')

if [[ ${#FILES[@]} -eq 0 ]]; then
  log "File list is empty — nothing to sign."
  exit 0
fi

# --------------------------------------------------------------------------- #
# Load the .gpg-ignore exclusion list (if present)
# --------------------------------------------------------------------------- #

IGNORE_FILE="${GITHUB_WORKSPACE:-.}/.gpg-ignore"
declare -a IGNORE_PATTERNS=()
if [[ -f "$IGNORE_FILE" ]]; then
  while IFS= read -r line; do
    # Skip blank lines and comments
    [[ -z "$line" || "$line" == \#* ]] && continue
    IGNORE_PATTERNS+=("$line")
  done < "$IGNORE_FILE"
fi

is_ignored() {
  local filepath="$1"
  for pattern in "${IGNORE_PATTERNS[@]:-}"; do
    # shellcheck disable=SC2254
    case "$filepath" in
      $pattern) return 0 ;;
    esac
  done
  return 1
}

# --------------------------------------------------------------------------- #
# GPG signing options
# --------------------------------------------------------------------------- #

GPG_OPTS=(
  --batch
  --yes
  --armor
  --detach-sign
)

# Optionally pin to a specific key
if [[ -n "${GPG_KEY_ID:-}" ]]; then
  GPG_OPTS+=(--local-user "$GPG_KEY_ID")
fi

# Use loopback pinentry for non-interactive environments (CI)
if [[ -n "${GPG_PASSPHRASE:-}" ]]; then
  GPG_OPTS+=(
    --pinentry-mode loopback
    --passphrase-fd 0
  )
fi

# --------------------------------------------------------------------------- #
# Sign each file
# --------------------------------------------------------------------------- #

SIGNED=0
SKIPPED=0
FAILED=0

for FILE in "${FILES[@]}"; do
  # Resolve relative to workspace root when running in CI
  FULL_PATH="${GITHUB_WORKSPACE:-.}/${FILE}"

  if [[ ! -f "$FULL_PATH" ]]; then
    warn "File not found, skipping: $FILE"
    (( SKIPPED++ )) || true
    continue
  fi

  if is_ignored "$FILE"; then
    log "Ignored (matches .gpg-ignore): $FILE"
    (( SKIPPED++ )) || true
    continue
  fi

  SIG_PATH="${FULL_PATH}.gpg.sig"

  log "Signing: $FILE → ${FILE}.gpg.sig"

  if [[ -n "${GPG_PASSPHRASE:-}" ]]; then
    if echo "$GPG_PASSPHRASE" | gpg "${GPG_OPTS[@]}" --output "$SIG_PATH" "$FULL_PATH"; then
      (( SIGNED++ )) || true
    else
      warn "Failed to sign: $FILE"
      (( FAILED++ )) || true
    fi
  else
    if gpg "${GPG_OPTS[@]/"--passphrase-fd 0"/}" --output "$SIG_PATH" "$FULL_PATH"; then
      (( SIGNED++ )) || true
    else
      warn "Failed to sign: $FILE"
      (( FAILED++ )) || true
    fi
  fi
done

# --------------------------------------------------------------------------- #
# Verify all freshly created signatures
# --------------------------------------------------------------------------- #

log "--- Verifying signatures ---"
VERIFY_FAILED=0
for FILE in "${FILES[@]}"; do
  FULL_PATH="${GITHUB_WORKSPACE:-.}/${FILE}"
  SIG_PATH="${FULL_PATH}.gpg.sig"
  [[ -f "$SIG_PATH" ]] || continue
  if gpg --batch --verify "$SIG_PATH" "$FULL_PATH" 2>/dev/null; then
    log "✔  Verified: $FILE"
  else
    warn "✘  Verification failed: $FILE"
    (( VERIFY_FAILED++ )) || true
  fi
done

# --------------------------------------------------------------------------- #
# Summary
# --------------------------------------------------------------------------- #

log "--- Summary ---"
log "  Signed:   $SIGNED"
log "  Skipped:  $SKIPPED"
log "  Failed:   $FAILED"
log "  Verify failures: $VERIFY_FAILED"

if (( FAILED > 0 || VERIFY_FAILED > 0 )); then
  die "One or more files could not be signed or verified."
fi
