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
