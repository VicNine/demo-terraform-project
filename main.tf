# terraform {
#   required_version = ">= 0.12"
#   backend "s3" {
#     bucket = "myapp-bucket"
#     key = "myapp/state.tfstate"
#     region = "ap-southeast-4"    
#   }
# }

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.env-prefix}-vpc"     # <= vpc "Name" tag
  cidr = var.vpc_cidr_block

  # Default six subnet => 2 per az
  azs             = ["ap-southeast-4a", "ap-southeast-4b", "ap-southeast-4c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # azs            = [var.avail_zone]
  # public_subnets = [var.subnet_cidr_block]
  # public_subnet_tags = {
  #   Name = "${var.env_prefix}-subnet-1"
  # }

  tags = {
    # Name        = "${var.env_prefix}-vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

module "myapp-webserver" {
  source = "./modules/webserver"

  vpc_id     = module.vpc.vpc_id
  subnet_id  = module.vpc.public_subnets[0]
  avail_zone = var.avail_zone

  my_ip      = var.my_ip
  env_prefix = var.env_prefix

  ami_name            = var.ami_name
  public_key_location = var.public_key_location
  instance_type       = var.instance_type
}
