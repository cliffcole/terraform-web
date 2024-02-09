provider "aws" {
  region  = var.region
  profile = "default"
}

terraform {
  backend "s3" {
    bucket  = "terraform-state-ccole"
    region  = "us-east-1"
    key     = "dev/terraform.tfstate"
    profile = "default"
  }
}