provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "secure" {
  name        = "secure"
  description = "Allow inbound SSH and HTTP traffic"

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
}


resource "aws_instance" "myinstance" {
  ami                    = "ami-03f4878755434977f" 
  instance_type          = "t2.micro"
  key_name               = "securekey"             
  vpc_security_group_ids = [aws_security_group.secure.id]
 
  }

resource "aws_eip" "myeip" {
  instance = aws_instance.myinstance.id
}

output "public_ip" {
  value = aws_instance.myinstance.public_ip
}