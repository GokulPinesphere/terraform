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
  associate_public_ip_address = true
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("path/to/your/private-key.pem")  # Update with the correct path
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y openjdk-11-jdk",
    ]
  }
}

resource "aws_eip" "myinstance" {
  instance = aws_instance.myinstance.id
}

# Output the public IP of the instance
output "public_ip" {
  value = aws_instance.myinstance.public_ip
}