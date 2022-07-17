variable "name" {}
variable "description" {}

resource "aws_kms_key" "default" {
  description             = var.description
  enable_key_rotation     = true
  is_enabled              = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "default" {
  name          = var.name
  target_key_id = aws_kms_key.default.id
}