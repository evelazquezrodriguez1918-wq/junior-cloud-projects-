# Define que usaremos el proveedor de AWS y su versión
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuración del proveedor de AWS (usará tu usuario IAM con AdministratorAccess)
provider "aws" {
  region = "us-east-1" # Reemplaza si usas otra región
}

# 1. Recurso: Grupo de Seguridad (Firewall)
resource "aws_security_group" "web_sg" {
  name        = "Terraform-WebSG-80"
  description = "Allow HTTP and SSH inbound traffic"
  # --- ¡REEMPLAZA ESTO CON TU VPC ID REAL! ---
  vpc_id      = "vpc-01093f70c4326ceee" 
  
  # Regla de Entrada HTTP (Puerto 80)
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Regla de Entrada SSH (Puerto 22)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Regla de Salida (Permite todo)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Recurso: Instancia EC2 (Servidor Web)
resource "aws_instance" "web_server" {
  ami           = "ami-0bbdd8c17ed981ef9" # AMI de Ubuntu 22.04 LTS (válida para us-east-1)
  instance_type = "t3.micro" 
  
  # Asocia el Grupo de Seguridad usando su nombre
  security_groups = [aws_security_group.web_sg.name] 
  
  # Script de User Data para la instalación de Apache2
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              echo "<h1>Servidor Web Desplegado con Terraform y IaC</h1>" | sudo tee /var/www/html/index.html
              sudo systemctl start apache2
              EOF
  
  tags = {
    Name = "Terraform-Web-Server-Junior"
  }
}