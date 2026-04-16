#!/usr/bin/env bash
set -euo pipefail

PACKER_FILE="control-server.pkr.hcl"
BUILD_NAME="control.amazon-ebs.ubuntu"
LOG_DIR="logs"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
LOG_FILE="${LOG_DIR}/build-${TIMESTAMP}.log"
TFVARS_FILE="terraform/terraform.auto.tfvars.json"

usage() {
  echo "Usage: $0 {fmt|validate|build|build-only|debug|clean|tf-init|tf-plan|tf-apply|build-and-apply}"
  exit 1
}

fmt() {
  packer fmt -recursive .
}

validate() {
  packer validate "${PACKER_FILE}"
}

extract_ami_id() {
  jq -r '.builds[-1].artifact_id' packer-manifest.json | cut -d':' -f2
}

write_tfvars() {
  local ami_id="$1"
  echo "Writing AMI ID to ${TFVARS_FILE}"
  cat > "${TFVARS_FILE}" <<EOF
{
  "ami_id": "${ami_id}"
}
EOF
}

build() {
  mkdir -p "${LOG_DIR}"

  packer build -machine-readable \
    "${PACKER_FILE}" | tee "${LOG_FILE}"

  local ami_id
  ami_id=$(extract_ami_id)

  echo "Built AMI: ${ami_id}"

  write_tfvars "${ami_id}"
}

build_only() {
  mkdir -p "${LOG_DIR}"

  packer build -only="${BUILD_NAME}" -machine-readable \
    "${PACKER_FILE}" | tee "${LOG_FILE}"

  local ami_id
  ami_id=$(extract_ami_id)

  echo "Built AMI: ${ami_id}"

  write_tfvars "${ami_id}"
}

debug() {
  mkdir -p "${LOG_DIR}"
  PACKER_LOG=1 PACKER_LOG_PATH="${LOG_FILE}" packer build "${PACKER_FILE}"
}

clean() {
  rm -rf /tmp/nginx || true
  rm -rf "${LOG_DIR}" || true
  rm -f packer-manifest.json || true
  rm -f "${TFVARS_FILE}" || true
}

tf_init() {
  terraform -chdir=terraform init
}

tf_plan() {
  terraform -chdir=terraform plan
}

tf_apply() {
  terraform -chdir=terraform apply -auto-approve
}

build_and_apply() {
  build
  terraform -chdir=terraform init
  terraform -chdir=terraform apply -auto-approve
}

case "${1:-}" in
  fmt) fmt ;;
  validate) validate ;;
  build) build ;;
  build-only) build_only ;;
  debug) debug ;;
  clean) clean ;;
  tf-init) tf_init ;;
  tf-plan) tf_plan ;;
  tf-apply) tf_apply ;;
  build-and-apply) build_and_apply ;;
  *) usage ;;
esac
