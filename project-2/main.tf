provider "aws" {
    region = "us-east-1"
    access_key = "......"
    secret_key = "......."
}

# create vpc
resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production"
    }
}

# create internet gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.prod-vpc.id
}

# Create route table
resource "aws_route_table" "prod-route-table" {
    vpc_id = aws_vpc.prod-vpc.id
    
    route {
        # all traffic from the vpc (0.0.0...) will go out to the internet using the internet gateway
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        # the default route for the ipv6 is going through this aws gateway
        gateway_id = aws_internet_gateway.gw.id
    }

    tags = {
        Name = "prod"
    }
}

# Create subnet where the webserver will reside.
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
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

# network interface that creates a private ip address for the EC2 host through which it can communicate with the VPC and the internet
resource "aws_network_interface" "web_server_nic" {
    # the interface must be asociated with a subnet in order to determine the ip address range that can be used
    subnet_id = aws_subnet.subnet-1.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.allow_web.id]
}

# assign a public ip address for the host so that it can be accessed from the internet
# we use an elastic ip that we assign to the newly created network interface

resource "aws_eip" "one" {
    vpc = true
    network_interface = aws_network_interface.web_server_nic.id
    associate_with_private_ip = "10.0.1.50"
    # we deploy the EIP only after deploying the internet gateway
    depends_on = [aws_internet_gateway.gw]
}

# create the Ubuntu server
resource "aws_instance" "web-server-instance" {
    # the ami for the Ubuntu Server 18.04LTS on aws
    ami = "ami-085925f297f89fce1"
    instance_type = "t2.micro"
    # same availability zone as for the subnet. hard coded in order not to get random zone
    availability_zone = "us-east-1a"
    # key pair set in aws
    key_name = "main-key"
    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web_server_nic.id
    }

    # run commands on the server in order to install apache 
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo the web server > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server"
    }
}

# at this point run: terraform apply
    # use ip address from the ubuntu ec2 instance