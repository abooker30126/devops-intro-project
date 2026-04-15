# Copilot instructions — devops-intro-project

Purpose
- Short guide for Copilot sessions to find build/test/lint commands, understand the top-level architecture, and respect repo conventions.

1) Build, test, and lint commands
- Packer image build (local):
  - cd packer-templates
  - packer build -only=virtualbox-iso application-server.json
  - (control server): packer build control-server.json
- Vagrant (local VM testing):
  - cd packer-templates/virtualbox
  - vagrant box add ubuntu-14.04.6-server-amd64-appserver_virtualbox.box --name devops-appserver
  - vagrant up && vagrant ssh
- Inside the VM (web app testing flow used in README):
  - git clone https://github.com/chef/devops-kungfu.git devops-kungfu
  - cd devops-kungfu
  - sudo npm install
  - Run tests: grunt -v  # runs the test suite from the app repo
- Single-test guidance:
  - This repo does not provide a per-test runner script. For a single test in the web app, invoke the app's underlying test runner directly (e.g., node ./node_modules/.bin/mocha test/path/to/file.js) from the app folder, or add a Grunt task if needed.
- Linting: No project-wide linter or lint commands detected in this repository. If linting is later added, include the top-level command and a per-file/per-rule invocation.

2) High-level architecture (big picture)
- Purpose: Teaching/practice repo for building VM images and provisioning local VMs for a sample web app.
- Packer templates (packer-templates/): contain JSON templates (application-server.json, control-server.json) and provisioning scripts (packer-templates/scripts/) that install services (nginx, jenkins, graphite, app setup, etc.).
- VirtualBox/Vagrant (packer-templates/virtualbox): Vagrantfile for testing built boxes locally.
- Jenkins config (jenkins-config/): holds config.xml, user config, and install_jenkins_plugins.sh. Used to seed Jenkins instance configuration in the images or as a reference.
- Workflow summary:
  1. Update PACKER_BOX_NAME / iso_checksum in templates for desired Ubuntu release
  2. packer build -> creates a box
  3. vagrant (or other consumer) uses box; VM boots and runs provisioning scripts
  4. Inside VM, clone sample web app (devops-kungfu) and run app-specific installs/tests

3) Key conventions and repo-specific notes
- Template edits:
  - When updating Ubuntu image/version, edit PACKER_BOX_NAME and iso_checksum directly in the relevant template file(s).
- Scripts layout:
  - packer-templates/scripts/ is organized by service; script names map to services called by the JSON templates. Keep names stable so templates continue to reference them correctly.
- Jenkins configuration:
  - jenkins-config/ contains XML job/user configs and an installer script for plugins. Treat XML here as canonical for seeding Jenkins in images.
- Legacy OS note:
  - Templates target Ubuntu 14.04 (trusty). README notes these may be out-of-date; verify and update iso/checksums before building.
- Ownership / reviewers:
  - CODEOWNERS points at @udacity/active-public-content; use that for suggested reviewers on PRs.

4) Other docs and AI assistant configs
- Source used: README.md (root). No existing .github/copilot-instructions.md detected prior to this file creation.
- No repository CLAUDE.md, .cursorrules, AGENTS.md, .windsurfrules, CONVENTIONS.md, or AIDER_CONVENTIONS.md were found. If added later, include relevant operational snippets here.

Contacts & quick pointers for Copilot
- Focus on packer-templates/ and jenkins-config/ for infra changes.
- If asked about running tests, point users to the README flow (build box -> vagrant -> clone app -> npm install -> grunt -v).

