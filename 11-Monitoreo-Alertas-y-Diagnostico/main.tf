# main.tf

# =======================================================
# 1. SETUP INICIAL: PROVIDERS Y LLAVE SSH
# =======================================================

# Proveedor de AWS
provider "aws" {
  region = "us-east-1"
}

# Proveedor TLS para generar la llave privada de SSH
resource "tls_private_key" "triage_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Key Pair de AWS usando la llave generada
resource "aws_key_pair" "triage_key_pair" {
  key_name   = "triage_key"
  public_key = tls_private_key.triage_key.public_key_openssh
}

# Guarda la llave privada localmente (para el comando SSH)
resource "local_file" "triage_key_private" {
  content  = tls_private_key.triage_key.private_key_pem
  filename = "triage_key_private.pem"
  file_permission = "0400" # Permisos de solo lectura para SSH
}

# Security Group para permitir SSH (puerto 22)
resource "aws_security_group" "triage_sg" {
  name        = "triage-sg"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permite acceso SSH desde cualquier IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =======================================================
# 2. RECURSOS DE IAM (LA CORRECCIÓN CRÍTICA PARA CLOUDWATCH)
# =======================================================

# A. Define el Rol que la instancia EC2 asumirá.
resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2-cloudwatch-role-triage"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# B. Adjunta la política predefinida de AWS para enviar métricas y logs.
resource "aws_iam_role_policy_attachment" "cloudwatch_attachment" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# C. Crea un Perfil de Instancia para pasar el Rol al EC2.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-cloudwatch-profile-triage"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

# =======================================================
# 3. RECURSO EC2 (ASIGNACIÓN DEL ROL E INSTALACIÓN DE STRESS)
# =======================================================

resource "aws_instance" "test_server" {
  ami           = "ami-052064a798f08f0d3" # Amazon Linux 2023 (Asegúrate que esta AMI sea válida en us-east-1)
  instance_type = "t3.micro"
  key_name      = aws_key_pair.triage_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.triage_sg.id]

  # ¡CLAVE! Esto le da al servidor los permisos para reportar a CloudWatch
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Instala 'stress' para simular la carga de CPU
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    # El paquete 'stress' está disponible directamente en AL2023 sin amazon-linux-extras
    sudo yum install stress -y
  EOF

  tags = {
    Name = "CloudWatch-Triage-Server"
  }
}

# =======================================================
# 4. RECURSO CLOUDWATCH METRIC ALARM (ALTA SENSIBILIDAD)
# =======================================================

resource "aws_cloudwatch_metric_alarm" "cpu_alert" {
  alarm_name                = "CRIT-EC2-CPU-Alta-Triage"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"

  # Configuración para respuesta inmediata (1 minuto)
  period                    = 60                  
  evaluation_periods        = 1                   
  datapoints_to_alarm       = 1                   
  threshold                 = 80                  

  statistic                 = "Average" 
  treat_missing_data        = "notBreaching"
  
  dimensions = {
    InstanceId = aws_instance.test_server.id
  }

  alarm_actions = [] 
  ok_actions    = []
}

# =======================================================
# 5. OUTPUTS (FACILITAR EL DIAGNÓSTICO)
# =======================================================

output "ssh_command" {
  description = "Comando para conectarse al servidor EC2 para el Triage."
  value       = "ssh -i triage_key_private.pem ec2-user@${aws_instance.test_server.public_ip}"
  sensitive   = true
}

output "instance_id" {
  description = "ID de la instancia EC2 para verificar en la consola."
  value       = aws_instance.test_server.id
}