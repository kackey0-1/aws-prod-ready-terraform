variable "target_repo_branch" {}
variable "source_repo_arn" {}
variable "source_repo_name" {}
variable "codebuild" {}
variable "artifact_bucket" {}
variable "cache_bucket" {}
variable "aws_region" {}

# --------------------------------
# Code Pipeline
# --------------------------------
module "codepipeline_role" {
  source     = "../../iam"
  name       = "codepipeline-execution"
  identifier = "codepipeline.amazonaws.com"
  policy     = aws_iam_policy.codepipeline_policy.policy
}

resource "aws_iam_policy" "codepipeline_policy" {
  description = "Policy to allow codepipeline to execute"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject",
        "s3:GetBucketVersioning"
      ],
      "Effect": "Allow",
      "Resource": "${var.artifact_bucket.arn}/*"
    },
    {
      "Action" : [
        "codebuild:StartBuild", "codebuild:BatchGetBuilds",
        "cloudformation:*",
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action" : [
        "ecs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action" : [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive"
      ],
      "Effect": "Allow",
      "Resource": "${var.source_repo_arn}"
    }
  ]
}
EOF
}

resource "aws_codepipeline" "pipeline" {
  name     = "${var.source_repo_name}-${var.target_repo_branch}-pipeline"
  role_arn = module.codepipeline_role.iam_role_arn
  artifact_store {
    location = var.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeCommit"
      output_artifacts = ["SourceOutput"]
      run_order        = 1
      configuration    = {
        RepositoryName       = var.source_repo_name
        BranchName           = var.target_repo_branch
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      run_order        = 2
      configuration    = {
        ProjectName = var.codebuild.id
      }
    }
  }
}

module "trigger_role" {
  source     = "../../iam"
  name       = "trigger-execution"
  identifier = "events.amazonaws.com"
  policy     = aws_iam_policy.trigger_policy.policy
}

resource "aws_iam_policy" "trigger_policy" {
  description = "Policy to allow rule to invoke pipeline"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codepipeline:StartPipelineExecution"
      ],
      "Effect": "Allow",
      "Resource": "${aws_codepipeline.pipeline.arn}"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_event_rule" "trigger_rule" {
  description   = "Trigger the pipeline on change to repo/branch"
  event_pattern = <<PATTERN
{
  "source": [ "aws.codecommit" ],
  "detail-type": [ "CodeCommit Repository State Change" ],
  "resources": [ "${var.source_repo_arn}" ],
  "detail": {
    "event": [ "referenceCreated", "referenceUpdated" ],
    "referenceType": [ "branch" ],
    "referenceName": [ "${var.target_repo_branch}" ]
  }
}
PATTERN
  role_arn      = module.trigger_role.iam_role_arn
  is_enabled    = true
}

resource "aws_cloudwatch_event_target" "target_pipeline" {
  rule      = aws_cloudwatch_event_rule.trigger_rule.name
  arn       = aws_codepipeline.pipeline.arn
  role_arn  = module.trigger_role.iam_role_arn
  target_id = "${var.source_repo_name}-${var.target_repo_branch}-pipeline"
}

output "pipeline_url" {
  value = "https://console.aws.amazon.com/codepipeline/home?region=${var.aws_region}#/view/${aws_codepipeline.pipeline.id}"
}
