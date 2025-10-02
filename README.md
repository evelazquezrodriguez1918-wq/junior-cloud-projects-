
# **AWS Backup Script & CloudWatch Monitoring**

## **Objetivo**
Automatizar el respaldo de un volumen EBS (Disco de un servidor EC2) a Amazon S3 y notificar al administrador si el uso de la CPU de la instancia excede el 80% durante más de 5 minutos.

## **Arquitectura Implementada**

* *Servicio de Cómputo:* 1 Instancia EC2 T2 Micro (Ubuntu 22.04).
* *Almacenamiento:* 1 Volumen EBS adjunto, 1 Bucket S3 para Backups.
* *Seguridad:* Política IAM de mínimo privilegio asignada a la instancia para solo permitir s3:PutObject en el bucket específico.
* *Monitoreo:* Alarma de CloudWatch configurada en la métrica CPUUtilization con acción de notificación SNS.

## **Pasos de Despliegue**

1.  *Configurar IAM:* Crear Rol EC2-Backup-Role con la política s3-limited-access.json.
2.  *Despliegue de EC2:* Lanzar la instancia y adjuntar el rol.
3.  *Scripting:* Copiar backup_script.sh a la instancia.
    * *El script usa el comando AWS CLI para copiar archivos (aws s3 cp).*
4.  *Cron Job:* Programar el script para que se ejecute cada domingo a las 2 AM.

## **Archivos del Repositorio**

| Archivo | Descripción |
| :--- | :--- |
| backup_script.sh | Script Bash que comprime y sube datos a S3 usando la AWS CLI. |
| s3-limited-access.json | JSON de la política IAM de mínimo privilegio. |
| cloudwatch-alarma-config.md | Documentación paso a paso de la configuración de la alarma. |
-----
---
# **Práctica 4: Despliegue de Servidor Web con Terraform (Infraestructura como Código - IaC)**

## **Objetivo de la Práctica**
El objetivo principal fue migrar la infraestructura creada manualmente en la Práctica 1 a un modelo de Infraestructura como Código (IaC) utilizando Terraform. Esto demuestra la capacidad para automatizar, versionar y replicar la infraestructura de forma segura y eficiente.

## **Infraestructura Desplegada**
Se utilizó un único archivo de configuración (`main.tf`) para desplegar dos recursos principales en AWS:

* *aws_security_group (web_sg):** Un firewall configurado para permitir tráfico entrante en los puertos **HTTP (80)** y **SSH (22)**.
* *aws_instance (web_server):** Una instancia EC2 de tipo **`t3.micro`** (para compatibilidad con la capa gratuita) que ejecuta Ubuntu 22.04 LTS.

## **Automatización (User Data)**
La instancia EC2 se inicializó automáticamente con un script Bash a través de `user_data`, que realizó las siguientes tareas:
* Instalación del servidor web **Apache2**.
* Creación de una página HTML personalizada con el mensaje **"Servidor Web Desplegado con Terraform y IaC"**.

## **Flujo de Trabajo Clave de Terraform**

Los comandos clave ejecutados y sus propósitos:

| Comando | Propósito | Resultado Esperado |
| :--- | :--- | :--- |
| `terraform init` | Inicializa el proyecto, descarga el proveedor de AWS y valida la sintaxis HCL. | **Terraform has been successfully initialized!** |
| `terraform plan` | Muestra el plan de ejecución: qué recursos se **añadirán**, modificarán o eliminarán. | **Plan: 2 to add, 0 to change, 0 to destroy.** |
| `terraform apply` | Ejecuta el plan, provisionando los recursos en la cuenta de AWS. | **Apply complete! Resources: 2 added, 0 changed, 0 destroyed.** |
| `terraform destroy` | Elimina toda la infraestructura gestionada por este archivo de estado. | **Destroy complete! Resources: 2 destroyed.** |

## **Evidencia de Éxito**

*<img width="1365" height="767" alt="Captura de pantalla 2025-10-01 131535" src="https://github.com/user-attachments/assets/ccac2e0d-4836-4586-abe3-0373a6787f76" />
---

##  **Desafíos y Aprendizaje**
1.  *Permisos (IAM):* Se enfrentó y resolvió el error `UnauthorizedOperation` al confirmar que el usuario que ejecuta Terraform debe tener la política **`AdministratorAccess`** (mientras se aprende a usar el Mínimo Privilegio).
2.  *Sintaxis y Dependencias:* Se resolvió un error de **`InvalidAMIID`** al aprender que las AMIs son específicas de la región.
3.  *Gestión de Versiones (Git):* Se resolvió el error `Large files detected` de GitHub (límite de 100MB) mediante la creación de un archivo **`.gitignore`** para excluir el binario del proveedor (`.terraform/`).
