variable "name" {}
variable "policy" {}
variable "identifier" {}

resource "aws_iam_role" "assume_default" {
  name = var.name
  assume_role_policy = var.policy
}

resource "aws_iam_policy" "default" {
  name = var.name
  policy = var.policy
}

resource "aws_iam_role_policy_attachment" "default" {
  policy_arn = aws_iam_policy.default.arn
  role = aws_iam_role.assume_default.name
}

output "iam_role_arn" {
  value = aws_iam_role.assume_default.arn
}

output "iam_role_name" {
  value = aws_iam_role.assume_default.name
}