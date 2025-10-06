# ----------------------------------------------------
# 0. CONFIGURACIÓN INICIAL Y PROVEEDORES
# ----------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # NECESARIO: Genera la clave privada para SSH
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

# ----------------------------------------------------
# 1. SEGURIDAD (Key Pair y Archivo .pem)
# ----------------------------------------------------

# Genera la clave RSA privada (recurso que faltaba)
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Registra la clave pública en AWS (recurso que faltaba)
resource "aws_key_pair" "junior_key" {
  key_name   = "junior_key_ssh_alb" # Nombre único para esta práctica
  public_key = tls_private_key.rsa.public_key_openssh
}

# ----------------------------------------------------
# 2. DATA Y RECURSOS DE RED (Subnets y Security Groups)
# ----------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

# Modificación para un filtro más robusto de subredes públicas
data "aws_subnets" "two_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "mapPublicIpOnLaunch"
    values = ["true"] 
  }
}

# 2.1 SG para el ALB (Solo permite HTTP 80 de cualquier lugar)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow all http traffic to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
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

# 2.2 SG para las EC2s (Permite HTTP del ALB y SSH para gestión)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-alb-sg"
  description = "Allow traffic from ALB and SSH"
  vpc_id      = data.aws_vpc.default.id

  # Acceso HTTP solo desde el Security Group del ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Acceso SSH (Para gestión)
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
}

# ----------------------------------------------------
# 3. BALANCEADOR DE CARGA DE APLICACIÓN (ALB)
# ----------------------------------------------------

# 3.1 Recurso: ALB
resource "aws_lb" "application_balancer" {
  name               = "junior-alb-balancer"
  internal           = false 
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.two_public.ids # Corregido para usar la lista de IDs directamente
  enable_deletion_protection = false 
}

# 3.2 Recurso: Target Group (Grupo de Destino)
resource "aws_lb_target_group" "web_target_group" {
  name     = "junior-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/" 
    port = "traffic-port"
    protocol = "HTTP"
    matcher = "200"
    interval = 30
    timeout  = 5
    healthy_threshold   = 2 
    unhealthy_threshold = 2
  }
}

# 3.3 Recurso: Listener (Escuchador)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_group.arn
  }
}

# ----------------------------------------------------
# 4. INSTANCIAS EC2 (Los Servidores)
# ----------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }
  owners = ["amazon"]
}

# Server 1
resource "aws_instance" "web_server_1" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.junior_key.key_name # <-- ¡CLAVE SSH ASIGNADA!
  
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>¡Servidor 1 Activo! (Balanceo de Carga OK)</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Web-Server-1"
  }
}

# Server 2 
resource "aws_instance" "web_server_2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.junior_key.key_name # <-- ¡CLAVE SSH ASIGNADA!
  
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>¡Servidor 2 Activo! (Balanceo de Carga OK)</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Web-Server-2"
  }
}

# ----------------------------------------------------
# 5. REGISTRO EN TARGET GROUP (Fiabilidad)
# ----------------------------------------------------

# Registro del Servidor 1
resource "aws_lb_target_group_attachment" "web_attach_1" {
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

# Registro del Servidor 2
resource "aws_lb_target_group_attachment" "web_attach_2" {
  target_group_arn = aws_lb_target_group.web_target_group.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

# ----------------------------------------------------
# 6. OUTPUTS (Generar clave localmente y mostrar DNS)
# ----------------------------------------------------

# Genera el archivo .pem que necesitas
resource "local_file" "private_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "${path.module}/junior_key_private.pem"
  # Comentamos file_permission para evitar errores en Windows
}

output "alb_dns_name" {
  value       = aws_lb.application_balancer.dns_name
  description = "El DNS público del Balanceador de Carga para acceder al sitio."
}

output "ssh_command_s1" {
  value = "ssh -i ${local_file.private_key.filename} ec2-user@<IP_DEL_SERVER_1>"
  description = "Comando de ejemplo para conectarse al Servidor 1. Sustituye la IP."
}