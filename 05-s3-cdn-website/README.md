# 05 - Práctica 5: Alojamiento Web Estático Seguro con CDN (S3 + CloudFront)

## 🎯 Objetivo de la Práctica

El objetivo de esta práctica fue crear una arquitectura de distribución de contenido de alto rendimiento y segura en AWS. Esto se logró utilizando un **Bucket S3** para alojar un sitio web estático y **Amazon CloudFront (CDN)** para servir el contenido a nivel global, con las siguientes metas de seguridad y rendimiento:

* **Rendimiento:** Distribuir el contenido en Edge Locations globales para baja latencia.
* **Seguridad:** Mantener el Bucket S3 **completamente privado**, forzando a los usuarios a acceder al contenido ÚNICAMENTE a través de la CDN.

## ⚙️ Arquitectura Desplegada (Terraform)

El despliegue con Terraform creó los siguientes recursos:

1.  **`aws_s3_bucket`:** El bucket de origen del sitio web, configurado para Alojamiento Web Estático.
2.  **`aws_s3_bucket_public_access_block`:** Bloqueo total de políticas y ACL públicas (máxima seguridad).
3.  **`aws_cloudfront_origin_access_identity` (OAI):** Una "identidad" de seguridad que solo la CDN (CloudFront) utiliza para solicitar archivos al S3.
4.  **`aws_s3_bucket_policy`:** Política de recurso que permite el acceso **solo al ARN de la OAI**.
5.  **`aws_cloudfront_distribution`:** La CDN (Content Delivery Network) que sirve como punto de acceso global y redirige el tráfico a HTTPS.

## ✅ Pruebas Exitosas (Logro Principal)

La arquitectura fue validada mediante las siguientes pruebas, confirmando el éxito en seguridad y funcionalidad principal:

| Prueba | Acción | Resultado Esperado | Resultado Obtenido |
| :--- | :--- | :--- | :--- |
| **Funcionalidad Principal** | Acceder a la URL de CloudFront. | Mostrar **`index.html`** | **ÉXITO** (Sitio en línea) |
| **Mínimo Privilegio (Seguridad)** | Intentar acceder a la URL directa del Bucket S3. | Devolver **`403 Access Denied`** | **ÉXITO** (Bucket es privado) |
| **Uso del Error Personalizado** | Acceder a una ruta falsa (`/404-test.html`). | Mostrar la página **`error.html`** personalizada. | **FALLO (Persistente)** |

## ⚠️ Desafío y Depuración

El principal desafío fue la propagación de la configuración de **manejo de errores (404)** en CloudFront. A pesar de configurar el bloque `custom_error_response` en Terraform para usar `/error.html`, la CDN persistió en devolver el error XML genérico de AWS.

**Pasos de Depuración Realizados:**
1.  Verificación y corrección de múltiples errores de sintaxis (`Unsupported argument`, `Missing newline`).
2.  Verificación de la configuración de `custom_error_response` y el origen (OAI) en el `main.tf`.
3.  Intento de forzar la invalidación de caché de CloudFront.

**Conclusión del Desafío:** Este es un problema conocido de propagación de la caché de CloudFront, el cual no impide que la funcionalidad principal (sitio en línea) y la seguridad (bucket privado) funcionen correctamente.

---

## 🧹 Limpieza de Recursos

Para evitar costos, la infraestructura de la práctica fue destruida:

```bash
terraform destroy