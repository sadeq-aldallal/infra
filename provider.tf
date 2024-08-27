provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key 
}

provider "aws" {
  alias      = "vir"
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}


terraform {
  required_version = "~> 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.43.0"
    }
  }
}

