terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_key_pair" "minecraft_key" {
  key_name   = "minecraft_key"
  public_key = file("~/minecraft-key.pub")
}

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft_sg"
  description = "Allow inbound traffic"

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "minecraft_sg"
  }
}

resource "aws_instance" "minecraft_server" {
  ami           = "ami-03f65b8614a860c29" 
  instance_type = "t3.small"
  key_name      = aws_key_pair.minecraft_key.key_name

  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]

  user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get install openjdk-17-jdk -y
  mkdir /home/ubuntu/minecraft
  wget -O /home/ubuntu/minecraft/minecraft_server.jar https://launcher.mojang.com/v1/objects/1b557e7b033b583cd9f66746b7a9ab1ec1673ced/server.jar
  chown -R ubuntu:ubuntu /home/ubuntu/minecraft
  echo 'eula=true' > /home/ubuntu/minecraft/eula.txt
  sudo bash -c 'cat > /etc/systemd/system/minecraft.service << EOL
  [Unit]
  Description=Minecraft Server
  After=network.target

  [Service]
  WorkingDirectory=/home/ubuntu/minecraft
  ExecStart=/usr/bin/java -Xmx1024M -Xms1024M -jar /home/ubuntu/minecraft/minecraft_server.jar nogui
  User=ubuntu
  Restart=always

  [Install]
  WantedBy=multi-user.target
  EOL'
  sudo systemctl enable minecraft
  sudo systemctl start minecraft
  EOF

  tags = {
    Name = "MinecraftServer"
  }
}

output "minecraft_server_public_ip" {
  value = aws_instance.minecraft_server.public_ip
  description = "The public IP of the Minecraft server"
}

output "minecraft_server_id" {
  value = aws_instance.minecraft_server.id
  description = "The ID of the Minecraft server"
}
