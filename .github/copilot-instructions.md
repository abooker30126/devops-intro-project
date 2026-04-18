# Copilot instructions — devops-intro-project

## Build, test, and lint commands

| Purpose | Command | Notes |
| --- | --- | --- |
| Format the active Packer/Terraform workspace | `cd packer-templates/control-server && ./build.sh fmt` | Runs `packer fmt -recursive .` |
| Validate the active control-server AMI template | `cd packer-templates/control-server && ./build.sh validate` | Validates `control-server.pkr.hcl` |
| Build the control-server AMI | `cd packer-templates/control-server && ./build.sh build` | Produces `packer-manifest.json`, extracts the AMI ID with `jq`, and writes `terraform/terraform.auto.tfvars.json` |
| Build only the named Packer source | `cd packer-templates/control-server && ./build.sh build-only` | Uses `BUILD_NAME=control.amazon-ebs.ubuntu` from `build.sh` |
| Run a verbose/debug build | `cd packer-templates/control-server && ./build.sh debug` | Enables `PACKER_LOG` and writes logs under `logs/` |
| Initialize Terraform for the control server | `cd packer-templates/control-server && ./build.sh tf-init` | Wraps `terraform -chdir=terraform init` |
| Preview Terraform changes | `cd packer-templates/control-server && ./build.sh tf-plan` | Wraps `terraform -chdir=terraform plan` |
| Apply Terraform changes | `cd packer-templates/control-server && ./build.sh tf-apply` | Wraps `terraform -chdir=terraform apply -auto-approve` |
| Build the AMI and launch the EC2 instance | `cd packer-templates/control-server && ./build.sh build-and-apply` | End-to-end path for the current AWS control-server flow |
| Build the legacy/sample AWS app image | `cd packer-templates/aws/Launch_EC2_Using_Your_Packer_AMI && packer build application-server.pkr.hcl` | Older sample area; `application-server.json` is also present there |
| Verify one generated file signature | `gpg --verify path/to/file.gpg.sig path/to/file` | Matches the signing workflow documented in `.github/SECURITY_KEYS.md` |

No in-repo automated test suite or standalone linter was found. There is also no in-repo single-test command today. The README still documents an older `grunt -v` exercise against an external cloned app; treat that as legacy training material, not a test suite for this repository.

## High-level architecture

- The current source of truth is `packer-templates/control-server/`. `control-server.pkr.hcl` builds an Ubuntu 22.04 AMI in ordered phases: upload staged assets from `files/`, install base packages, install and configure Nginx, install Docker/AWS CLI/SSM/Jenkins, then harden the instance and emit `packer-manifest.json`.
- `packer-templates/control-server/build.sh` is the operational entrypoint. It wraps Packer and Terraform, extracts the AMI ID from `packer-manifest.json`, writes `terraform/terraform.auto.tfvars.json`, and then drives the Terraform deployment in `packer-templates/control-server/terraform/`.
- `packer-templates/control-server/terraform/` launches the EC2 instance from the Packer-built AMI and owns the surrounding AWS resources: key pair, security group, IAM role/profile, root volume settings, IMDSv2 enforcement, and `user_data`.
- Runtime configuration is staged under `packer-templates/control-server/files/`: Nginx config, app config, systemd units, and helper scripts are copied into the image first and then installed into final paths during the Packer build.
- `.github/workflows/gpg-sign-files.yml` plus `.github/scripts/setup-gpg.sh` and `.github/scripts/sign-files.sh` form a separate repository-security path: PRs sign modified `.sh`, `.py`, `.yml`, and `.tf` files and commit sibling `.gpg.sig` artifacts.
- `packer-templates/aws/Launch_EC2_Using_Your_Packer_AMI/` is a legacy/sample AWS Packer area with older JSON/HCL templates and a checked-in manifest. The root README still reflects that older learning flow in places, so prefer the control-server workspace when working on the current implementation.

## Key conventions

- Treat `packer-templates/control-server/control-server.pkr.hcl` as the active build definition. `build.sh` points directly at that file, so edits to adjacent `builders/` or `provisioners/` fragments do not affect the default build path unless the invocation changes.
- When changing runtime behavior, prefer editing staged assets in `packer-templates/control-server/files/` over embedding more inline shell in the Packer template. Phase 1 uploads those assets; Phase 4 copies them into `/etc/nginx`, `/opt/app/config`, `/etc/systemd/system`, and `/opt/scripts`.
- Do not rename or remove `packer-manifest.json` or `terraform/terraform.auto.tfvars.json` without updating `build.sh`; the script depends on those exact paths to pass the AMI ID from Packer into Terraform.
- Keep generated artifacts untracked. `.gitignore` already excludes Packer logs, `*.box`, manifests, Terraform state/plan files, and local `terraform.tfvars` overrides.
- If you modify `.sh`, `.py`, `.yml`, or `.tf` files outside `.github/`, expect the PR workflow to generate or refresh sibling `.gpg.sig` files unless the path is excluded in `.gpg-ignore`.
- Use `packer-templates/control-server/terraform/terraform.tfvars.example` as the template for local values such as `public_key` and `allowed_ssh_cidrs`; do not commit real public keys or broaden SSH/Jenkins CIDRs casually.
- Prefer AWS and Terraform MCP servers for infrastructure investigation, and GitHub MCP for workflow and CI/debugging tasks.
