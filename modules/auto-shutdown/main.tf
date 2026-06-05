# ============================================================
# AUTO-SHUTDOWN – odpowiednik Azure Automation (codziennie 18:00)
# Cloud Scheduler → bezpośrednie wywołanie GKE API nodePools.setSize = 0.
# Bez Cloud Function (taniej i prościej): SA + token OAuth wystarczą.
# ============================================================

# SA dla Cloud Scheduler – uprawnienie do zmiany rozmiaru node pool.
resource "google_service_account" "scheduler" {
  account_id   = "${var.name_prefix}-shutdown-sa"
  display_name = "GKE auto-shutdown scheduler"
}

resource "google_project_iam_member" "scheduler_container" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
}

# Jeden job harmonogramu na klaster (test + prod). Skaluje węzły do 0 o 18:00.
resource "google_cloud_scheduler_job" "shutdown" {
  for_each = toset(var.cluster_names)

  name      = "${each.value}-shutdown-18"
  region    = var.region
  schedule  = var.shutdown_cron
  time_zone = var.schedule_timezone

  http_target {
    http_method = "POST"
    uri         = "https://container.googleapis.com/v1/projects/${var.project_id}/locations/${var.zone}/clusters/${each.value}/nodePools/${var.node_pool_name}/setSize"
    body        = base64encode(jsonencode({ nodeCount = 0 }))

    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = google_service_account.scheduler.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}
