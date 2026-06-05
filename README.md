# Infrastructure – GCP DevOps Project

Provisioning GKE (×2, zonal), Artifact Registry, VPC, Secret Manager, ArgoCD (via script) i auto-shutdown.
Odpowiednik `infra-azure`, dostosowany pod **niskie koszty**.

---

## Overview

Repozytorium zawiera kompletny kod Terraform IaC dla warstwy GCP projektu DevOps:

- VPC custom + subnet z secondary ranges (VPC-native) + Cloud NAT
- Artifact Registry (rejestr obrazów – odpowiednik ACR)
- Klastry GKE **zonal**:
  - **devops-poc01-test**
  - **devops-poc01-prod**
- Węzły robocze na **Compute Engine** (`e2-standard-2`, scale-to-zero)
- Secret Manager + Workload Identity dla External Secrets Operator (odpowiednik Key Vault)
- Auto-shutdown (Cloud Scheduler → GKE setSize API) – codziennie 18:00 skaluje węzły do 0

> **ArgoCD** instaluje skrypt `install-argocd.sh` (jak w `infra-azure`).

---

## Mapowanie Azure → GCP

| Rola | Azure | GCP |
|---|---|---|
| Sieć | VNet | VPC + subnet + Cloud NAT |
| Rejestr obrazów | ACR | Artifact Registry |
| Klaster K8s | AKS | GKE (zonal) |
| Węzły | VM `Standard_B4ms` | **Compute Engine** `e2-standard-2` |
| Sekrety | Key Vault | Secret Manager |
| Auto-shutdown | Automation Account | Cloud Scheduler + GKE API |

Pełny opis komponentów: `documentation/multicloud-infrastructure.md`.

---

## Repository Structure

```
infra-gcp/
├── main.tf, providers.tf, variables.tf, outputs.tf, versions.tf
├── envs/{test.tfvars, prod.tfvars}
├── modules/
│   ├── network/            # VPC, subnet + secondary ranges (pods/services), Cloud NAT
│   ├── artifact-registry/  # repo Docker + cleanup policy
│   ├── gke/                # cluster zonal + node pool (Compute Engine) + Workload Identity
│   ├── secrets/            # Secret Manager + Workload Identity dla ESO
│   └── auto-shutdown/      # Cloud Scheduler → setSize=0 (18:00)
├── scripts/{deploy.sh, destroy.sh, install-argocd.sh, check-infra.sh}
└── README.md
```

---

## Deployment Flow

```bash
# 1. Zaloguj się i ustaw projekt
gcloud auth application-default login
# Ustaw project_id w envs/*.tfvars

# 2. Pełny deploy
export GCP_PROJECT=<twoje-project-id>
./scripts/deploy.sh
```

Manualnie:
```bash
terraform init
terraform apply -var-file=envs/test.tfvars -auto-approve   # tworzy OBA klastry (test + prod)
./scripts/install-argocd.sh
./scripts/check-infra.sh
```

---

## Required Namespaces

| Cluster            | Namespaces                        |
| ------------------ | --------------------------------- |
| devops-poc01-test  | environment-dev, environment-test |
| devops-poc01-prod  | environment-prod                  |

---

## Koszty / FinOps

Mechanizmy ograniczające koszt:

- **GKE zonal** (jedna strefa) – brak replikacji węzłów ×3 jak w regional; pierwszy klaster zonal ma
  darmowe zarządzanie w ramach GCP free tier.
- **Auto-shutdown 18:00** – węzły skalowane do 0 (Cloud Scheduler → GKE API).
- **1 węzeł `e2-standard-2`** na klaster.
- **Spot VM** – ustaw `use_spot = true` w `envs/*.tfvars` (do ~91% taniej).
- **Artifact Registry cleanup policy** – trzyma 10 ostatnich obrazów, kasuje starsze niż 30 dni.

> Opłata za zarządzanie GKE to ok. 0,10 USD/h za klaster (pierwszy zonal w ramach free tier).
> Główny koszt godzinowy generują węzły – dlatego wygaszamy je o 18:00.

---

## Requirements

- gcloud CLI
- Terraform >= 1.6
- kubectl, Helm >= 3.x
- Bash

---

## Cleanup

```bash
./scripts/destroy.sh
```
