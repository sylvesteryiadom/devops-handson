# # vpc resource
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

# subnet module reference

module "myapp-subnet" {
  source                 = "./modules/subnet"
  vpc_id                 = aws_vpc.myapp-vpc.id
  subnet_cidr_block      = var.subnet_cidr_block
  avail_zone             = var.avail_zone
  env_prefix             = var.env_prefix
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

module "myapp-server" {
  source            = "./modules/webserver"
  vpc_id            = aws_vpc.myapp-vpc.id
  my_ip             = var.my_ip
  env_prefix        = var.env_prefix
  instance_type     = var.instance_type
  subnet_id         = module.myapp-subnet.subnet-1.id
  avail_zone        = var.avail_zone
  vpc_cidr_block    = var.vpc_cidr_block
  subnet_cidr_block = var.subnet_cidr_block
}



