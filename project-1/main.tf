provider "aws" {
    region = "us-east-1"
    access_key = "AKIASDLDL4PYSSXUK2F2"
    secret_key = "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"
}

# create aws vpc
resource "aws_vpc" "first-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production"
    }
}

# create subnet within above vpc
resource "aws_subnet" "subnet-1" {
    # for the vpc where we want to create the subnet, we reffer to the id of the vpc
    vpc_id = aws_vpc.first-vpc.id
    cidr_block = "10.0.1.0/24"
    tags = {
        Name = "prod-subnet"
    }
}

resource "aws_vpc" "second-vpc" {
    cidr_block = "10.1.0.0/16"
    tags = {
        Name = "Dev"
    }
}

resource "aws_subnet" "subnet-2" {
    # for the vpc where we want to create the subnet, we reffer to the id of the vpc
    vpc_id = aws_vpc.second-vpc.id
    cidr_block = "10.1.1.0/24"
    tags = {
        Name = "dev-subnet"
    }
}



# create aws ec2 ubuntu22 server 
# resource "aws_instance" "server-1" {
#     # changes with the region for same service
#     ami = "ami-053b0d53c279acc90"
#     instance_type = "t2.micro"
#     tags = {
#        # Name = "ubuntu"
#     }
# }
