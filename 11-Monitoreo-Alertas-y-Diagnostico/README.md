# 🛠️ Práctica 11: Monitoreo, Alertas y Diagnóstico (Triage con CloudWatch)

Este proyecto despliega una infraestructura simple en AWS utilizando Terraform para simular un escenario de alta carga de CPU y probar un flujo de trabajo de SysOps completo: **Alerta (CloudWatch) $\rightarrow$ Diagnóstico (SSH/top) $\rightarrow$ Mitigación (killall)**.

## 🎯 Objetivo de la Práctica

El objetivo principal fue configurar una alarma de CloudWatch de alta sensibilidad y asegurar que la instancia EC2 tuviera los permisos necesarios para reportar sus métricas, resolviendo así el problema común de falta de conexión entre EC2 y CloudWatch (IAM Role).

## ☁️ Recursos Desplegados con Terraform

| Recurso | Descripción |
| :--- | :--- |
| `aws_instance` | Servidor EC2 (t2.micro) con Amazon Linux 2023. |
| `aws_cloudwatch_metric_alarm` | Alarma crítica de alta sensibilidad (CPU >= 80% por 1 minuto). |
| `aws_iam_role` & `aws_iam_instance_profile` | Permisos necesarios para que el EC2 envíe métricas al servicio CloudWatch. **(Corrección clave de la práctica)**. |
| `tls_private_key` & `aws_key_pair` | Par de llaves SSH para acceso al servidor. |
| `aws_security_group` | Grupo de seguridad que permite la conexión SSH (puerto 22). |

## ⚙️ Flujo de Triage (Simulación de la Falla)

1.  **Despliegue:** Ejecutar `terraform init` y `terraform apply`.
2.  **Conexión:** Usar el `output` del `ssh_command` para acceder al servidor.
3.  **Simulación de Falla (CÓDIGO ROJO):** Ejecutar `stress --cpu 1 --timeout 300s &` dentro del EC2.
4.  **Verificación de Alerta:** Monitorear la Consola de CloudWatch hasta que la alarma cambie a **"In Alarm" (Rojo)**.
5.  **Diagnóstico:** Usar el comando `top` en una segunda ventana SSH para confirmar que el proceso `stress` es la causa de la alta CPU.
6.  **Mitigación:** Ejecutar el comando `killall stress` para detener el proceso.
7.  **Verificación Final:** La alarma debe regresar a **"OK" (Verde)**.

## ⚠️ Pasos para la Destrucción

Para evitar cargos, siempre destruye los recursos después de la práctica:

```bash
terraform destroy