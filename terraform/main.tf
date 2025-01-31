provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Create Confluent Environment 
resource "confluent_environment" "env" {
  display_name = var.environment_name
}

# Create a Basic Cluster in that Environment
resource "confluent_kafka_cluster" "basic_cluster" {
  display_name         = var.cluster_name
  cloud               = var.cloud_provider
  region              = var.region
  availability        = "SINGLE_ZONE"
  environment {
    id =   confluent_environment.env.id
  } 
  basic { }    
}

