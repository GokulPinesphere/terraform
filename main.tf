provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "My-VPC-AWS-vpc" {
  cidr_block = "19.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.My-VPC-AWS-vpc.id

  tags = {
    Name = "my_igw"
  }
}

resource "aws_subnet" "subnet_az1" {
  vpc_id                  = aws_vpc.My-VPC-AWS-vpc.id
  cidr_block              = "19.0.16.0/20"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-az1"
  }
}

resource "aws_subnet" "subnet_az2" {
  vpc_id                  = aws_vpc.My-VPC-AWS-vpc.id
  cidr_block              = "19.0.128.0/20"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-az2"
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Security group for EC2 instances in the subnet"

  vpc_id = aws_vpc.My-VPC-AWS-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.instance_sg.id]
  subnets            = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]

  enable_deletion_protection = false


  tags = {
    Name = "my-alb"
  }
}

resource "aws_instance" "ec2_instance" {
  count = 2

  ami           = "ami-03f4878755434977f"

  instance_type = "t2.micro"
  key_name = "key-for-demo-1"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
subnet_id = aws_subnet.subnet_az1.id
provisioner "remote-exec" {
    inline = [ 
      "sudo apt update",
      "sudo apt install -y openjdk-11-jdk",  # Install OpenJDK 11
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"  // or the appropriate username for your AMI
    private_key = file("/home/ubuntu/key-for-demo-1")
    host        = self.public_ip
  }
  tags = {
    Name = "ec2-instance-${count.index + 1}"
  }
}

resource "aws_key_pair" "demo" {
  key_name = "key-for-demo-1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpXBXyniuB2vDjWjSAH5I9IvFtxyub4c28fR/a3hP77iWNVsITFLj75hYZAI3HHmflBRznAiCFUaLRjmUAvJLhAFtfcWhXYis8iYI7M75bJa9CC9PR+GqK4s5pO1t+Hw3AxbAAt8anZOeUwNT3ddoExIOZeWxvj7IbmcubLCDYcSM4+1ZgXhUc+mjK2Ac7VdHooysYpd70OZ8tP944XCN7h+T40aSyMaWJmyiIEMQ1Hhvreg24pu6MBtGYwyFEhFrrnA61KNzI5mxizO1JRF59b6Gchmwsb0O+tB8EIcaBgtj8I99mvl4TiMDQuEk4unwg1hm79KGNFBX67m0FR50T"
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.My-VPC-AWS-vpc.id
}

resource "aws_lb_target_group_attachment" "ec2_attachment" {
  count = 2

  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.ec2_instance[count.index].id
  port             = 80
}

output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}
