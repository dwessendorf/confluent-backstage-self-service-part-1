variable "confluent_cloud_api_key" {
  type      = string
  sensitive = true
}

variable "confluent_cloud_api_secret" {
  type      = string
  sensitive = true
}

variable "environment_name" {
  type    = string
  default = "backstage-env"
}

variable "cluster_name" {
  type    = string
  default = "backstage-cluster"
}

variable "cloud_provider" {
  type    = string
  default = "GCP"
}

variable "region" {
  type    = string
  default = "europe-west3"
}