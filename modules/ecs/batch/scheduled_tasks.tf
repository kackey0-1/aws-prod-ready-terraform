variable "hypo-driven_ecs_cluster_arn" {}

resource "aws_cloudwatch_log_group" "for_ecs_scheduled_task" {
  name              = "/ecs-scheduled-tasks/example"
  retention_in_days = 180
}

resource "aws_ecs_task_definition" "example_batch" {
  container_definitions    = "./json/batch_container_definitions.json"
  family                   = "example-batch"
  cpu                      = "256"
  memory                   = "516"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  ecs_execution_role_arn   = module.ecs_batch_execution_role.iam_role_arn
}

resource "aws_cloudwatch_event_rule" "example-batch" {
  name                = "example-batch"
  description         = "important batch process"
  schedule_expression = "cron(*/2 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "example-batch" {
  target_id = "example-batch"
  rule      = aws_cloudwatch_event_rule.example-batch.name
  role_arn  = module.ecs_batch_event_role.iam_role_arn
  arn       = hypo-driven_ecs_cluster_arn
}

# ---------------------
# IAM ROLES
# ---------------------
module "ecs_batch_execution_role" {
  source     = "../../iam"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

module "ecs_batch_event_role" {
  source     = "../../iam"
  name       = "ecs-events"
  identifier = "events.amazonaws.com"
  policy     = data.aws_iam_policy.ecs_event_role_policy.policy
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_policy_documents = [data.aws_iam_policy.ecs_task_execution_role_policy.policy]
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

data "aws_iam_policy" "ecs_event_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

