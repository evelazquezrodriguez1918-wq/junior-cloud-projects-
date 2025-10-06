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
# 1. RECURSO ECR (Elastic Container Registry)
# ----------------------------------------------------

# El Repositorio ECR: donde se almacenan las imágenes Docker.
resource "aws_ecr_repository" "junior_repo" {
  name                 = "junior-sysops-web-app"
  image_tag_mutability = "MUTABLE" # Permite reescribir tags (como 'latest')

  # 1.1. Configuración de escaneo de vulnerabilidades
  image_scanning_configuration {
    scan_on_push = true # Escanea la imagen cada vez que se sube (Seguridad)
  }

  tags = {
    Name = "JuniorECRRepo"
  }
}

# ----------------------------------------------------
# 2. POLÍTICA DE CICLO DE VIDA (Optimización de Costos y Rendimiento)
# ----------------------------------------------------

# Policy que elimina imágenes viejas para ahorrar espacio (Optimización)
resource "aws_ecr_lifecycle_policy" "cleanup_policy" {
  repository = aws_ecr_repository.junior_repo.name

  policy = jsonencode({
    rules = [
      {
        action = {
          type = "expire"
        }
        selection = {
          tagStatus   = "untagged" # Imágenes sin tag (sin usar)
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 90         # Eliminar después de 90 días
        }
        description = "Eliminar imágenes sin tag después de 90 días."
        rulePriority = 1
      },
      {
        action = {
          type = "expire"
        }
        selection = {
          tagStatus   = "any" # Cualquier imagen
          countType   = "imageCountMoreThan"
          countNumber = 50     # Mantener solo las 50 imágenes más recientes
        }
        description = "Mantener solo las últimas 50 imágenes."
        rulePriority = 2
      },
    ]
  })
}

# ----------------------------------------------------
# 3. OUTPUTS
# ----------------------------------------------------

output "ecr_repository_url" {
  value       = aws_ecr_repository.junior_repo.repository_url
  description = "La URL completa del repositorio para comandos Docker."
}

output "docker_login_command" {
  value       = "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.junior_repo.repository_url}"
  description = "Comando para autenticar Docker localmente con AWS."
}