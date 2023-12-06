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
