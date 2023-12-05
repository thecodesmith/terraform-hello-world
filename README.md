# Terraform Demo

## Tasks

1. [x] Create an empty AWS account
2. [x] Create a public GitHub repo
3. [ ] Manually create a Terraform automation role in AWS with admin privileges, and an OIDC connector, which will be allowed to be assumed with OIDC web identity from your GitHub repo
4. [ ] Commit a Terraform GitHub workflow that can assume your automation role and plan/apply Terraform in automation
5. [ ] Deploy the following resources in your AWS account using only Terraform code:
   a. [ ] A multi region KMS CMK and replica
   b. [ ] A VPC with 2 public and 2 private subnets and a NAT gateway
   c. [ ] A publicly accessible "hello world" container in ECS Fargate fronted by a load balancer
   d. [ ] Bonus: Capture ECS/container log output to a CloudWatch log group which is encrypted with your CMK
