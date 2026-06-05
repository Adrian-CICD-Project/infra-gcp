#!/bin/bash
set -e

PROJECT="${GCP_PROJECT:?Ustaw zmienną GCP_PROJECT}"
ZONE="${GCP_ZONE:-europe-west1-b}"
REGION="${GCP_REGION:-europe-west1}"
CLUSTERS=("devops-poc01-test" "devops-poc01-prod")
REGISTRY="${REGISTRY_NAME:-adrian-java-app}"

echo "=== Artifact Registry ==="
gcloud artifacts repositories describe "$REGISTRY" --location "$REGION" --project "$PROJECT" \
  --format='value(name)' 2>/dev/null || echo "   ❌ Brak rejestru"

for CLUSTER in "${CLUSTERS[@]}"; do
  echo
  echo "=== GKE: ${CLUSTER} ==="
  gcloud container clusters describe "$CLUSTER" --zone "$ZONE" --project "$PROJECT" \
    --format='value(status)' 2>/dev/null || { echo "   ❌ Brak klastra"; continue; }

  echo "→ Rozmiar node pool (systempool):"
  gcloud container node-pools describe systempool --cluster "$CLUSTER" --zone "$ZONE" --project "$PROJECT" \
    --format='value(initialNodeCount)' 2>/dev/null || echo "   (brak)"

  echo "→ ArgoCD:"
  gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$PROJECT" >/dev/null 2>&1 || true
  kubectl -n argocd get pods 2>/dev/null || echo "   (brak dostępu / węzły wyłączone)"
done

echo
echo "=== Cloud Scheduler (auto-shutdown) ==="
gcloud scheduler jobs list --location "$REGION" --project "$PROJECT" 2>/dev/null || echo "   (brak jobów)"
