variable "source_repo_name" {}
# --------------------------------
# Code Commit
# --------------------------------
resource "aws_codecommit_repository" "source_repo" {
  repository_name = var.source_repo_name
  description     = "This is the app source repository"
}

output "source_repo_arn" {
  value = aws_codecommit_repository.source_repo.arn
}

output "source_repo_name" {
  value = aws_codecommit_repository.source_repo.arn
}
