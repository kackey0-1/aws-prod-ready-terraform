terraform {
  backend "s3" {
    bucket = "dev-env-terraform"
    region = "ap-northeast-1"
    key    = "dev-env-terraform.tfstate"
  }
}
