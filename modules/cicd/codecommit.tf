variable "source_repo_name" {}
variable "source_repo_branch" {}
# ---------------------------------------------------------------------------------------------------------------------
# Code Commit
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_codecommit_repository" "source_repo" {
    repository_name = var.source_repo_name
    description     = "This is the app source repository"
}

module "trigger_role" {
  source     = "../../modules/iam"
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
  "resources": [ "${aws_codecommit_repository.source_repo.arn}" ],
  "detail": {
    "event": [ "referenceCreated", "referenceUpdated" ],
    "referenceType": [ "branch" ],
    "referenceName": [ "${var.source_repo_branch}" ]
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
    target_id = "${var.source_repo_name}-${var.source_repo_branch}-pipeline"
}

output "source_repo_clone_url_http" {
    value = aws_codecommit_repository.source_repo.clone_url_http
}
