# Dedykowane konto usługi dla węzłów (zasada najmniejszych uprawnień).
resource "google_service_account" "node" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "GKE node SA – ${var.cluster_name}"
}

# Odpowiednik AcrPull – odczyt obrazów z Artifact Registry + telemetria.
resource "google_project_iam_member" "node_roles" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.node.email}"
}

# GKE CONTROL PLANE – odpowiednik AKS (zarządzany master). ZONAL = tanio.
resource "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.zone # pojedyncza strefa → klaster zonal

  network    = var.network_id
  subnetwork = var.subnet_id

  # Usuwamy domyślny node pool – własny zarządzamy osobno.
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Workload Identity – pody używają tożsamości GCP bez kluczy (dla ESO).
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  deletion_protection = false
}

# NODE POOL – węzły robocze na Compute Engine (odpowiednik default_node_pool AKS).
resource "google_container_node_pool" "this" {
  name     = "systempool"
  location = var.zone
  cluster  = google_container_cluster.this.name

  node_count = var.node_count

  node_config {
    machine_type    = var.node_machine_type
    spot            = var.use_spot # true = Spot VM (oszczędność)
    service_account = google_service_account.node.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # auto-shutdown zmienia node_count do 0 – nie nadpisuj tego z TF.
  lifecycle {
    ignore_changes = [node_count]
  }
}

output "cluster_name" {
  value = google_container_cluster.this.name
}

output "node_pool_name" {
  value = google_container_node_pool.this.name
}

output "node_sa_email" {
  value = google_service_account.node.email
}
