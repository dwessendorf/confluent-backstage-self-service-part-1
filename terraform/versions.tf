terraform {
  required_version = ">= 1.2.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 1.33"
    }
  }
}