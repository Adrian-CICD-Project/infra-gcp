#!/bin/bash
set -e

PROJECT="${GCP_PROJECT:?Ustaw zmienną GCP_PROJECT}"
ZONE="${GCP_ZONE:-europe-west1-b}"
CLUSTERS=("devops-poc01-test" "devops-poc01-prod")

MAX_RETRIES=20
SLEEP_SECONDS=15

echo "=== Dodaję repo Helm Argo ==="
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update

for CLUSTER in "${CLUSTERS[@]}"; do
  echo
  echo "========================================="
  echo "  ARGOCD + NAMESPACES DLA KLASTRA: ${CLUSTER}"
  echo "========================================="

  echo "→ Pobieram kubeconfig (gcloud container clusters get-credentials)..."
  gcloud container clusters get-credentials "${CLUSTER}" --zone "${ZONE}" --project "${PROJECT}"

  echo "→ Tworzę namespace argocd..."
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

  echo "→ Tworzę wymagane namespace'y środowiskowe..."
  if [ "${CLUSTER}" = "devops-poc01-test" ]; then
    NS_ENV_LIST=("environment-dev" "environment-test")
  else
    NS_ENV_LIST=("environment-prod")
  fi
  for NS in "${NS_ENV_LIST[@]}"; do
    echo "   - ${NS}"
    kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -
  done

  echo "→ Tworzę namespace'y dla narzędzi platformowych..."
  for NS in sonarqube dependency-track monitoring external-secrets; do
    echo "   - ${NS}"
    kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -
  done

  echo "→ Instaluję / aktualizuję ArgoCD przez Helm..."
  helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --set server.service.type=LoadBalancer \
    --wait

  echo "→ Czekam aż 'argocd-server' będzie gotowy..."
  kubectl -n argocd rollout status deploy argocd-server --timeout=300s || echo "   ❌ argocd-server NIE gotowy"

  echo "→ Czekam na IP z LoadBalancera..."
  IP=""
  i=1
  while [ $i -le $MAX_RETRIES ]; do
    IP=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [ -n "$IP" ]; then
      echo "   ✅ IP po ${i} próbach: ${IP}"
      break
    fi
    echo "   ...jeszcze brak IP, próba ${i}/${MAX_RETRIES}, czekam ${SLEEP_SECONDS}s"
    sleep "${SLEEP_SECONDS}"
    i=$((i+1))
  done
  [ -n "$IP" ] && echo "   🌐 ArgoCD URL: http://${IP}" || echo "   ❌ Brak IP LB dla ${CLUSTER}"

  echo "→ Hasło admina:"
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d && echo " (login: admin)" || echo "   ❌ Brak secreta"
done

echo
echo "  INSTALACJA ARGOCD ZAKOŃCZONA"
