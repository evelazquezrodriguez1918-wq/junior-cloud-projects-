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