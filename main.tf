provider "aws" {
  region = "ap-south-1"
}

resource "aws_key_pair" "demo" {
  key_name = "key-1"
  public_key = file("/home/ubuntu/key-1.pub")
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

resource "aws_route_table" "RT" {
   vpc_id = aws_vpc.My-VPC-AWS-vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "rtal" {
  count         = 2
  route_table_id = aws_route_table.RT.id
  subnet_id     = count.index == 0 ? aws_subnet.subnet_az1.id : aws_subnet.subnet_az2.id
}

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Security group for EC2 instances in the subnet"
  vpc_id      = aws_vpc.My-VPC-AWS-vpc.id

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
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  key_name = "key-1"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  subnet_id     = count.index == 0 ? aws_subnet.subnet_az1.id : aws_subnet.subnet_az2.id
  connection {
        type        = "ssh"
        user        = "ubuntu" 
        private_key = file("/home/ubuntu/key-1")
        host        = self.public_ip
    }
  provisioner "remote-exec" {
    inline = [ 
      "sudo apt update -y",
      "sudo apt install -y openjdk-17-jdk",
      "wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz",
      "tar -xvzf apache-tomcat-9.0.85.tar.gz",
      "sudo mv apache-tomcat-9.0.85 /opt/tomcat9",
      "sudo /opt/tomcat9/bin/startup.sh"
    ]
  }

  provisioner "file" {
    source      = "/home/ubuntu/warfile/jenkins_workflow/sample.war"
    destination = "/opt/tomcat9/webapps/sample.war"
  }
    tags = {
      Name = "ec2-instance-${count.index + 1}"
    }
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

