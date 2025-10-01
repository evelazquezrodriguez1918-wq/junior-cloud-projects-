# 🔒 Práctica 3: Implementación de Mínimo Privilegio en AWS S3 (IaC)

## 🎯 Objetivo de la Práctica
Demostrar la capacidad para asegurar el almacenamiento de objetos mediante políticas de Mínimo Privilegio. Se desplegó un Bucket S3 y se aplicó una política estricta para controlar el acceso basado en la dirección IP de origen.

## 🛠️ Infraestructura Desplegada con Terraform
1.  **aws_s3_bucket:** El contenedor de almacenamiento (utilizando un nombre globalmente único).
2.  **aws_s3_bucket_public_access_block:** Un bloqueo de acceso público para cumplir con las mejores prácticas de seguridad de AWS (bloqueando ACLs y políticas públicas).
3.  **aws_s3_bucket_policy:** La política clave de seguridad que define el Mínimo Privilegio.

## ⚙️ La Política de Mínimo Privilegio (Resultado Clave)
La política fue configurada con dos declaraciones críticas:

| Declaración | Acción | Condición | Demostración de Seguridad |
| :--- | :--- | :--- | :--- |
| **Permitir Lectura** (`Allow`) | `s3:GetObject` (Lectura) | **`aws:SourceIp`** igual a **Mi IP pública** (`/32`) | **Funciona:** Permite el acceso solo al desarrollador para verificación. |
| **Denegar Todo** (`Deny`) | `s3:*` (Todas las acciones) | **`NotIpAddress`** diferente a **Mi IP pública** | **Funciona:** Bloquea todas las IPs externas y anula cualquier permiso de escritura, protegiendo el contenido. |

## 🖼️ Evidencia del Éxito
La verificación de la política de Mínimo Privilegio se confirmó con estas pruebas:

1.  **Prueba de Éxito (Mi IP):** Al acceder a la URL del objeto desde mi PC (IP autorizada), el navegador muestra el contenido del archivo de prueba.
2.  **Prueba de Denegación (IP Externa):** Al acceder a la misma URL desde mi celular (usando datos móviles, que es una IP diferente), el acceso fue **negado** con el error `Access Denied` (403 Forbidden).

---

## 🧩 Desafíos y Aprendizaje Clave
* **Diagnóstico de Sintaxis:** Se resolvió el error de sintaxis al utilizar correctamente las comillas dobles en la dirección IP dentro del JSON de la política.
* **Persistencia de Seguridad:** Se diagnosticó y resolvió un fallo de subida persistente causado por el Bloqueo de Acceso Público, demostrando la alta prioridad de esta configuración de seguridad sobre los permisos de IAM.