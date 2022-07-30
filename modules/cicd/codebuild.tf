variable "codebuild_cache_bucket_name" {}
variable "aws_region" {}
variable "family" {}
# --------------------------------
# Code Build
# --------------------------------
data "aws_caller_identity" "current" {}

module "codebuild_execution_role" {
  source     = "../../modules/iam"
  name       = "codebuild-execution"
  identifier = "codebuild.amazonaws.com"
  policy     = aws_iam_policy.codebuild_policy.policy
}

resource "aws_iam_policy" "codebuild_policy" {
  description = "Policy to allow codebuild to execute build spec"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.artifact_bucket.arn}/*",
        "${aws_s3_bucket.cache.arn}/*"
      ]
    },
    {
      "Action": [
        "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability", "ecr:PutImage",
        "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_ecr_repository.image_repo.arn}"
    },
    {
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_ecr_repository.image_repo.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuild-attach" {
  role       = module.codepipeline_role.iam_role_arn
  policy_arn = aws_iam_policy.codebuild_policy.arn
}


# Codebuild project

resource "aws_s3_bucket" "cache" {
  # workaround from https://github.com/hashicorp/terraform-provider-aws/issues/10195
  bucket        = var.codebuild_cache_bucket_name
  # acl    = "private"
  force_destroy = true
}

resource "aws_codebuild_project" "codebuild" {
  depends_on = [
    aws_codecommit_repository.source_repo,
    aws_ecr_repository.default
  ]
  name         = "codebuild-${var.source_repo_name}-${var.source_repo_branch}"
  service_role = module.codepipeline_role.iam_role_arn
  artifacts {
    type = "CODEPIPELINE"
  }
  cache {
    type     = "S3"
    location = var.codebuild_cache_bucket_name
  }
  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "REPOSITORY_URI"
      value = data.aws_ecr_repository.image_repo.repository_url
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.family
    }
  }
  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.source_repo.clone_url_http
    git_clone_depth = 1
  }
}
