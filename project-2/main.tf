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

# Use route table association to associate subnet with route table.
resource "aws_route_table_association" {
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.prod-route-table.id
}


# create security group that allows access only to port 22,80,443
resource "aws_security_group" "allow_web" {
    name = "allow_web_traffic"
    description = "allow inbound traffic from the net"
    vpc_id = aws_vpc.prod-vpc.ic

    ingress {
        description = "HTTPS"
        # allow tcp traffic on port 443
        from_port = 443
        to_port = 443
        protocol = "tcp"
        # what subnets or ip addressed we want to allow to reach this port. in this case we want this open to the web
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        # allow tcp traffic also for http - which resides on port 80
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        # allow tcp traffic for ssh on port 22
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }    

    egress {
        # 0 = we are allowing all ports in the egress direction
        from_port = 0
        to_port = 0
        # -1 = all protocolos
        protocol = "-1"
        # = any ip address from the subnet can go in the egress direction
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "allow_web"
    }


    }