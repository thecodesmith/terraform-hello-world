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

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "alb_tls_cert_arn" {
  type = string
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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "main"
  }
}

resource "aws_eip" "main" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_ecr_repository" "main" {
  name                 = "hello-world"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 3 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
    }]
  })
}

resource "aws_ecs_cluster" "main" {
  name = "main"
}

resource "aws_ecs_task_definition" "hello_world" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "hello-world"
  cpu                      = 256 # Fargate CPU units (1024 units = 1 vCPU)
  memory                   = 512 # MiB
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "hello-world"
    image     = "${var.container_image}:latest"
    essential = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
  }])
}

resource "aws_iam_role" "ecs_task_role" {
  name = "hello-world-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "hello-world-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "hello_world" {
  name                               = "hello-world"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.hello_world.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = "hello-world"
    container_port   = var.container_port
    target_group_arn = aws_lb_target_group.ecs.arn
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource "aws_lb" "public" {
  name               = "public-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_groups    = [aws_security_group.alb_public.id]
}

resource "aws_lb_target_group" "ecs" {
  name        = "ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    healthy_threshold   = "3"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.id
  protocol          = "HTTP"
  port              = 80

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = 443
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.public.id
  protocol          = "HTTPS"
  port              = 443

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.alb_tls_cert_arn

  default_action {
    target_group_arn = aws_lb_target_group.ecs.id
    type             = "forward"
  }
}

resource "aws_security_group" "alb_public" {
  name   = "alb-public"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "ecs-tasks"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol         = "tcp"
    from_port        = var.container_port
    to_port          = var.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
