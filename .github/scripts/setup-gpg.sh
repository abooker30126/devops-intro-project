#!/usr/bin/env bash
# setup-gpg.sh — Configure the local GPG environment for code-signing.
#
# What this script does:
#   1. Verifies that gpg and git are installed.
#   2. Imports a GPG private key (interactive or from a file / env variable).
#   3. Marks the imported key as ultimately trusted.
#   4. Configures git to sign commits and tags with that key.
#   5. Optionally enables gpg-agent's loopback pinentry (useful for scripted use).
#
# Usage:
#   # Interactive — follow the prompts
#   bash .github/scripts/setup-gpg.sh
#
#   # Non-interactive — supply key via environment variable
#   GPG_PRIVATE_KEY="$(cat my-key.asc)" bash .github/scripts/setup-gpg.sh
#
#   # Non-interactive — supply key from a file
#   KEY_FILE=/path/to/my-key.asc bash .github/scripts/setup-gpg.sh

set -euo pipefail

log()  { echo "[setup-gpg] $*"; }
warn() { echo "[setup-gpg] WARNING: $*" >&2; }
die()  { echo "[setup-gpg] ERROR: $*" >&2; exit 1; }

# --------------------------------------------------------------------------- #
# Pre-flight checks
# --------------------------------------------------------------------------- #

command -v gpg  >/dev/null 2>&1 || die "gpg is not installed. Install GnuPG and retry."
command -v git  >/dev/null 2>&1 || die "git is not installed."

GPG_VERSION=$(gpg --version | head -1)
log "Using $GPG_VERSION"

# --------------------------------------------------------------------------- #
# Import the GPG private key
# --------------------------------------------------------------------------- #

if [[ -n "${GPG_PRIVATE_KEY:-}" ]]; then
  log "Importing GPG key from GPG_PRIVATE_KEY environment variable..."
  echo "$GPG_PRIVATE_KEY" | gpg --batch --import
elif [[ -n "${KEY_FILE:-}" ]]; then
  [[ -f "$KEY_FILE" ]] || die "KEY_FILE not found: $KEY_FILE"
  log "Importing GPG key from file: $KEY_FILE"
  gpg --batch --import "$KEY_FILE"
else
  log "No key provided via GPG_PRIVATE_KEY or KEY_FILE."
  log "Please export your key and run one of:"
  log "  gpg --armor --export-secret-keys <KEY_ID> > my-key.asc"
  log "  KEY_FILE=my-key.asc bash .github/scripts/setup-gpg.sh"
  log ""
  log "If you already have a key in your keyring, we'll proceed using it."
  log "Press ENTER to continue or Ctrl-C to abort."
  read -r
fi

# --------------------------------------------------------------------------- #
# List available secret keys and pick one
# --------------------------------------------------------------------------- #

log "Available secret keys:"
gpg --list-secret-keys --keyid-format=long

KEY_ID="${GPG_KEY_ID:-}"

if [[ -z "$KEY_ID" ]]; then
  # Auto-select the first available key
  KEY_ID=$(gpg --list-secret-keys --keyid-format=long \
    | grep '^sec' \
    | head -1 \
    | sed 's|.*\/\([A-F0-9]\+\).*|\1|')
fi

if [[ -z "$KEY_ID" ]]; then
  die "Could not determine a GPG key ID. Set GPG_KEY_ID and retry."
fi

log "Using key ID: $KEY_ID"

# --------------------------------------------------------------------------- #
# Mark key as ultimately trusted
# --------------------------------------------------------------------------- #

FINGERPRINT=$(gpg --list-secret-keys --with-colons "$KEY_ID" \
  | awk -F: '/^fpr/{print $10; exit}')

if [[ -n "$FINGERPRINT" ]]; then
  log "Setting ultimate trust for fingerprint: $FINGERPRINT"
  echo "${FINGERPRINT}:6:" | gpg --import-ownertrust
else
  warn "Could not determine fingerprint — skipping trust assignment."
fi

# --------------------------------------------------------------------------- #
# Configure git to sign commits and tags
# --------------------------------------------------------------------------- #

log "Configuring git signing..."

git config --global user.signingkey "$KEY_ID"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

log "Git signing configured:"
log "  user.signingkey = $KEY_ID"
log "  commit.gpgsign  = true"
log "  tag.gpgsign     = true"

# --------------------------------------------------------------------------- #
# Enable loopback pinentry (optional — useful for scripted/CI use)
# --------------------------------------------------------------------------- #

GPG_AGENT_CONF="${GNUPGHOME:-$HOME/.gnupg}/gpg-agent.conf"

if ! grep -q "allow-loopback-pinentry" "$GPG_AGENT_CONF" 2>/dev/null; then
  echo "allow-loopback-pinentry" >> "$GPG_AGENT_CONF"
  log "Enabled loopback pinentry in $GPG_AGENT_CONF"
fi

gpgconf --kill gpg-agent 2>/dev/null || true
gpgconf --launch gpg-agent 2>/dev/null || true

# --------------------------------------------------------------------------- #
# Done
# --------------------------------------------------------------------------- #

log "GPG setup complete."
log ""
log "To export your public key and add it to GitHub:"
log "  gpg --armor --export $KEY_ID"
log ""
log "To verify a file signature:"
log "  gpg --verify <file>.gpg.sig <file>"
