# Define que usaremos el proveedor de AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
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
# 1. SEGURIDAD Y RED (2. Seguridad por diseño)
# ----------------------------------------------------

# Data: Encuentra tu VPC por defecto
data "aws_vpc" "default" {
  default = true
}

# 1.1. Recurso: Key Pair para SSH (Acceso mínimo, clave privada)
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "junior_key" {
  key_name   = "junior_key_ssh"
  public_key = tls_private_key.rsa.public_key_openssh
}

# 1.2. Recurso: Security Group (Firewall)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  # Mínimo Privilegio: Solo Puerto 22 (SSH) y 80 (Web)
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "HTTP Access"
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

# ----------------------------------------------------
# 2. INSTANCIA EC2 (4. Automatización y 3. Optimización)
# ----------------------------------------------------

# Data: Obtener la AMI más reciente de Amazon Linux 2023 (OS Linux esencial)
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }
  owners = ["amazon"]
}

# Recurso: EC2 Instance (Servidor Web)
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro" # Free Tier (Optimización de costos)
  key_name      = aws_key_pair.junior_key.key_name
  
  # Asignar IP pública y SG
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  
  # User Data: Script de automatización (Instala Apache)
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install httpd -y
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Servidor Web Desplegado y Monitorizado con Terraform!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Junior Web Server"
  }
}

# ----------------------------------------------------
# 3. MONITOREO (1. Fiabilidad ante todo)
# ----------------------------------------------------

# Recurso: CloudWatch Metric Alarm
# Alerta si el uso de CPU excede el 80% (Indicador de problemas de rendimiento)
resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = "High-CPU-Junior-Web-Server"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60 # 60 segundos
  statistic           = "Average"
  threshold           = "80"
  unit                = "Percent"
  
  alarm_description = "Alerta si el uso de CPU excede el 80% por 2 minutos."
  
  dimensions = {
    InstanceId = aws_instance.web_server.id
  }
  
  actions_enabled = true
  # NOTA: En un entorno real, aquí se pondría un SNS Topic (ej. topic_arns = [aws_sns_topic.alerts.arn])
  # Para esta práctica, la crearemos para que la veas en la consola.
}

# ----------------------------------------------------
# 4. OUTPUTS (5. Documentación y claridad)
# ----------------------------------------------------

# Output: Generar archivo .pem (clave privada) en la carpeta local
resource "local_file" "private_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "${path.module}/junior_key_private.pem"
  # Permiso de archivo restringido (Buenas prácticas de seguridad)
  file_permission = "0400" 
}

output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "La IP pública del servidor web EC2. Úsala en tu navegador (http://IP)."
}

output "ssh_command" {
  value = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.web_server.public_ip}"
  description = "Comando para conectarse al servidor por SSH."
}