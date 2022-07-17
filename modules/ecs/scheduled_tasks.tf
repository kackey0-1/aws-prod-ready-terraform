resource "aws_cloudwatch_log_group" "for_ecs_scheduled_task" {
  name              = "/ecs-scheduled-tasks/example"
  retention_in_days = 180
}

resource "aws_ecs_task_definition" "example_batch" {
  container_definitions = "./json/batch_container_definitions.json"
  family                = "example-batch"
  cpu                   = "256"
  memory                = "516"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  ecs_execution_role_arn = module.ecs_execution_role.iam_role_arn
}

resource "aws_cloudwatch_event_rule" "example-batch" {
  name = "example-batch"
  description = "important batch process"
  schedule_expression = "cron(*/2 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "example-batch" {
  target_id = "example-batch"
  rule  = aws_cloudwatch_event_rule.example-batch.name
  role_arn = module.ecs_event_role.iam_role_arn
  arn = aws_ecs_cluster.hypo-driven.arn
}
