terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.60.0"
    }
  }
  # bucket must be hardcoded
  backend "s3" {
    bucket = "vo-tf-bucket"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create VPC; CIDR 10.0.0.0/16
resource "aws_vpc" "main" {
  cidr_block                       = var.vpc_cidr
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  enable_dns_support               = true
  tags = {
    "Name" = "${var.default_tags.env}-vpc"
  }
}

# Public Subnets 10.0.0.0/24
resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
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
  count      = var.private_subnet_count
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + var.public_subnet_count)
  tags = {
    "Name" = "${var.default_tags.env}-private-subnet-${data.aws_availability_zones.aws_availability_zone.names[count.index]}"
  }
  availability_zone = data.aws_availability_zones.aws_availability_zone.names[count.index]
}

# IGW
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id #Attachment
  tags = {
    "Name" = "${var.default_tags.env}-igw"
  }
}

# NGW
resource "aws_nat_gateway" "main_NAT" {
  allocation_id = aws_eip.NAT_EIP.id
  subnet_id     = aws_subnet.public.0.id
  tags = {
    "Name" = "${var.default_tags.env}-ngw"
  }
}
# EIP
resource "aws_eip" "NAT_EIP" {
  vpc = true
}
# Public Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.default_tags.env}-public-rt"
  }
}

# Public Routes - for route table
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.default_tags.env}-private-rt"
  }
}

# Private Routes - for route table
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_NAT.id
}

# Private Routes Table Association
resource "aws_route_table_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}