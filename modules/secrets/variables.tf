variable "name_prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "eso_namespace" {
  type    = string
  default = "external-secrets"
}

variable "eso_ksa" {
  type        = string
  description = "Kubernetes ServiceAccount używany przez External Secrets Operator"
  default     = "external-secrets"
}
