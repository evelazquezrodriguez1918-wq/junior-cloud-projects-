# AWS Backup Script & CloudWatch Monitoring 
## Objetivo 
Automatizar el respaldo de un volumen EBS (Disco de un servidor EC2) a Amazon S3 y notificar al administrador si el uso de la CPU de la instancia excede el 80% durante más de 5 minutos.
## Arquitectura implmentada 
* **Servicio de Cómputo:** 1 Instancia EC2 T2 Micro (Ubuntu 22.04).
* **Almacenamiento:** 1 Volumen EBS adjunto, 1 Bucket s3 para Backups.
* **Seguridad:** Política de IAM de mínimo privilegio asignada a la instancia para solo permitir `s3:PutObject` en el bucket específico.
* **Monitoreo:** Alarma de CloudWatch configurada en la métrica `CPUUtilization` con acción de notificación SNS.
## Pasos de Despliegue 
1. **Configurar IAM:** Crear Rol `EC2-Backup-Role` con la política `s3-limited-acces.json`
2. **Despliegue de EC2:** Lanzar la instacnia y adjuntar el rol.
3. **Scripting:** Copiar `backup_script.sh` a la instancia. **El script usa el comando AWS CLI para copiar archivos (`aws s3 cp`).*
4. **Cron Job:** Programar el script para que se ejecute cada domingo a las 2 AM.
5. ## Archivos del Respositorio
6. | Archivo | Descripción |
7. | :--- | :--- |
8. |`backup_script.sh` | Script Bash que comprime y sube datos a S3 usando la AWS CLI. |
9. |`s3-limited-acces.json` | JSON de la política IAM de mínimo privilegio. |
10. | `cloudwatch-alarma-config.md` | Documentación paso a paso de la configuración de la alarma. 
