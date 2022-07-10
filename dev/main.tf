module "aws_vpc" {
  source = "../modules/vpc"
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidr_az_a_0 = "10.0.1.0/24"
  public_subnet_cidr_az_c_0 = "10.0.2.0/24"
  private_subnet_cidr_az_a_0 = "10.0.65.0/24"
  private_subnet_cidr_az_c_0 = "10.0.66.0/24"
}

module "aws_sg" {
  source = "../modules/security_group"
  name = "module_sg"
  vpc_id = module.aws_vpc.vpc_id
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