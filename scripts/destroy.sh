#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "========================================="
echo "  DESTROY INFRASTRUCTURE (GCP)"
echo "========================================="

terraform destroy -var-file=envs/test.tfvars -auto-approve

echo "✅ Infrastruktura GCP usunięta (GKE test+prod, Artifact Registry, VPC, NAT, Secret Manager, scheduler)."
