terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region   = "us-east-1"
    bucket   = "thecodesmith-demo-terraform-state"
    key      = "terraform.tfstate"
    profile  = ""
    role_arn = ""
    encrypt  = "true"

    dynamodb_table = "thecodesmith-demo-terraform-state-lock"
  }
}
