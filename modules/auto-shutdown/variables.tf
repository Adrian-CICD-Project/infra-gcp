variable "name_prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type        = string
  description = "Region dla Cloud Scheduler"
}

variable "zone" {
  type        = string
  description = "Strefa klastrów (lokalizacja w API GKE)"
}

variable "cluster_names" {
  type        = list(string)
  description = "Klastry GKE do wygaszenia (test + prod)"
}

variable "node_pool_name" {
  type    = string
  default = "systempool"
}

variable "shutdown_cron" {
  type = string
}

variable "schedule_timezone" {
  type = string
}
