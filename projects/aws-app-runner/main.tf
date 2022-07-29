module "aws_ecr" {
  source          = "../../modules/ecr"
  image_repo_name = var.image_repo_name
}

module "aws_cicd" {
  source = "../../modules/cicd"
}

data "aws_caller_identity" "current" {}

# --------------------------------
# SSM Parameter for RDS Password
# --------------------------------
data "aws_ssm_parameter" "dbpassword" {
  #  name = "/database/password"
  name = var.ssm_parameter_store_name
}

# --------------------------------
# APP RUNNER IAM ROLES
# --------------------------------
module "apprunner_service_role" {
  source     = "../../modules/iam"
  name       = "${var.apprunner-service-role}AppRunnerECRAccessRole"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.apprunner-service-assume-policy.json
}

module "apprunner_instance_role" {
  source     = "../../modules/iam"
  name       = "${var.apprunner-service-role}AppRunnerInstanceRole"
  identifier = "tasks.apprunner.amazonaws.com"
  policy     = data.aws_iam_policy_document.apprunner-instance-assume-policy.json
}

data "aws_iam_policy_document" "apprunner-service-assume-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "apprunner-service-role-attachment" {
  role       = module.apprunner_service_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_policy" "Apprunner-policy" {
  name   = "Apprunner-getSSM"
  policy = data.aws_iam_policy_document.apprunner-instance-role-policy.json
}

resource "aws_iam_role_policy_attachment" "apprunner-instance-role-attachment" {
  role       = module.apprunner_instance_role.iam_role_name
  policy_arn = aws_iam_policy.Apprunner-policy.arn
}

data "aws_iam_policy_document" "apprunner-instance-assume-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "apprunner-instance-role-policy" {
  statement {
    actions   = ["ssm:GetParameter"]
    effect    = "Allow"
    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${data.aws_ssm_parameter.dbpassword.name}"
    ]
  }
}
