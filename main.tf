terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.60.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create VPC; CIDR 10.0.0.0/16
resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  enable_dns_support               = true
  tags = {
    "Name" = "${var.default_tags.env}-vpc"
  }
}

# Public Subnets 10.0.0.0/24
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${var.default_tags.env}-public-subnet-${data.aws_availability_zones.aws_availability_zone.names[count.index]}"
  }
  availability_zone = data.aws_availability_zones.aws_availability_zone.names[count.index]
}

# Private Subnets 10.0.0.0/24
resource "aws_subnet" "private" {
  count      = 2
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + var.public_subnet_count)
  tags = {
    "Name" = "${var.default_tags.env}-private-subnet-${data.aws_availability_zones.aws_availability_zone.names[count.index]}"
  }
  availability_zone = data.aws_availability_zones.aws_availability_zone.names[count.index]
}

# Public Route Tables
# Private Route Table
# IGW
# NGW
