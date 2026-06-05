# Secret Manager – odpowiednik Azure Key Vault.
# Źródło sekretów (GitHub App key, tokeny) dla External Secrets Operator na GKE.
resource "google_secret_manager_secret" "github_app" {
  secret_id = "${var.name_prefix}-github-app"

  replication {
    auto {}
  }
}

# GCP SA, do którego mapuje się Kubernetes SA ESO przez Workload Identity.
resource "google_service_account" "eso" {
  account_id   = "${var.name_prefix}-eso"
  display_name = "External Secrets Operator – ${var.name_prefix}"
}

resource "google_secret_manager_secret_iam_member" "eso_access" {
  secret_id = google_secret_manager_secret.github_app.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.eso.email}"
}

# Workload Identity: KSA external-secrets/external-secrets → GCP SA.
# Oba klastry współdzielą pulę WI projektu, więc jedno powiązanie obejmuje test + prod.
resource "google_service_account_iam_member" "eso_wi" {
  service_account_id = google_service_account.eso.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.eso_namespace}/${var.eso_ksa}]"
}

output "github_app_secret_id" {
  value = google_secret_manager_secret.github_app.secret_id
}

output "eso_sa_email" {
  value = google_service_account.eso.email
}
