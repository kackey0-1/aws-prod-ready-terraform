module "aws_code_resources" {
  source                      = "../../modules/cicd/code"
  image_repo_name             = var.image_repo_name
  image_tag_mutability        = "MUTABLE"
  source_repo_name            = var.source_repo_name
  codebuild_cache_bucket_name = var.codebuild_cache_bucket_name
  aws_region                  = var.aws_region
  family                      = var.family
}

module "aws_cicd_for_master" {
  source             = "../../modules/cicd/pipeline"
  target_repo_branch = "master"
  source_repo_arn    = module.aws_code_resources.source_repo_arn
  source_repo_name   = module.aws_code_resources.source_repo_name
  codebuild          = module.aws_code_resources.codebuild
  artifact_bucket    = module.aws_code_resources.codebuild_s3.artifact_bucket
  cache_bucket       = module.aws_code_resources.codebuild_s3.cache_bucket
  aws_region         = var.aws_region
  depends_on         = [module.aws_code_resources]
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
