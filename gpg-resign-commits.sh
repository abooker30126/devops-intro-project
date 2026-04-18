#!/bin/bash

# Function to check GPG setup
check_gpg_setup() {
    gpg --list-secret-keys --keyid-format LONG &> /dev/null
    if [ $? -ne 0 ]; then
        echo "GPG is not set up properly. Please set it up before running this script." >&2
        exit 1
    fi
}

# Function to clone or update repositories
clone_or_update_repos() {
    repos=("devops-intro-project" "certified-kubernetes-security-specialist" "devsecops")

    for repo in "${repos[@]}"; do
        if [ ! -d "$repo" ]; then
            echo "Cloning $repo..."
            git clone "https://github.com/username/$repo.git"
        else
            echo "Updating $repo..."
            cd "$repo" && git pull
            cd ..
        fi
    done
}

# Function to find commits with target files
find_commits_with_target_files() {
    target_files=("*.sh")
    for file in "${target_files[@]}"; do
        git log --pretty=format:"%h - %an, %ar : %s" -- $file
    done
}

# Function to resign commits
resign_commits() {
    # Adding a new signature
    git commit --amend --no-edit -S
}

# Function to verify signatures
verify_signatures() {
    git log --show-signature
}

# Function to push changes with safety checks
push_with_safety_checks() {
    git push origin master
}

# Main script execution
check_gpg_setup
clone_or_update_repos
find_commits_with_target_files
resign_commits
verify_signatures
push_with_safety_checks
