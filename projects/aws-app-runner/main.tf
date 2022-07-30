module "aws_cicd" {
  source                      = "../../modules/cicd"
  codebuild_cache_bucket_name = var.codebuild_cache_bucket_name
  aws_region                  = var.aws_region
  family                      = var.family
  source_repo_name            = var.source_repo_name
  source_repo_branch          = var.source_repo_branch
  image_repo_name = var.image_repo_name
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
  policy     = aws_iam_policy.apprunner-policy.policy
}

module "apprunner_instance_role" {
  source     = "../../modules/iam"
  name       = "${var.apprunner-service-role}AppRunnerInstanceRole"
  identifier = "tasks.apprunner.amazonaws.com"
  policy     = data.aws_iam_policy_document.apprunner-instance-role-policy.json
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

resource "aws_iam_policy" "apprunner-policy" {
  name   = "apprunner-getSSM"
  policy = data.aws_iam_policy_document.apprunner-instance-role-policy.json
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
