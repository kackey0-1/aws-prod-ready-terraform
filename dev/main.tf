module "aws_vpc" {
  source                     = "../modules/internal-network/vpc"
  vpc_cidr                   = "10.0.0.0/16"
  public_subnet_cidr_az_a_0  = "10.0.1.0/24"
  public_subnet_cidr_az_c_0  = "10.0.2.0/24"
  private_subnet_cidr_az_a_0 = "10.0.65.0/24"
  private_subnet_cidr_az_c_0 = "10.0.66.0/24"
}

module "aws_s3_bucket" {
  source = "../modules/s3"
}

module "aws_alb" {
  source                  = "../modules/external-network/alb"
  public_subnets          = module.aws_vpc.public_subnet_ids
  access_log_bucket_id    = module.aws_s3_bucket.access_log_bucket_id
  vpc_id                  = module.aws_vpc.vpc_id
  aws_hypo-driven_acm_arn = module.aws_acm.aws_hypo-driven_acm_arn
}

module "aws_route53" {
  source          = "../modules/external-network/route53"
  hypo-driven_alb = module.aws_alb.hypo-driven_alb
}

module "aws_acm" {
  source                      = "../modules/external-network/acm"
  hypo-driven_aws_domain_name = module.aws_route53.hypo-driven_aws_domain_name
  hypo-driven_aws_zone_id     = module.aws_route53.hypo-driven_aws_zone_id
}

module "aws_kms" {
  source      = "../modules/kms"
  name        = "alias/example"
  description = "Example Customer Master Key"
}

module "ecs_scheduled_batch" {
  source                      = "../modules/ecs/batch"
  hypo-driven_ecs_cluster_arn = ""
}

