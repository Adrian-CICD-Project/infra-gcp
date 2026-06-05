# Artifact Registry – odpowiednik Azure Container Registry (ACR).
# Tu trafiają obrazy Docker z pipeline CI (adrian-java-app).
resource "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = var.registry_name
  format        = "DOCKER"
  description   = "Rejestr obrazów aplikacji – odpowiednik ACR"

  # OSZCZĘDNOŚĆ: automatyczne kasowanie starych obrazów (storage).
  cleanup_policies {
    id     = "keep-recent-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"
    condition {
      older_than = "2592000s" # 30 dni
    }
  }
}

output "repository_url" {
  value = "${var.region}-docker.pkg.dev/${google_artifact_registry_repository.this.project}/${google_artifact_registry_repository.this.repository_id}"
}

output "repository_id" {
  value = google_artifact_registry_repository.this.repository_id
}
