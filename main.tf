# Follow the bootstrapping procedure here to set up the state backend the first time:
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage
module "terraform_state_backend" {
  source           = "cloudposse/tfstate-backend/aws"
  version          = "1.3.0"
  namespace        = "thecodesmith"
  stage            = "demo"
  name             = "terraform"
  attributes       = ["state"]
  role_arn         = "arn:aws:iam::103437585953:role/terraform"
  dynamodb_enabled = false

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# US East (N. Virginia) region
provider "aws" {
  region = "us-east-1"
}

# Europe (Frankfurt) region
provider "aws" {
  region = "eu-central-1"
  alias  = "secondary"
}

resource "aws_kms_key" "primary" {
  description         = "Primary US region CMK for encrypting CloudWatch logs"
  multi_region        = true
  enable_key_rotation = true
}

resource "aws_kms_replica_key" "replica" {
  provider                = aws.secondary
  description             = "EU multi-region replica key for encrypting CloudWatch logs"
  primary_key_arn         = aws_kms_key.primary.arn
  deletion_window_in_days = 7
}
