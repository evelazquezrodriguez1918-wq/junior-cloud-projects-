# 06 - Práctica 6: Despliegue de Base de Datos RDS (PostgreSQL)

## 🎯 Objetivo de la Práctica

El objetivo de esta práctica fue desplegar una **Base de Datos Relacional de nivel de producción** utilizando el servicio gestionado Amazon RDS (PostgreSQL). Se enfocó en la correcta configuración de red y seguridad para que la base de datos sea accesible para la prueba, pero mantenida por AWS.

## ⚙️ Arquitectura Desplegada (Terraform)

El despliegue con Terraform creó los siguientes recursos:

1.  **`aws_db_subnet_group`:** Un grupo que agrupa las subredes por defecto de la VPC, necesario para la **Alta Disponibilidad** de RDS.
2.  **`aws_security_group`:** Un firewall de red configurado para abrir el puerto **5432** (PostgreSQL), permitiendo el acceso solo a este servicio y bloqueando el tráfico web.
3.  **`aws_db_instance`:** La instancia de PostgreSQL (clase `db.t3.micro`) desplegada y lista para usarse.

---

## ✅ Pruebas Exitosas y Lecciones Aprendidas

| Prueba | Acción | Resultado Obtenido | Conclusión Clave (Lección Aprendida) |
| :--- | :--- | :--- | :--- |
| **1. Estado de la Instancia** | Verificación en la Consola AWS. | **ÉXITO:** El estado es **`Disponible`**. | La instancia fue creada y está activa. |
| **2. Prueba de Protocolo** | Acceso al `rds_endpoint` usando el **Navegador**. | **FALLO/TIME OUT:** Muestra `ERR_CONNECTION_TIMED_OUT`. | **ÉXITO de Seguridad:** El Security Group bloquea correctamente el tráfico web (puerto 443), confirmando que solo el protocolo PostgreSQL (5432) es aceptado. La DB no es un sitio web. |
| **3. Conexión Funcional** | Conexión con el cliente **`psql`** al `rds_endpoint` e ingreso de contraseña. | **ÉXITO:** Conexión establecida y *prompt* de `junior_database=>` visible. | La red y el firewall permiten el acceso al cliente correcto. **La infraestructura es funcional.** |

---

## 🧠 Conceptos Clave de la Práctica

| Concepto | Significado |
| :--- | :--- |
| **SQL** | **Structured Query Language** (Lenguaje de Consulta Estructurada). Es el lenguaje estándar universalmente utilizado para gestionar, manipular y consultar bases de datos relacionales (como PostgreSQL). |
| **PostgreSQL** | Un sistema de gestión de bases de datos relacionales (RDBMS) de código abierto, reconocido por su robustez, rendimiento y soporte avanzado de características. |
| **RDS** | **Relational Database Service**. Es el servicio de AWS que gestiona bases de datos. Se encarga automáticamente de tareas como parches, copias de seguridad y alta disponibilidad. |
| **Security Group** | Un firewall virtual a nivel de instancia. Controla el tráfico de entrada y salida permitido por número de puerto (ej. 5432 para PostgreSQL). |
| **DB Subnet Group** | Un grupo de subredes que se le asigna a una instancia RDS para que AWS sepa en qué Zonas de Disponibilidad (AZs) puede desplegar la base de datos para asegurar la alta disponibilidad. |

## 💻 Comandos Clave de Terraform

| Comando | Función |
| :--- | :--- |
| **`terraform init`** | Inicializa el directorio de trabajo, descarga el proveedor de AWS. |
| **`terraform plan`** | Muestra los cambios que se aplicarán (qué se creará, modificará o destruirá). |
| **`terraform apply`** | Ejecuta el plan y aplica los cambios en la infraestructura de AWS. |
| **`terraform output`** | Muestra el valor de una variable de salida (como el `rds_endpoint`). |
| **`terraform destroy`**| Elimina todos los recursos gestionados por el archivo de estado actual. **(Crucial para evitar costos)**. |

---

## 🧹 Limpieza de Recursos

Para evitar costos, la infraestructura de la práctica fue destruida:

```bash
terraform destroy