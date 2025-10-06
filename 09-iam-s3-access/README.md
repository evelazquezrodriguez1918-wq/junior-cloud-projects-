# 09 - Práctica 9: Seguridad IAM y Mínimo Privilegio

## 🎯 Objetivo de la Práctica (Enfoque SysOps: Seguridad)

El objetivo fue aplicar el **Principio de Mínimo Privilegio** de IAM. Se creó un Rol que permite a una instancia EC2 (el 'IAM-Test-Server') interactuar de forma segura con un bucket S3 específico, y se demostró que este Rol niega el acceso a cualquier otro recurso o bucket.

## ⚙️ Arquitectura Desplegada (Terraform)

| Recurso Desplegado | Función SysOps Principal | Principio Aplicado |
| :--- | :--- | :--- |
| **`aws_iam_role`** | Contenedor de permisos que el EC2 asume. | 2. Seguridad |
| **`aws_iam_policy_document`** | Define permisos explícitos de Lectura/Escritura solo en el Bucket de destino. | 2. Seguridad (Mínimo Privilegio) |
| **`aws_s3_bucket`** | El recurso de destino. Configuramos el Bloqueo de Acceso Público. | 2. Seguridad |
| **`aws_instance` (EC2)** | Servidor de prueba que ejecuta el comando `aws s3 ls`. | 4. Automatización |

---

## ✅ Pruebas de Mínimo Privilegio Realizadas

Se validó la política de seguridad directamente desde la terminal del EC2:

| Prueba | Comando | Resultado | Conclusión (Principio de Seguridad) |
| :--- | :--- | :--- | :--- |
| **1. Acceso Permitido** | `aws s3 ls s3://<BUCKET_PROPIO>` | **ÉXITO** | El Rol funcionó correctamente al proveer los permisos necesarios. |
| **2. Acceso Denegado** | `aws s3 ls s3://<BUCKET_AJENO>` | **Access Denied** | **ÉXITO** La política niega el acceso a recursos fuera de su alcance, confirmando el Mínimo Privilegio. |

---

## 🧹 Limpieza de Recursos (Principio 3: Costos)

La infraestructura de la práctica fue destruida:

```bash
terraform destroy
