# 09 - Práctica 10: Rendimiento y Contenedores (ECR)

## 🎯 Objetivo de la Práctica (Enfoque SysOps: Rendimiento y Seguridad)

El objetivo fue configurar la infraestructura para desplegar aplicaciones basadas en contenedores de manera eficiente y segura. Se creó un Repositorio de Contenedores Elástico (ECR) con políticas de Optimización de Costos y se validó la autenticación.

## ⚙️ Arquitectura Desplegada (Terraform)

| Recurso Desplegado | Función SysOps Principal | Principio Aplicado |
| :--- | :--- | :--- |
| **`aws_ecr_repository`** | Almacenamiento privado y seguro de imágenes Docker. | Rendimiento y Seguridad |
| **`aws_ecr_lifecycle_policy`** | Elimina imágenes antiguas para controlar el espacio de almacenamiento. | Optimización de Costos |

---

## ✅ Prueba de Rendimiento y Seguridad Realizada

Se validó la capacidad de la terminal local para autenticarse de forma segura en el repositorio privado ECR:

| Prueba | Comando | Resultado | Conclusión |
| :--- | :--- | :--- | :--- |
| **Autenticación Docker** | `aws ecr get-login-password... | docker login...` | **Login Succeeded** | **ÉXITO** Se confirmó que la CLI de AWS, mediante IAM, puede obtener un token de autenticación para Docker, garantizando un flujo de trabajo seguro y eficiente para los contenedores. |

---

## 🧹 Limpieza de Recursos (Principio 3: Costos)

La infraestructura de la práctica fue destruida:

```bash
terraform destroy