variable "cluster_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "zone" {
  type        = string
  description = "Strefa – klaster ZONAL (taniej niż regional)"
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "pods_range_name" {
  type = string
}

variable "services_range_name" {
  type = string
}

variable "node_machine_type" {
  type = string
}

variable "node_count" {
  type = number
}

variable "use_spot" {
  type = bool
}
