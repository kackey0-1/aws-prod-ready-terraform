variable "dbpassword" {}
variable "apprunner-service-role" {}
variable "container_port" {}
variable "aws_region" {}
variable "db_user" {}
variable "db_initialize_mode" {}
variable "db_profile" {}
variable "db_name" {}
variable "aws_db_instance_address" {}
variable "aws_ecr_repository_url" {}
# --------------------------------
# APPRUNNER Service
# --------------------------------
data "aws_caller_identity" "current" {}
resource "aws_apprunner_service" "service" {
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.auto-scaling-config.arn
  service_name                   = "apprunner-${var.apprunner-service-role}"
  source_configuration {
    authentication_configuration {
      access_role_arn = module.apprunner_service_role.iam_role_arn
    }
    image_repository {
      image_configuration {
        port                          = var.container_port
        runtime_environment_variables = {
          "AWS_REGION" : var.aws_region,
          "spring.datasource.username" : var.db_user,
          "spring.datasource.initialization-mode" : var.db_initialize_mode,
          "spring.profiles.active" : var.db_profile,
          "spring.datasource.url" : "jdbc:mysql://${var.aws_db_instance_address}/${var.db_name}"
        }
      }
      image_identifier      = "${var.aws_ecr_repository_url}:master-cd41ee8"
      image_repository_type = "ECR"
    }
  }
  instance_configuration {
    instance_role_arn = module.apprunner_instance_role.iam_role_arn
  }
  depends_on = [
    module.apprunner_service_role,
  ]
}

# --------------------------------
# APP RUNNER IAM ROLES
# --------------------------------
module "apprunner_service_role" {
  source     = "../../modules/iam"
  name       = "${var.apprunner-service-role}AppRunnerECRAccessRole"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = aws_iam_policy.apprunner-policy.policy
}

module "apprunner_instance_role" {
  source     = "../../modules/iam"
  name       = "${var.apprunner-service-role}AppRunnerInstanceRole"
  identifier = "tasks.apprunner.amazonaws.com"
  policy     = data.aws_iam_policy_document.apprunner-instance-role-policy.json
}

resource "aws_iam_role_policy_attachment" "apprunner-service-role-attachment" {
  role       = module.apprunner_service_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_policy" "apprunner-policy" {
  name   = "apprunner-getSSM"
  policy = data.aws_iam_policy_document.apprunner-instance-role-policy.json
}

data "aws_iam_policy_document" "apprunner-instance-role-policy" {
  statement {
    actions   = ["ssm:GetParameter"]
    effect    = "Allow"
    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${var.dbpassword.name}"
    ]
  }
}

output "apprunner_service_url" {
  value = "https://${aws_apprunner_service.service.service_url}"
}
