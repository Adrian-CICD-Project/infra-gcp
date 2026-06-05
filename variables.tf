# Minimalny, kosztooszczędny zestaw zmiennych – odpowiednik infra-azure
variable "project_id" {
  type        = string
  description = "ID projektu GCP (wymagane – brak domyślnej wartości)"
}

# Region/strefa tania i blisko westeurope: europe-west1 (Belgia)
variable "region" {
  type    = string
  default = "europe-west1"
}

# GKE ZONAL (jedna strefa) – taniej niż regional (brak replikacji węzłów ×3)
variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "name_prefix" {
  type    = string
  default = "devops-poc01"
}

# --- Sieć (VPC-native) ---
variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/24" # węzły
}

variable "pods_cidr" {
  type    = string
  default = "10.20.0.0/16" # secondary range: pody
}

variable "services_cidr" {
  type    = string
  default = "10.30.0.0/20" # secondary range: usługi
}

# --- Artifact Registry (odpowiednik ACR) ---
variable "registry_name" {
  type    = string
  default = "adrian-java-app"
}

# --- Klastry GKE (parytet z AKS) ---
variable "gke_test_name" {
  type    = string
  default = "devops-poc01-test"
}

variable "gke_prod_name" {
  type    = string
  default = "devops-poc01-prod"
}

# --- Węzły (Compute Engine) ---
# e2-standard-2 (~odpowiednik B4ms): 2 vCPU / 8 GB.
variable "node_machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "node_count" {
  type    = number
  default = 1
}

# true = Spot VM (do ~91% taniej); false = standardowe.
variable "use_spot" {
  type    = bool
  default = false
}

# --- Auto-shutdown ---
variable "shutdown_cron" {
  type    = string
  default = "0 18 * * *"
}

variable "schedule_timezone" {
  type    = string
  default = "Europe/Warsaw"
}
