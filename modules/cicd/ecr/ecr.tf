variable "image_repo_name" {}
variable "image_tag_mutability" {}

resource "aws_ecr_repository" "default" {
  name                 = var.image_repo_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }
}
data "aws_ecr_repository" "image_repo" {
  name = var.image_repo_name

  depends_on = [
    aws_ecr_repository.default
  ]
}
