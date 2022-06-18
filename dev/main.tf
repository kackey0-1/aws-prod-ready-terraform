module "aws_vpc" {
  source = "../modules/vpc"
}

module "aws_sg" {
  source = "../modules/security_group"
  name = "module-sg"
  vpc_id = module.aws_vpc
  port = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "aws_s3_bucket" {
  source = "../modules/s3"
}

module "describe_regions_for_ec2" {
  source = "../modules/iam"
  name = "describe_regions_for_ec2"
  identifier = "ec2.amazonaws.com"
  policy = data.aws_iam_policy_document.allow_describe_regions.json
}

data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect = "Allow"
    actions = ["ec2:DescribeRegions"] # リージョン一覧を取得する
    resources = ["*"]
  }
}