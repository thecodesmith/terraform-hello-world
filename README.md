# Terraform Demo

## Tasks

- [x] Create an empty AWS account
- [x] Create a public GitHub repo
- [x] Manually create a Terraform automation role in AWS with admin privileges, and an OIDC connector, which will be allowed to be assumed with OIDC web identity from your GitHub repo
- [x] Commit a Terraform GitHub workflow that can assume your automation role and plan/apply Terraform in automation
- [ ] Deploy the following resources in your AWS account using only Terraform code:
   - [ ] A multi region KMS CMK and replica
   - [ ] A VPC with 2 public and 2 private subnets and a NAT gateway
   - [ ] A publicly accessible "hello world" container in ECS Fargate fronted by a load balancer
   - [ ] Bonus: Capture ECS/container log output to a CloudWatch log group which is encrypted with your CMK

## Details

### Terraform AWS state backend

This project uses the [terraform-aws-tfstate-backend](https://github.com/cloudposse/terraform-aws-tfstate-backend) from Cloud Posse to manage backend state in an S3 bucket. See the README there for details on usage, to initialize this project from scratch, or to tear down the state backend resources.
