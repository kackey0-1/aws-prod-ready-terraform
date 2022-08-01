module "aws_vpc" {
  source                     = "../modules/internal-network/vpc"
  vpc_cidr                   = "10.0.0.0/16"
  public_subnet_cidr_az_a_0  = "10.0.1.0/24"
  public_subnet_cidr_az_c_0  = "10.0.2.0/24"
  private_subnet_cidr_az_a_0 = "10.0.65.0/24"
  private_subnet_cidr_az_c_0 = "10.0.66.0/24"
}

module "http_sg" {
  source      = "../modules/internal-network/security_group"
  name        = "http_sg"
  vpc_id      = module.aws_vpc.vpc_id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "../modules/internal-network/security_group"
  name        = "https_sg"
  vpc_id      = module.aws_vpc.vpc_id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "../modules/internal-network/security_group"
  name        = "http_redirect_sg"
  vpc_id      = module.aws_vpc.vpc_id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

module "aws_s3_bucket" {
  source = "../modules/s3"
}

module "aws_alb" {
  source               = "../modules/external-network/alb"
  public_subnets       = module.aws_vpc.public_subnet_ids
  access_log_bucket_id = module.aws_s3_bucket.access_log_bucket_id
  alb_security_groups  = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id
  ]
  aws_hypo-driven_acm_arn = module.aws_acm.aws_hypo-driven_acm_arn
  vpc_id = module.aws_vpc.vpc_id
  # TODO add dependency
  # depends_on = [module.aws_acm]
}

module "aws_route53" {
  source          = "../modules/external-network/route53"
  hypo-driven_alb = module.aws_alb.hypo-driven_alb
}

module "aws_acm" {
  source = "../modules/external-network/acm"
  hypo-driven_aws_domain_name = module.aws_route53.hypo-driven_aws_domain_name
  hypo-driven_aws_zone_id = module.aws_route53.hypo-driven_aws_zone_id
}

module "aws_kms" {
  source      = "../modules/kms"
  name        = "alias/example"
  description = "Example Customer Master Key"
}

module "aws_ecs" {
  source      = "../modules/ecs"
  private_subnet_ids = module.aws_vpc.private_subnet_ids
  hypo-driven_alb = module.aws_alb.hypo-driven_alb
  vpc_id = module.aws_vpc.vpc_id
  vpc_cidr = module.aws_vpc.vpc_cidr
}

module "ecs_scheduled_batch" {
  source                      = "../modules/ecs/batch"
  hypo-driven_ecs_cluster_arn = ""
}

