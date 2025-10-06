# 08 - Práctica 8: Balanceo de Carga y Alta Disponibilidad (ALB + EC2)

## 🎯 Objetivo de la Práctica (Enfoque SysOps: Fiabilidad y Redes)

El objetivo fue desplegar una arquitectura web distribuida utilizando un Balanceador de Carga de Aplicación (ALB) para garantizar la **Alta Disponibilidad** y la **Fiabilidad** del servicio. Se demostró que la infraestructura puede tolerar un fallo total en uno de los servidores sin interrumpir el servicio.

## ⚙️ Arquitectura Desplegada (Terraform)

La arquitectura consta de:

1.  **Application Load Balancer (ALB):** Distribuye el tráfico en el puerto 80.
2.  **Dos Instancias EC2 (t3.micro):** Servidores web idénticos (`Web-Server-1` y `Web-Server-2`), distribuidos en diferentes Zonas de Disponibilidad (AZs).
3.  **Target Group:** Gestiona las verificaciones de salud (Health Checks) y la lista de servidores sanos.
4.  **Security Groups:** Aseguran que solo el tráfico del ALB pueda llegar a las EC2.

---

## ✅ Pruebas de Fiabilidad (Failover Test)

| Prueba | Acción | Resultado Obtenido | Principio Confirmado |
| :--- | :--- | :--- | :--- |
| **1. Balanceo de Carga** | Acceder a la URL del ALB y refrescar la página. | **ÉXITO:** El sitio alterna entre "Servidor 1 activo" y "Servidor 2 activo". | Fiabilidad (La carga se distribuye correctamente). |
| **2. Simulación de Fallo (Failover)** | Conexión SSH al Servidor 2 y ejecución de `sudo systemctl stop httpd`. | **ÉXITO:** Después de ~90 segundos, todas las peticiones se redirigieron **automáticamente** al **Servidor 1**. | Fiabilidad / Alta Disponibilidad (El sistema toleró la caída de un nodo sin interrupción). |
| **3. Seguridad** | El acceso SSH se aseguró mediante la clave privada `.pem` generada por Terraform. | **ÉXITO** | Seguridad (El acceso de gestión se realizó con credenciales de mínimo privilegio). |

---

## 🧹 Limpieza de Recursos (Principio 3: Costos)

La infraestructura de la Práctica 8 fue destruida para evitar costos:

```bash
terraform destroy