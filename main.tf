provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "cloudposse/vpc/aws"
  version    = "0.25.0"
  cidr_block = "172.16.0.0/16"

  context = module.this.context
}

module "subnets" {
  source               = "cloudposse/dynamic-subnets/aws"
  version              = "0.39.0"
  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false

  context = module.this.context
}

module "ec2_instance_group" {
  source                        = "cloudposse/ec2-instance-group/aws"
  version                       = "0.11.6"
  region                        = var.region
  ami                           = var.ami
  ami_owner                     = var.ami_owner
  vpc_id                        = module.vpc.vpc_id
  subnet                        = module.subnets.public_subnet_ids[0]
  security_groups               = [module.vpc.vpc_default_security_group_id, aws_security_group.we_are_all_happy.id]
  assign_eip_address            = var.assign_eip_address
  associate_public_ip_address   = var.associate_public_ip_address
  instance_type                 = var.instance_type
  instance_count                = var.instance_count
  allowed_ports                 = var.allowed_ports
  create_default_security_group = var.create_default_security_group
  generate_ssh_key_pair         = var.generate_ssh_key_pair
  root_volume_type              = var.root_volume_type
  root_volume_size              = var.root_volume_size
  delete_on_termination         = var.delete_on_termination

  context = module.this.context
}

resource "aws_security_group" "we_are_all_happy" {
  name = "we-are-all-happy"
  vpc_id = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "we_are_all_happy" {
  security_group_id = aws_security_group.we_are_all_happy.id
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}