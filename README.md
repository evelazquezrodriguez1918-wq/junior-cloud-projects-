
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
# **PRACTICA 1. AWS Despliegue de Servidor Web EC2 y Segurdad básica**
---
## **Objetivo**
Deplegar una máquina virtual (Instancia EC2) Con un servidor web simple (Como Apache o Nginx) y asegurar que solo se pueda acceder a él a través del puerto HTTP (80) desde internet 
---
## **Arquitectura Implementada**
| Componente | Configuración | Propósito |
| :--- | :--- | :--- |
| *Cómputo* | Instancia EC2 (`t3.micro` - Ubuntu) | Servidor de aplicación (Web). |
| *Seguridad(IAM)* | Poliítica de Mínimo Privilegio (`JuniorCloudAdmin-EC2-Policy`) | Restringe el usuario a solo manipular recursos de EC2 y Networking, cumpliendo con la seguridad. |
| *Firewall (SG)* | Grupo de Seguridad (`WebSG-HTTP-80`) | Permite tráfico **HTTP (Puerto 80)** para internet (`0.0.0.0/0`) y **SSH (Puerto 22)** para gestión remota. | 
| *Automatización* | User Data (Script Bash) | Instala Apache2 y crea la página de bienvenida al arranque de la instancia. |
---
## <img width="1365" height="767" alt="Captura de pantalla 2025-09-30 211329" src="https://github.com/user-attachments/assets/a57c01b1-eb6b-4551-9b23-fbc855215d03" />
Aquí se muestra la página Web personalizada que confirma el despliegue correcto del servidor Apache y la correcta apertura de firewall (Puerto 80)


## **Lecciones Aprednidas y Diagnóstico (El Valor Agergado)**
Esta pr+actica fue un laboratorio completo de diagnóstico, resolviendo dos problemas clave:

### *1. Error de instalación del Servicio (Problema de Compatibilidad)* 
* **Síntoma:** Al verificar el servicio, el sistema arrojó `Unit httpd.service could not be found`.
* **Causa:** La AMI (Amazon Machine Image) seleccionada fue **Ubuntu**,que utiliza el gestor de paquetes `apt` y nombra al servicio como **`apache2`**. El script inicial utilizaba la sintaxis de `yum` (`httpd`).
* Solución:** Se corrigió el script de *User Data* a la sintaxis correcta para Ubuntu (`sudo apt install apache2 -y`) y se usó el comando `sudo systemctl start apache2`.

### *2. Bloqueo de Acceso Denegado (Problema de Firewall)*
* **Síntoma:** La IP Pública no cargaba ("No se puede acceder a este sitio") incluso después de que el servidor web estaba corriendo.
*  **Causa:** El tráfico HTTP (Puerto 80) estaba bloqueado por el firewall de la nube (**Grupo de Seguridad**)
*  **Solución:** Se verificaron y se aseguraron las **Reglas de Entrada** del Grupo de Seguridad, confirmando que el **Puerto 80** estuviera abierto al origen **`0.0.0.0/0`** (Internet)
---
# **Práctica 2: Despliegue de Servidor Web con Terraform (Infraestructura como Código - IaC)**

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
---
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

1.  **Prueba de Éxito (Mi IP):** Al acceder a la URL del objeto desde mi PC (IP autorizada), el navegador muestra el contenido del archivo de prueba (`test_cli.txt`). 
2.  **Prueba de Denegación (IP Externa):** Al acceder a la misma URL desde mi celular (usando datos móviles, que es una IP diferente), el acceso fue **negado** con el error `Access Denied` (403 Forbidden). 

---

## 🧩 Desafíos y Aprendizaje Clave
* **Diagnóstico de `MalformedPolicy`:** Se resolvió el error `MalformedPolicy` de S3 ajustando el formato CIDR (`/32`) en la cláusula `Deny`.
* **Persistencia de `Explicit Deny`:** Se diagnosticó y resolvió un fallo de subida persistente (`explicit deny`) causado por el Bloqueo de Acceso Público, demostrando la alta prioridad de esta configuración de seguridad.
* **Flujo de Trabajo (Git):** Se aseguró que el flujo de trabajo de IaC se integrara sin problemas con Git.
