variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "environment_name" {
  description = "Name for the Confluent environment"
  type        = string
  default     = "backstage-env"
}

variable "cluster_name" {
  description = "Name for the Kafka cluster"
  type        = string
  default     = "backstage-cluster"
}

variable "cloud_provider" {
  description = "Cloud provider (AWS, GCP, AZURE)"
  type        = string
  default     = "GCP"
}

variable "region" {
  description = "Cloud region for the cluster"
  type        = string
  default     = "europe-west3"
}