# GPG Signing — Security Keys Guide

This document explains how to set up GPG signing locally, verify file
signatures, and configure the required GitHub Secrets.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Generating a GPG Key](#generating-a-gpg-key)
3. [Exporting Keys for GitHub Secrets](#exporting-keys-for-github-secrets)
4. [Adding Secrets to GitHub](#adding-secrets-to-github)
5. [Local Setup with setup-gpg.sh](#local-setup-with-setup-gpgsh)
6. [Verifying Signatures](#verifying-signatures)
7. [Workflow Overview](#workflow-overview)

---

## Prerequisites

- **GnuPG 2.x** — Install with:
  - macOS: `brew install gnupg`
  - Ubuntu/Debian: `sudo apt-get install gnupg`
  - Windows: Download from <https://www.gnupg.org/download/>
- **git** 2.x or later

---

## Generating a GPG Key

```bash
gpg --full-generate-key
```

When prompted:

| Prompt | Recommended value |
|---|---|
| Key type | `RSA and RSA` (option 1) |
| Key size | `4096` |
| Expiry | `2y` (rotate every two years) |
| Real name | Your full name |
| Email | Your GitHub-verified email address |
| Passphrase | A strong, unique passphrase |

After generation, find your key ID:

```bash
gpg --list-secret-keys --keyid-format=long
```

The key ID is the hex string after the `/` on the `sec` line, e.g. `B732B308C0FE0BB3`.

---

## Exporting Keys for GitHub Secrets

### Private key (for `GPG_PRIVATE_KEY` secret)

```bash
gpg --armor --export-secret-keys <KEY_ID>
```

Copy the entire output, including the `-----BEGIN PGP PRIVATE KEY BLOCK-----`
header and `-----END PGP PRIVATE KEY BLOCK-----` footer.

### Public key (for GitHub profile / collaborator verification)

```bash
gpg --armor --export <KEY_ID>
```

Add this to your GitHub account at **Settings → SSH and GPG keys → New GPG key**.

---

## Adding Secrets to GitHub

Go to your repository on GitHub:
**Settings → Secrets and variables → Actions → New repository secret**

| Secret name | Value |
|---|---|
| `GPG_PRIVATE_KEY` | Output of `gpg --armor --export-secret-keys <KEY_ID>` |
| `GPG_PASSPHRASE` | The passphrase you chose when creating the key |

> ⚠️ **Never commit your private key to the repository.**

---

## Local Setup with setup-gpg.sh

Run the helper script to configure your local environment:

```bash
# Interactive (prompts for a key if none found)
bash .github/scripts/setup-gpg.sh

# Non-interactive with an existing key file
KEY_FILE=/path/to/my-private-key.asc bash .github/scripts/setup-gpg.sh

# Non-interactive with a key stored in an environment variable
export GPG_PRIVATE_KEY="$(gpg --armor --export-secret-keys <KEY_ID>)"
bash .github/scripts/setup-gpg.sh
```

The script will:

1. Import the GPG key into your local keyring.
2. Mark it as ultimately trusted.
3. Configure `git` to sign all commits and tags with that key.

---

## Verifying Signatures

Each signed file has a corresponding `.gpg.sig` detached-signature file.

### Verify a single file

```bash
gpg --verify <file>.gpg.sig <file>
```

A successful verification looks like:

```
gpg: Signature made Mon Apr 18 19:00:00 2024 UTC
gpg:                using RSA key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gpg: Good signature from "Your Name <your@email.com>" [ultimate]
```

### Verify all signature files in the repository

```bash
find . -name '*.gpg.sig' | while read -r sig; do
  original="${sig%.gpg.sig}"
  echo -n "Verifying $original ... "
  gpg --batch --verify "$sig" "$original" 2>/dev/null \
    && echo "OK" \
    || echo "FAILED"
done
```

---

## Workflow Overview

The GitHub Actions workflow (`.github/workflows/gpg-sign-files.yml`) runs
automatically on every pull request:

1. **Detects modified files** — uses `git diff` to find `.sh`, `.py`, `.yml`,
   and `.tf` files changed in the PR.
2. **Imports the private key** — reads the `GPG_PRIVATE_KEY` secret.
3. **Signs each file** — calls `.github/scripts/sign-files.sh` to create
   armored detached signatures (`.gpg.sig`).
4. **Commits signatures** — pushes the new/updated signature files back to the
   PR branch.
5. **Reports results** — posts a comment listing every signed file.

Files and directories listed in `.gpg-ignore` are excluded from signing.
