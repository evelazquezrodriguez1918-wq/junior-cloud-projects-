# 07 - Práctica 7: Despliegue de Servidor Web Robusto y Observado (EC2 + CloudWatch)

## 🎯 Objetivo de la Práctica (Enfoque SysOps)

El objetivo fue desplegar una infraestructura de servidor web de forma **automática, segura y observable**. El enfoque estuvo en Infraestructura como Código (IaC) y garantizar la capacidad de respuesta ante problemas de rendimiento.

## ⚙️ Arquitectura Desplegada (Terraform)

| Recurso Desplegado | Función SysOps Principal | Principio Aplicado |
| :--- | :--- | :--- |
| **`aws_instance` (EC2)** | Servidor de aplicación (t3.micro, Optimización de Costos). | 3. Optimización |
| **`user_data` Script** | Automatización de la instalación de Apache y la página de prueba. | 4. Automatización |
| **`aws_security_group`** | Firewall configurado con Mínimo Privilegio (solo puertos 22 y 80 abiertos). | 2. Seguridad |
| **`aws_key_pair`** | Clave privada SSH para acceso de gestión segura. | 2. Seguridad |
| **`aws_cloudwatch_metric_alarm`** | Crea una alarma de **Fiabilidad** que se activa si el CPU > 80% (Monitoreo). | 1. Fiabilidad |

---

## ✅ Pruebas de SysOps Realizadas

| Prueba | Acción | Estado | Principio Confirmado |
| :--- | :--- | :--- | :--- |
| **1. Acceso Web** | Acceder a la IP pública en el navegador. | **ÉXITO** | Automatización (El script `user_data` se ejecutó correctamente). |
| **2. Conexión SSH** | Conectarse al EC2 usando el archivo `.pem` y el comando `ssh -i ...`. | **ÉXITO** | Seguridad (El acceso remoto de gestión está asegurado por la clave privada). |
| **3. Monitoreo** | Verificar la alarma `High-CPU-Junior-Web-Server` en CloudWatch. | **ÉXITO** | Fiabilidad (La observabilidad del servidor está activa desde el inicio). |

---

## 🧹 Limpieza de Recursos

Para evitar costos, la infraestructura de la práctica fue destruida:

```bash
terraform destroy