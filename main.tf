terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}

#####################
# VARIABLES
#####################
variable "uri_img" {
  type        = string
  description = "La URI de la imagen Docker para el contenedor"
}

variable "ecs_service_name" {
  type        = string
  description = "Nombre del servicio ECS"
}

#####################
# DATOS VPC + SUBREDES
#####################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_route_tables" "default_rtb" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#####################
# CLOUDWATCH LOG GROUP
#####################
resource "aws_cloudwatch_log_group" "nagios_log_group" {
  name              = "/ecs/nagios"
  retention_in_days = 7
}

#####################
# VPC ENDPOINTS (ECR + S3 + CloudWatch)
#####################

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.default.ids
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.default.ids
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.default_rtb.ids
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.default.ids
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
}

#####################
# SECURITY GROUPS
#####################

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "tasks_sg" {
  name        = "tasks-sg"
  description = "Allow traffic from ALB SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS from tasks-sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-sg"
  description = "Allow ECS tasks to access VPC endpoints"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#####################
# EFS + Access Point
#####################

resource "aws_efs_file_system" "nagios_efs" {
  encrypted = true
  tags = {
    Name = "nagios-efs"
  }
}

resource "aws_efs_mount_target" "efs_mount" {
  for_each       = toset(data.aws_subnets.default.ids)
  file_system_id = aws_efs_file_system.nagios_efs.id
  subnet_id      = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_access_point" "efs_ap" {
  file_system_id = aws_efs_file_system.nagios_efs.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/usr/local/nagios/var"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

#####################
# ECS CLUSTER
#####################

resource "aws_ecs_cluster" "ea2_cluster" {
  name = "ea2-cluster"
}

#####################
# ECS TASK DEFINITION
#####################

data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "nagios_task" {
  family                   = "prueba2-tareas"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  ephemeral_storage {
    size_in_gib = 21
  }

  container_definitions = jsonencode([
    {
      name      = "nagios-ea2"
      image     = var.uri_img
      cpu       = 1024
      memory    = 3072
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.nagios_log_group.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "nagios"
        }
      }
      mountPoints = [
        {
          containerPath = "/usr/local/nagios/var"
          sourceVolume  = "efs-volume"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name = "efs-volume"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.nagios_efs.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.efs_ap.id
        iam             = "ENABLED"
      }
    }
  }
}

#####################
# LOAD BALANCER
#####################

resource "aws_lb" "nagios_alb" {
  name               = "nagios-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "tg" {
  name        = "nagios-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nagios_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

#####################
# ECS SERVICE
#####################

resource "aws_ecs_service" "nagios_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ea2_cluster.id
  task_definition = aws_ecs_task_definition.nagios_task.arn
  desired_count   = 1
  platform_version = "LATEST"

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "nagios-ea2"
    container_port   = 80
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 1
  }

  depends_on = [
    aws_lb_listener.http
  ]
}