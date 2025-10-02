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

# ----------------------------------------------------
# 1. RECURSOS DEL BUCKET S3
# ----------------------------------------------------

# 1.1. Recurso: Bucket S3 para Alojamiento Estático
resource "aws_s3_bucket" "website_bucket" {
  # ¡REEMPLAZA CON TU NOMBRE ÚNICO GLOBAL!
  bucket = "bucket-practica-cdn-web-site" 
}

# 1.2. Recurso: Habilitar Alojamiento Web Estático (Para la metadata del S3)
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html" 
  }
  error_document {
    key = "error.html"
  }
}

# 1.3. Recurso: Bloquear Acceso Público Directo (Seguridad)
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------------------------------
# 2. ARCHIVOS DE PRUEBA DEL SITIO WEB
# ----------------------------------------------------

# 2.1. Archivo: index.html
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  content_type = "text/html"
  source       = "index.html" 
  etag         = filemd5("index.html")
}

# 2.2. Archivo: error.html
resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "error.html"
  content_type = "text/html"
  source       = "error.html" 
  etag         = filemd5("error.html")
}

# ----------------------------------------------------
# 3. RECURSOS DE CLOUDFRONT (CDN)
# ----------------------------------------------------

# 3.1. Recurso: Origin Access Identity (OAI) - La identidad de seguridad
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI para acceso seguro a bucket S3"
}

# 3.2. Recurso: Política de Bucket para Permitir Acceso OAI
# Permite que SOLO la OAI de CloudFront pueda leer los archivos del bucket
resource "aws_s3_bucket_policy" "cloudfront_s3_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "GrantCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action    = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.website_bucket.arn}/*",
        ]
      }
    ]
  })
}

# 3.3. Recurso: Distribución CloudFront (CDN)
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3-Website-Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website-Origin"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  # ✅ CORRECCIÓN FINAL: Manejo de errores 404 (para que muestre error.html)
  custom_error_response {
    error_code            = 404               # Cuando CloudFront recibe este código... 
    response_code         = 404               # envía este código al usuario
    response_page_path    = "/error.html"     # ... y muestra esta página
    error_caching_min_ttl = 300                
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "Junior-CDN-Website-V3-Refresh"
  }
}

# --- OUTPUTS ---

output "cloudfront_url" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "URL pública del sitio web servido por CloudFront (CDN)"
}

output "s3_website_endpoint" {
  value = aws_s3_bucket_website_configuration.website_config.website_endpoint
  description = "URL del bucket S3 (debe dar Access Denied)"
}