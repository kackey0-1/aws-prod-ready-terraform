terraform {
  required_providers {
    # aws = {
    #  source  = "hashicorp/aws"
    #  version = "3.39.0"
    # }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

