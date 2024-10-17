provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "my_vpc"
  }
}

# Subnets (Public)
resource "aws_subnet" "my_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "my_subnet"
  }
}
# Subnet in us-east-1b (private)
resource "aws_subnet" "subnet_us_east_1b_private" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false  # Private subnet

  tags = {
    Name = "subnet_us_east_1b_private"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

# Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "my_subnet_association" {
  subnet_id      = aws_subnet.my_subnet_1.id
  route_table_id = aws_route_table.my_route_table.id
}
# Security Group for EC2 Instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   }
}
#resource "aws_key_pair" "ssh_keypair" {
#key_name   = "sjr"  # Replace with your desired key pair name
#public_key = file("~/.ssh/id_rsa.pub")  # Replace with the path to your public key file
#}
 # EC2 Instance
resource "aws_instance" "my_instance" {
  ami             = "ami-0866a3c8686eaeeba" # Ubuntu 24.04 LTS
  instance_type   = "t2.micro"
  key_name	  = "sjr"
  #key_name        = aws_key_pair.ssh_keypair.key_name
  subnet_id       = aws_subnet.my_subnet_1.id
  security_groups  = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install gnupg curl
              curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
              gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
              --dearmor
              echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
              apt-get update
              sudo apt-get install -y mongodb-org
              systemctl start mongod
              systemctl enable mongodb
              EOF
 tags = {
    Name = "my-mongodb"

 }
}
