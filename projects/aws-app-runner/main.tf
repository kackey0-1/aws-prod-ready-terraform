module "aws_code_resources" {
  source                      = "../../modules/cicd/code"
  image_repo_name             = var.image_repo_name
  image_tag_mutability        = "MUTABLE"
  source_repo_name            = var.source_repo_name
  codebuild_cache_bucket_name = var.codebuild_cache_bucket_name
  aws_region                  = var.aws_region
  family                      = var.family
}

module "aws_cicd_for_master" {
  source             = "../../modules/cicd/pipeline"
  target_repo_branch = "master"
  source_repo_arn    = module.aws_code_resources.source_repo_arn
  source_repo_name   = module.aws_code_resources.source_repo_name
  codebuild          = module.aws_code_resources.codebuild
  artifact_bucket    = module.aws_code_resources.codebuild_s3.artifact_bucket
  cache_bucket       = module.aws_code_resources.codebuild_s3.cache_bucket
  aws_region         = var.aws_region
  depends_on         = [module.aws_code_resources]
}

module "aws_vpc" {
  source                     = "../../modules/internal-network/vpc"
  vpc_cidr                   = "10.0.0.0/16"
  public_subnet_cidr_az_a_0  = "10.0.1.0/24"
  public_subnet_cidr_az_c_0  = "10.0.2.0/24"
  private_subnet_cidr_az_a_0 = "10.0.65.0/24"
  private_subnet_cidr_az_c_0 = "10.0.66.0/24"
}

module "aws_rds" {
  source           = "../../modules/rds/single"
  vpc_id           = module.aws_vpc.vpc_id
  app_cidr_blocks  = ["10.0.1.0/24", "10.0.2.0/24"]
  db_subnet_groups = [
    module.aws_vpc.public_subnet_ids.public_subnet_0,
    module.aws_vpc.public_subnet_ids.public_subnet_1,
  ]
  db_instance_type = var.db_instance_type
  db_name          = var.db_name
  db_user          = var.db_user
  db_pass          = data.aws_ssm_parameter.dbpassword.value
  aws_region       = var.aws_region
  stack            = var.stack

  depends_on = [module.aws_vpc]
}

module "aws_apprunner" {
  source                  = "../../modules/apprunner"
  max_concurrency         = var.max_concurrency
  max_size                = var.max_size
  min_size                = var.min_size
  dbpassword              = data.aws_ssm_parameter.dbpassword
  apprunner-service-role  = var.apprunner-service-role
  container_port          = var.container_port
  aws_region              = var.aws_region
  db_user                 = var.db_user
  db_initialize_mode      = var.db_initialize_mode
  db_profile              = var.db_profile
  db_name                 = var.db_name
  aws_db_instance_address = module.aws_rds.aws_db_instance_address
  aws_ecr_repository_url = module.aws_code_resources.aws_ecr_repository_url

  depends_on = [module.aws_code_resources, module.aws_vpc, module.aws_rds]
}

# --------------------------------
# SSM Parameter for RDS Password
# --------------------------------
data "aws_ssm_parameter" "dbpassword" {
  #  name = "/database/password"
  name = var.ssm_parameter_store_name
}

