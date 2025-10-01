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
  region = "us-east-1"
}

# 1. Recurso: Bucket S3
# ¡USA UN NOMBRE COMPLETAMENTE NUEVO, EJEMPLO: admin-practica-3-s3!
resource "aws_s3_bucket" "static_website" {
  bucket = "admin-practica-3-s3" 

  tags = {
    Name        = "admin-practica-3-s3"
    Environment = "Dev"
  }
}

# 2. Recurso: Configuración de Bloqueo de Acceso Público
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.static_website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Recurso: Bucket Policy (MÍNIMO PRIVILEGIO)
resource "aws_s3_bucket_policy" "restrict_access_policy" {
  bucket = aws_s3_bucket.static_website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowReadAccessFromSpecificIP"
        Effect    = "Allow"
        Principal = "*" 
        Action    = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.static_website.arn}/*",
        ]
        Condition = {
          IpAddress = {
            # 🚨 TU IP con /32 (ej: "187.202.40.38/32")
            "aws:SourceIp" = ["187.202.40.38/32"] 
          }
        }
      },
      {
        Sid       = "DenyAllOtherActions"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "${aws_s3_bucket.static_website.arn}/*"
        Condition = {
          NotIpAddress = {
            # 🚨 TU IP sin /32 (ej: "187.202.40.38")
            "aws:SourceIp" = ["187.202.40.38"] 
          }
        }
      }
    ]
  })
}