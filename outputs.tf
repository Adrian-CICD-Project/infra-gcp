output "region" {
  value = var.region
}

output "registry_url" {
  value = module.artifact_registry.repository_url
}

output "gke_test_name" {
  value = module.gke_test.cluster_name
}

output "gke_prod_name" {
  value = module.gke_prod.cluster_name
}

output "github_app_secret_id" {
  value = module.secrets.github_app_secret_id
}

output "eso_sa_email" {
  value = module.secrets.eso_sa_email
}
