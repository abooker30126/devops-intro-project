#!/bin/bash

################################################################################
# GPG Re-sign Commits Script - FIXED VERSION
# 
# This script re-signs commits with unsigned script files using SSH auth
#
# Prerequisites:
#   - GPG configured: git config --global user.signingkey <KEY_ID>
#   - SSH keys set up for GitHub
#   - SSH test: ssh -T git@github.com
#
# Usage: ./gpg-resign-commits.sh [--repo-only REPO_NAME] [--force]
#
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

USERNAME="abooker30126"
REPOS_DIR="./gpg-resign-temp"
FORCE_MODE=false
REPO_ONLY=""

# Target repositories and their script files
declare -A TARGET_FILES=(
    ["devops-intro-project"]="packer-templates/scripts/nginx.sh packer-templates/scripts/update.sh packer-templates/scripts/jenkins.sh"
    ["certified-kubernetes-security-specialist"]="domain-2-cluster-hardening/kubeadm-automate.sh domain-2-cluster-hardening/kubeadm-worker-automate.sh"
    ["devsecops"]="my-arsenal-of-aws-security-tools/ami/install-tools.sh my-arsenal-of-aws-security-tools/kreator/arsenal-kreator.sh"
)

REPOS=("devops-intro-project" "certified-kubernetes-security-specialist" "devsecops")

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

check_gpg_setup() {
    log_info "Checking GPG setup..."
    if ! gpg --list-secret-keys | grep -q "sec"; then
        log_error "No GPG secret keys found"
        return 1
    fi
    
    GPG_KEY=$(git config --global user.signingkey 2>/dev/null || echo "")
    if [ -z "$GPG_KEY" ]; then
        log_error "No git signing key configured"
        return 1
    fi
    
    log_success "GPG verified with key: $GPG_KEY"
    return 0
}

check_git_config() {
    log_info "Checking git configuration..."
    
    local name=$(git config --global user.name 2>/dev/null || echo "")
    local email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -z "$name" ] || [ -z "$email" ]; then
        log_error "Git user not configured"
        return 1
    fi
    
    log_success "Git configured: $name <$email>"
    return 0
}

check_ssh_access() {
    log_info "Checking SSH access to GitHub..."
    if ! ssh -T git@github.com 2>&1 | grep -q "You've successfully authenticated"; then
        log_error "SSH access to GitHub failed"
        return 1
    fi
    log_success "SSH access verified"
    return 0
}

clone_or_update_repo() {
    local repo=$1
    local repo_path="${REPOS_DIR}/${repo}"
    
    if [ -d "$repo_path" ]; then
        log_info "Updating $repo..."
        cd "$repo_path"
        git fetch origin
        git reset --hard origin/master 2>/dev/null || git reset --hard origin/main
    else
        log_info "Cloning $repo..."
        mkdir -p "$REPOS_DIR"
        cd "$REPOS_DIR"
        git clone "git@github.com:${USERNAME}/${repo}.git"
    fi
    
    cd "$repo_path"
    log_success "$repo ready at $repo_path"
    return 0
}

find_unsigned_commits() {
    local repo=$1
    local files_str=$2
    
    log_info "Finding commits for target files in $repo..."
    
    local count=0
    local IFS=' '
    for file in $files_str; do
        if [ -f "$file" ]; then
            count=$(git log --format='%H' -- "$file" 2>/dev/null | wc -l)
            log_info "  - $file: $count commits"
        fi
    done
    
    return 0
}

resign_commits() {
    local repo=$1
    local branch=$2
    
    log_info "Re-signing commits on $branch..."
    
    # Create backup branch
    local backup_branch="${branch}-backup-$(date +%s)"
    git branch "$backup_branch"
    log_info "Created backup: $backup_branch"
    
    # Re-sign all commits
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch \
        --env-filter ' \
            export GIT_COMMITTER_NAME="'"$(git config user.name)"'"\n            export GIT_COMMITTER_EMAIL="'"$(git config user.email)"'"\n            export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"\n        ' \
        --commit-filter ' \
            git commit-tree -S "$@"\n        ' \
        -- "$branch" || {\n            log_error "Re-signing failed"\n            git reset --hard "$backup_branch"\n            return 1\n        }\n    
    log_success "Commits re-signed"
    return 0
}

verify_signatures() {
    local branch=$1
    
    log_info "Verifying GPG signatures..."
    
    local total=0
    local signed=0
    
    while IFS= read -r commit; do
        ((total++))
        if git verify-commit "$commit" &>/dev/null; then
            ((signed++))
        fi
    done < <(git log --format='%H' "$branch")
    
    log_info "Verification: $signed/$total commits signed"
    
    if [ $signed -eq $total ]; then
        log_success "All commits verified!"
        return 0
    else
        log_warning "Only $signed/$total signed"
        return 1
    fi
}

push_changes() {
    local repo=$1
    local branch=$2
    
    log_warning "About to force-push to $branch"
    
    if [ "$FORCE_MODE" != "true" ]; then
        read -p "Continue? (yes/no): " response
        if [[ ! $response =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Push cancelled"
            return 1
        fi
    fi
    
    log_info "Pushing to origin/$branch..."
    git push origin "$branch" --force-with-lease || return 1
    
    log_success "Push complete"
    return 0
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force) FORCE_MODE=true; shift ;; 
            --repo-only) REPO_ONLY="$2"; shift 2 ;; 
            --help) echo "Usage: $0 [--force] [--repo-only REPO_NAME]"; exit 0 ;; 
            *) log_error "Unknown: $1"; exit 1 ;; 
        esac
    done
    
    log_info "========================================"; log_info "GPG Re-sign Commits"; log_info "========================================"
    echo ""
    
    check_gpg_setup || exit 1
    check_git_config || exit 1
    check_ssh_access || exit 1
    echo ""
    
    local repos_to_process=("${REPOS[@]}")
    if [ -n "$REPO_ONLY" ]; then
        repos_to_process=("$REPO_ONLY")
    fi
    
    for repo in "${repos_to_process[@]}"; do
        echo ""; log_info "========== $repo =========="; echo ""
        
        clone_or_update_repo "$repo" || continue
        cd "${REPOS_DIR}/${repo}"
        
        local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@.*/@@' || echo "master")
        
        find_unsigned_commits "$repo" "${TARGET_FILES[$repo]}"
        resign_commits "$repo" "$default_branch" || continue
        verify_signatures "$default_branch" || continue
        push_changes "$repo" "$default_branch" || continue
        
        log_success "$repo complete!"
    done
    
    echo ""; log_success "All done! Cleaning up..."; rm -rf "$REPOS_DIR"
}

trap "rm -rf $REPOS_DIR" EXIT
main "$@"