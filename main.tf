########################
# Włączenie wymaganych API GCP
########################
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudscheduler.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

########################
# NETWORK (VPC) – odpowiednik Azure VNet
########################
module "network" {
  source        = "./modules/network"
  name_prefix   = var.name_prefix
  region        = var.region
  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  depends_on = [google_project_service.apis]
}

########################
# ARTIFACT REGISTRY – odpowiednik ACR
########################
module "artifact_registry" {
  source        = "./modules/artifact-registry"
  registry_name = var.registry_name
  region        = var.region

  depends_on = [google_project_service.apis]
}

########################
# GKE TEST – odpowiednik AKS test
########################
module "gke_test" {
  source              = "./modules/gke"
  cluster_name        = var.gke_test_name
  project_id          = var.project_id
  zone                = var.zone
  network_id          = module.network.network_id
  subnet_id           = module.network.subnet_id
  pods_range_name     = module.network.pods_range_name
  services_range_name = module.network.services_range_name
  node_machine_type   = var.node_machine_type
  node_count          = var.node_count
  use_spot            = var.use_spot
}

########################
# GKE PROD – odpowiednik AKS prod
########################
module "gke_prod" {
  source              = "./modules/gke"
  cluster_name        = var.gke_prod_name
  project_id          = var.project_id
  zone                = var.zone
  network_id          = module.network.network_id
  subnet_id           = module.network.subnet_id
  pods_range_name     = module.network.pods_range_name
  services_range_name = module.network.services_range_name
  node_machine_type   = var.node_machine_type
  node_count          = var.node_count
  use_spot            = var.use_spot
}

########################
# SECRETS – odpowiednik Key Vault
########################
module "secrets" {
  source      = "./modules/secrets"
  name_prefix = var.name_prefix
  project_id  = var.project_id

  depends_on = [google_project_service.apis]
}

########################
# AUTO-SHUTDOWN – scale-to-zero 18:00 (odpowiednik Azure Automation)
########################
module "auto_shutdown" {
  source            = "./modules/auto-shutdown"
  name_prefix       = var.name_prefix
  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  cluster_names     = [var.gke_test_name, var.gke_prod_name]
  shutdown_cron     = var.shutdown_cron
  schedule_timezone = var.schedule_timezone

  depends_on = [google_project_service.apis]
}
