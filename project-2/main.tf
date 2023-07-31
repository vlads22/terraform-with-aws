provider "aws" {
    region = "us-east-1"
    access_key = "AKIASDLDL4PYSSXUK2F2"
    secret_key = "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"
}

# create vpc
resource "aws-vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production"
    }
}

# create internet gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = aws-vpc.prod-vpc.id
}

# Create route table
resource "aws_route_table" "prod-route-table" {
    vpc_id = aws-vpc.prod-vpc.id
    
    route {
        # all traffic from the vpc (0.0.0...) will go out to the internet using the internet gateway
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        egress_only_gateway_id = aws_internet_gatewasy.gw.id
    }

    tags = {
        Name = "prod"
    }
}

# Create subnet where the webserver will reside.
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.ic
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "prod-subnet"
  }
}

# Use route table association to assign subnet to route table.
