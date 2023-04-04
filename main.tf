// always avoid to use default resources/components
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    "Name" = "${var.env_prefix}-vpc"
  }
}

module "myapp-subnet" {
  source            = "./modules/subnet"
  env_prefix        = var.env_prefix
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone        = var.avail_zone
  vpc_id            = aws_vpc.myapp-vpc.id
}

module "myapp-webserver" {
  source              = "./modules/webserver"
  vpc_id              = aws_vpc.myapp-vpc.id
  my_ip               = var.my_ip
  env_prefix          = var.env_prefix
  ami_name            = var.ami_name
  public_key_location = var.public_key_location
  instance_type       = var.instance_type
  subnet_id           = module.myapp-subnet.subnet.id
  avail_zone          = var.avail_zone
}