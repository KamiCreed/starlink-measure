terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.73"
    }
  }
}


provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*20*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

resource "aws_default_vpc" "vpc" {
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_default_subnet" "subnet_public" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_security_group" "allow_iperf3" {
  name   = "allow_iperf3"
  vpc_id = aws_default_vpc.vpc.id

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5201
    to_port     = 5202
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5201
    to_port     = 5202
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data" {
  template = file("../scripts/run-iperf3.yaml")

  vars = {
    region = var.region
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_default_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.allow_iperf3.id]
  associate_public_ip_address = true
  user_data                   = data.template_file.user_data.rendered

  tags = {
    Name = "iperf3-server"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
output "region_name" {
  value = data.aws_region.current.description
}
