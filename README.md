# Terraform Demo

This project demonstrates deploying AWS infrastructure as code with Terraform and GitHub Actions.

## Status

- [![Publish image to ECR](https://github.com/thecodesmith/terraform-demo/actions/workflows/build-image.yaml/badge.svg)](https://github.com/thecodesmith/terraform-demo/actions/workflows/build-image.yaml)
- [![Deploy Terraform](https://github.com/thecodesmith/terraform-demo/actions/workflows/deploy.yaml/badge.svg)](https://github.com/thecodesmith/terraform-demo/actions/workflows/deploy.yaml)

## Tasks

- [x] Create an empty AWS account
- [x] Create a public GitHub repo
- [x] Manually create a Terraform automation role in AWS with admin privileges, and an OIDC connector, which will be allowed to be assumed with OIDC web identity from your GitHub repo
- [x] Commit a Terraform GitHub workflow that can assume your automation role and plan/apply Terraform in automation
- [x] Deploy the following resources in your AWS account using only Terraform code:
   - [x] A multi region KMS CMK and replica
   - [x] A VPC with 2 public and 2 private subnets and a NAT gateway
   - [x] A publicly accessible "hello world" container in ECS Fargate fronted by a load balancer
   - [x] Bonus: Capture ECS/container log output to a CloudWatch log group which is encrypted with your CMK

## Development

To initialize Terraform locally for the first time on a new machine, run:

    terraform init

Note that Terraform is using an S3 bucket to store backend state so it is portable across machines.

To view changes between the Terraform configuration and the actual resource state, run:

    terraform plan

To apply changes from the configuration, run:

    terraform apply

## Reference

### Terraform AWS state backend

This project uses the [terraform-aws-tfstate-backend](https://github.com/cloudposse/terraform-aws-tfstate-backend) from Cloud Posse to manage backend state in an S3 bucket. See the README there for details on usage, to initialize this project from scratch, or to tear down the state backend resources.

### AWS docs

- https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html
- https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html
- https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html
