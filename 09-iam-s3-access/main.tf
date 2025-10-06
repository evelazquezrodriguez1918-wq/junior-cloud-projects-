# ----------------------------------------------------
# 0. CONFIGURACIÓN INICIAL Y PROVEEDORES
# ----------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

# ----------------------------------------------------
# 1. RECURSOS DE S3 (El recurso de destino)
# ----------------------------------------------------

# El bucket donde el EC2 tendrá acceso de lectura/escritura.
# ¡REEMPLAZA ESTO CON UN NOMBRE ÚNICO!
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "junior-iam-access-octubre-2025-admin" 
  # Solo dejamos la definición del nombre del bucket 
} 
  # Recurso dedicado para el Bloqueo de Acceso Público (Principio 2: Seguridad)
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------------------------
# 2. IAM: ROL DE MÍNIMO PRIVILEGIO (Principio 2)
# ----------------------------------------------------

# 2.1. Trust Policy: Define quién puede asumir este Rol (Solo instancias EC2)
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    effect = "Allow"
  }
}

# 2.2. Rol de IAM que será asumido por la instancia EC2
resource "aws_iam_role" "ec2_s3_role" {
  name               = "junior-ec2-s3-access-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# 2.3. Attach Policy: Define los permisos reales (solo lectura/escritura en el bucket)
data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.secure_bucket.arn,            # Acceso al bucket en sí
      "${aws_s3_bucket.secure_bucket.arn}/*",     # Acceso a los objetos dentro del bucket
    ]
  }
  # AÑADE UNA REGLA EXPLÍCITA DE NEGACIÓN DE ACCESO TOTAL
  statement {
    actions = ["s3:*"]
    effect  = "Deny"
    resources = ["*"]
    condition {
      test     = "ArnNotEquals"
      variable = "aws:SourceArn"
      values   = [aws_iam_role.ec2_s3_role.arn]
    }
  }
}

# 2.4. Adjunta la política al Rol
resource "aws_iam_role_policy" "s3_policy_attachment" {
  name   = "s3-read-write-policy"
  role   = aws_iam_role.ec2_s3_role.id
  policy = data.aws_iam_policy_document.s3_access_policy.json
}

# 2.5. Perfil de Instancia (Necesario para que EC2 asuma el Rol)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "junior-ec2-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# ----------------------------------------------------
# 3. EC2 (La instancia de prueba)
# ----------------------------------------------------

# Data: VPC y AMI para el EC2
data "aws_vpc" "default" {
  default = true
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }
  owners = ["amazon"]
}

# SG para permitir SSH
resource "aws_security_group" "ssh_sg" {
  name        = "ssh-only-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id
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

# Recurso: EC2 Instance
resource "aws_instance" "iam_test_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  
  # 🚨 ASIGNACIÓN DEL ROL DE IAM
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name 
  
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ssh_sg.id]
  
  tags = {
    Name = "IAM-Test-Server"
  }
}

# ----------------------------------------------------
# 4. OUTPUTS
# ----------------------------------------------------
output "ec2_public_ip" {
  value = aws_instance.iam_test_server.public_ip
  description = "IP pública para conectarse al servidor EC2 de prueba (SSH)."
}

output "bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
  description = "Nombre del bucket S3 de acceso restringido."
}