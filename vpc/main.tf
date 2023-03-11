provider "aws" {
  region = "us-east-1"
}


variable "app_count" {
  type = number
  default = 1
}


data "aws_availability_zones" "available_zones" {
  state = "available"
}


terraform {
  backend "s3" {
    bucket = "drohealth-tf-state"
    key = "vpc/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "test_EHR_tf_lock_db"
  }
}


resource "aws_vpc" "Drohealth_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    "Name" = "Drohealth_vpc"
  }
}


resource "aws_subnet" "DroHealth_subnet" {
  count = 2
  vpc_id                  = aws_vpc.Drohealth_vpc.id
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.Drohealth_vpc.cidr_block, 8, 2 + count.index)
  map_public_ip_on_launch = true
}


resource "aws_internet_gateway" "DroHealth_igw" {
  vpc_id = aws_vpc.Drohealth_vpc.id
  tags = {
    "Name" = "DroHealth_igw"
  }
}


resource "aws_route_table" "DroHealth_route_table" {
  vpc_id = aws_vpc.Drohealth_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.DroHealth_igw.id
  }
}


resource "aws_route_table_association" "DroHealth_rt_a" {
  count = 2
  subnet_id      = element(aws_subnet.DroHealth_subnet.*.id, count.index)
  route_table_id = aws_route_table.DroHealth_route_table.id
}

