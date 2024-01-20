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

# Create an EC2 instance
resource "aws_instance" "myinstance" {
  ami                    = "ami-03f4878755434977f" # Update with your desired AMI ID
  instance_type          = "t2.micro"
  key_name               = "securekey"             # Update with your SSH key pair name
  vpc_security_group_ids = [aws_security_group.secure.id]

  user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update -y
             sudo apt-get install -y default-jdk
             sudo apt-get install -y tomcat9
             # Update Tomcat server port to 8081
             sudo sed -i 's/8080/8081/g' /etc/tomcat9/server.xml
             sudo systemctl restart tomcat9
             EOF
}

resource "aws_eip" "myinstance" {
  instance = aws_instance.myinstance.id
}

# Output the public IP of the instance
output "public_ip" {
  value = aws_instance.myinstance.public_ip
}