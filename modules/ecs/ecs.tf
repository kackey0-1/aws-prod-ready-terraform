variable "private_subnet_ids" {}
variable "hypo-driven_alb" {}
variable "vpc_id" {}
variable "vpc_cidr" {}

# cluster
resource "aws_ecs_cluster" "hypo-driven" {
  name = "hypo-driven"
}

# ecs_task
resource "aws_ecs_task_definition" "hypo-driven" {
  container_definitions    = file("./container_definitions.json")
  family                   = "hypo-driven"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}

# ecs_service
resource "aws_ecs_service" "hypo-driven" {
  name = "hypo-driven"
  cluster = aws_ecs_cluster.hypo-driven.arn
  task_definition = aws_ecs_task_definition.hypo-driven.arn
  desired_count = 2
  launch_type = "FARGATE"
  platform_version = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups = [module.nginx_sg.security_group_id]
    subnets = var.private_subnet_ids
  }

  load_balancer {
    target_group_arn = var.hypo-driven_alb.ypo-driven_alb_target_group_arn
    container_name = "hypo-driven"
    container_port = 0
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "nginx_sg" {
  source = "../internal-network/security_group"
  name = "nginx-sg"
  vpc_id = var.vpc_id
  port = 80
  cidr_blocks = var.vpc_cidr
}