# Define que usaremos el proveedor de AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuración del proveedor de AWS
provider "aws" {
  # RDS se recomienda en us-east-1 o la región más cercana
  region = "us-east-1" 
}

# ----------------------------------------------------
# 1. RED (ASUMIENDO UNA VPC Y SUBNETS EXISTENTES)
# ----------------------------------------------------

# 1.1. Data: Encuentra tu VPC por defecto
data "aws_vpc" "default" {
  default = true
}

# 1.2. Data: Encuentra tus subredes por defecto
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ----------------------------------------------------
# 2. RDS CONFIGURACIÓN DE RED Y SEGURIDAD
# ----------------------------------------------------

# 2.1. Recurso: RDS Subnet Group (Obligatorio para RDS)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-junior-subnet-group"
  subnet_ids = data.aws_subnets.all.ids

  tags = {
    Name = "RDS Junior Subnet Group"
  }
}

# 2.2. Recurso: Security Group para RDS
# Permite tráfico en el puerto 5432 (PostgreSQL) desde cualquier IP (0.0.0.0/0)
resource "aws_security_group" "rds_sg" {
  name        = "rds-postgresql-sg"
  description = "Allow inbound traffic for PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "PostgreSQL access from anywhere"
    from_port   = 5432
    to_port     = 5432
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
    Name = "RDS PostgreSQL SG"
  }
}

# ----------------------------------------------------
# 3. INSTANCIA DE BASE DE DATOS RDS
# ----------------------------------------------------

resource "aws_db_instance" "postgresql_instance" {
  identifier           = "junior-cloud-postgresql"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t3.micro"
  db_name                 = "junior_database"         # <---- ¡CORREGIDO AQUÍ!
  username             = "adminuser"                  # 🚨 CAMBIAR
  password             = "PasswordSegura12345"        # 🚨 CAMBIAR
  publicly_accessible  = true                         
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "Junior Postgres Practice 6"
  }
}

# --- OUTPUT: Muestra el punto de conexión (endpoint) de la DB ---
output "rds_endpoint" {
  value       = aws_db_instance.postgresql_instance.endpoint
  description = "El punto de conexión para la base de datos PostgreSQL."
}