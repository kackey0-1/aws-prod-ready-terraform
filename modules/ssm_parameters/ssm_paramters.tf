variable "db_username" {}

resource "aws_ssm_parameter" "db_username" {
  name  = "/db/username"
  type  = "String"
  value = var.db_username
  description = "database username"
}

resource "aws_ssm_parameter" "db_password" {
  # TODO you must update value after this resource is created by CLI
  #  By doing this, you can avoid that you have raw password in your code base
  #  ```bash
  #  aws ssm put-parameter --name '/db/password' --type SecureString --value 'VeryStrongPassword!' --overwrite
  #  ```
  name  = "/db/password"
  type  = "SecureString"
  value = "uninitialized"
  description = "database password"
  lifecycle {
    ignore_changes = [value]
  }
}

