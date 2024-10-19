
# Security Group for EC2 Instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Security group for EC2 instance"
  vpc_id      = module.vpc.vpc_id

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
    cidr_blocks = [module.vpc.vpc_cidr_block]
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

resource "aws_instance" "my_instance" {
  ami             = "ami-0866a3c8686eaeeba" # Ubuntu 24.04 LTS
  instance_type   = "t2.micro"
  key_name	  = "sjr"
  iam_instance_profile = aws_iam_instance_profile.ec2allprofile.name
  #key_name        = aws_key_pair.ssh_keypair.key_name
  subnet_id       = module.vpc.public_subnets[0]
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
