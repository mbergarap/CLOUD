# Soluciones Cloud — Obligatorio

## Descripción del proyecto

Proyecto desarrollado para la asignatura **Soluciones Cloud**, correspondiente a la carrera Analista en Infraestructura Informática de ORT Uruguay.

El objetivo es implementar una infraestructura en Amazon Web Services (AWS) que permita desplegar una aplicación web utilizando servicios de nube, automatización, seguridad, monitoreo, escalabilidad y distribución entre zonas de disponibilidad.

La infraestructura se administra mediante **Terraform**, utilizando una arquitectura modular.

La aplicación implementada es **Online Boutique**, una aplicación de microservicios desplegada sobre un clúster **K3s (Kubernetes)** en instancias Amazon EC2.

La solución incorpora:

- Infraestructura de red privada en AWS.
- Dos zonas de disponibilidad.
- Application Load Balancer (ALB).
- Clúster K3s con tres nodos EC2.
- Aplicación Online Boutique basada en microservicios.
- Horizontal Pod Autoscaler (HPA).
- Amazon RDS PostgreSQL Multi-AZ.
- Amazon S3.
- Bastion Host.
- Security Groups.
- CloudWatch y Amazon SNS.
- Estado remoto de Terraform almacenado en S3.

## Arquitectura

La infraestructura se encuentra desplegada en:

- **Región:** `us-east-1`
- **Zona de disponibilidad 1:** `us-east-1a`
- **Zona de disponibilidad 2:** `us-east-1b`
- **VPC:** `192.168.0.0/16`

### Networking

La VPC se divide en seis subredes distribuidas entre dos zonas de disponibilidad.

| Tipo de subred | Zona de disponibilidad | CIDR |
|---|---|---|
| Pública AZ1 | us-east-1a | 192.168.1.0/24 |
| Pública AZ2 | us-east-1b | 192.168.2.0/24 |
| Aplicación AZ1 | us-east-1a | 192.168.10.0/24 |
| Aplicación AZ2 | us-east-1b | 192.168.20.0/24 |
| Base de datos AZ1 | us-east-1a | 192.168.30.0/24 |
| Base de datos AZ2 | us-east-1b | 192.168.40.0/24 |

La arquitectura utiliza:

- **Internet Gateway:** permite la comunicación entre Internet y los recursos públicos de la VPC.
- **NAT Gateway AZ1:** permite la salida a Internet de las instancias privadas de la primera zona.
- **NAT Gateway AZ2:** proporciona salida a Internet para las instancias privadas de la segunda zona.
- **Tablas de rutas:** controlan el enrutamiento de las subredes públicas y privadas.

Las instancias K3s y RDS se encuentran en subredes privadas y no requieren direcciones IP públicas para recibir el tráfico de la aplicación.

### Application Load Balancer

Se utiliza un Application Load Balancer público para distribuir las solicitudes HTTP entre los nodos K3s.

Configuración:

- **Nombre:** `cloud-obligatorio-alb`
- **Listener:** HTTP, puerto 80
- **Target Group:** `cloud-obligatorio-k3s-tg`
- **Protocolo hacia los nodos:** HTTP
- **Puerto de destino:** 30080
- **Health Check:** `/`
- **Código esperado:** HTTP 200

El Target Group registra los tres nodos del clúster K3s.

La dirección pública utilizada para acceder a Online Boutique es:

`http://cloud-obligatorio-alb-643673029.us-east-1.elb.amazonaws.com/`

Esta dirección corresponde al entorno desplegado y puede cambiar si se recrea el ALB.

## Clúster K3s

La aplicación se ejecuta sobre un clúster Kubernetes implementado mediante K3s.

El clúster está formado por tres instancias EC2:

| Nodo | Dirección IP privada | Zona | Función |
|---|---|---|---|
| K3s Server | 192.168.10.152 | us-east-1a | Control Plane |
| K3s Worker 1 | 192.168.10.63 | us-east-1a | Worker |
| K3s Worker 2 | 192.168.20.83 | us-east-1b | Worker |

El servidor K3s administra el clúster y participa en la ejecución de cargas de trabajo.

Los dos workers permiten distribuir los contenedores entre instancias y zonas de disponibilidad.

El clúster utiliza el perfil IAM `LabInstanceProfile` proporcionado por AWS Academy, que permite utilizar los permisos disponibles en el laboratorio.

### Distribución entre zonas de disponibilidad

El frontend de Online Boutique utiliza `topologySpreadConstraints` con la etiqueta:

`topology.kubernetes.io/zone`

Esta configuración permite distribuir las réplicas del frontend entre diferentes zonas de disponibilidad.

En las verificaciones realizadas se confirmó:

- Una réplica del frontend en `us-east-1a`.
- Una réplica del frontend en `us-east-1b`.
- Ambas réplicas en estado `Running` y disponibles.

Esta distribución mejora la continuidad del servicio ante fallas de un nodo o zona, aunque no garantiza por sí sola la recuperación completa de todos los componentes.

### Limitación del Control Plane

La implementación utiliza un único servidor K3s en `us-east-1a`.

Por este motivo, **el Control Plane no tiene alta disponibilidad completa**.

Ante una falla de este servidor, pueden verse afectadas las operaciones de administración y programación de nuevos pods.

Esta limitación se considera una oportunidad de mejora de la arquitectura.

## Aplicación Online Boutique

Online Boutique es una aplicación de comercio electrónico basada en microservicios.

Los componentes desplegados son:

| Microservicio | Función |
|---|---|
| frontend | Interfaz web utilizada por los usuarios |
| adservice | Gestión de anuncios y recomendaciones publicitarias |
| cartservice | Administración del carrito de compras |
| checkoutservice | Coordinación del proceso de compra |
| currencyservice | Conversión de monedas |
| emailservice | Simulación del envío de correos |
| paymentservice | Simulación del procesamiento de pagos |
| productcatalogservice | Catálogo de productos |
| recommendationservice | Recomendaciones de productos |
| redis-cart | Almacenamiento del carrito |
| shippingservice | Cálculo y procesamiento simulado de envíos |

Cada componente cuenta con su Deployment y Service correspondiente.

Los servicios internos utilizan `ClusterIP`, mientras que el frontend se expone mediante un Service `NodePort`.

### Frontend personalizado

El frontend utiliza la imagen:

`matiasbp/online-boutique-interfaz:1.0`

Configuración de acceso:

- **Tipo de Service:** NodePort
- **Puerto interno del Service:** 80
- **NodePort:** 30080
- **Acceso externo:** Application Load Balancer

Los usuarios acceden al ALB, que distribuye las solicitudes a los nodos del clúster a través del puerto 30080.

### Flujo de solicitudes

```text
                    INTERNET
                        |
                        v
             APPLICATION LOAD BALANCER
                   HTTP :80
                        |
                        v
                TARGET GROUP K3S
                   HTTP :30080
                        |
           +------------+------------+
           |            |            |
           v            v            v
      K3s Server    K3s Worker   K3s Worker
         AZ1           AZ1          AZ2
           |            |            |
           +------------+------------+
                        |
                        v
                SERVICE FRONTEND
                   NODEPORT
                        |
                        v
                FRONTEND PODS
                  AZ1 y AZ2
                        |
                        v
              MICROSERVICIOS
                ONLINE BOUTIQUE
```

El ALB utiliza los tres nodos como destinos. Kubernetes gestiona el acceso a los pods del frontend y la comunicación entre los microservicios.

## Escalabilidad automática

Se implementó un Horizontal Pod Autoscaler (HPA) para el Deployment `frontend`.

Configuración:

| Parámetro | Valor |
|---|---|
| Nombre | frontend-hpa |
| API | autoscaling/v2 |
| Deployment | frontend |
| Réplicas mínimas | 2 |
| Réplicas máximas | 4 |
| Objetivo de utilización de CPU | 60 % |

El HPA consulta las métricas de CPU proporcionadas por Kubernetes y ajusta el número de réplicas según la demanda y la capacidad disponible.

El Deployment utiliza solicitudes de recursos de CPU para permitir el cálculo de utilización.

Se verificó que el HPA estaba activo, recibía métricas y mantenía dos réplicas cuando la utilización de CPU era baja.

**Limitación:** el HPA escala pods, pero no aumenta automáticamente la cantidad de instancias EC2 del clúster. La capacidad máxima depende de los tres nodos existentes.

## Base de datos Amazon RDS

La infraestructura incluye una base de datos administrada mediante Amazon RDS.

Características:

- **Motor:** PostgreSQL 16.
- **Tipo de instancia:** `db.t3.micro`.
- **Almacenamiento:** 20 GB.
- **Tipo de almacenamiento:** gp3.
- **Cifrado:** habilitado.
- **Multi-AZ:** habilitado.
- **Backups automáticos:** retención de 7 días.
- **Acceso público:** deshabilitado.
- **Subredes:** privadas de base de datos en ambas zonas.

RDS utiliza un Security Group específico que restringe sus conexiones de red.

Actualmente, RDS se mantiene como **componente independiente de infraestructura** y no es utilizado por los microservicios de Online Boutique.

La aplicación utiliza sus propios servicios internos, incluido Redis para el carrito.

La configuración Multi-AZ proporciona redundancia para el servicio de base de datos administrado.

## Almacenamiento Amazon S3

Se utilizan dos propósitos diferenciados de almacenamiento S3.

### Estado remoto de Terraform

Bucket:

`cloud-obligatorio-tfstate-2026`

Permite almacenar el estado de Terraform de forma remota, manteniendo un registro de los recursos administrados.

El bucket fue configurado con versionado habilitado.

Este bucket debe existir antes de inicializar Terraform con el backend remoto.

### Bucket de aplicación

Bucket:

`cloud-obligatorio-app-bergara-ocampo-2026`

Configuración:

- Bloqueo de acceso público.
- Cifrado SSE-S3.
- Versionado de objetos.
- Política de ciclo de vida para versiones anteriores.

El bucket conserva el archivo histórico `app.zip`, correspondiente a la implementación inicial de Flask.

Este archivo ya no forma parte del despliegue de Online Boutique y dejó de estar administrado como objeto por Terraform.

No debe confundirse este bucket con el utilizado para almacenar el estado remoto.

## Seguridad

La infraestructura utiliza Security Groups para controlar las comunicaciones.

### Application Load Balancer

- Permite recibir HTTP por el puerto 80 desde Internet.
- Permite la comunicación hacia los nodos K3s por el puerto 30080.

### K3s

Los nodos utilizan reglas de seguridad para:

- Recibir tráfico desde el ALB al frontend.
- Permitir las comunicaciones necesarias entre componentes del clúster.
- Permitir la administración autorizada.

### Bastion Host

El Bastion Host se encuentra en una subred pública y permite realizar tareas de administración sobre recursos privados.

El acceso SSH se restringe a una dirección IPv4 autorizada mediante una regla `/32`.

El proyecto incluye un script administrativo para actualizar esta dirección cuando cambia la IP pública del operador.

### RDS

La base de datos se encuentra en subredes privadas, sin acceso público.

Su Security Group no permite actualmente conexiones entrantes desde la antigua aplicación Flask.

### Protección de información sensible

Los siguientes archivos no deben publicarse en GitHub:

- `terraform.tfvars`
- Archivos de estado de Terraform.
- Credenciales AWS.
- Claves privadas SSH.
- Archivos `.pem` y `.key`.
- Planes binarios de Terraform.
- Archivos temporales que puedan contener datos sensibles.

El repositorio utiliza `.gitignore` para excluir estos archivos.

## Monitoreo y alertas

Se implementó monitoreo mediante Amazon CloudWatch y notificaciones mediante Amazon SNS.

### Alarmas de CPU

| Componente | Métrica | Umbral |
|---|---|---|
| K3s Server | CPUUtilization | 80 % |
| K3s Worker AZ1 | CPUUtilization | 80 % |
| K3s Worker AZ2 | CPUUtilization | 80 % |
| RDS PostgreSQL | CPUUtilization | 80 % |

Las alarmas evalúan el promedio de CPU durante períodos de 300 segundos.

Cuando se cumple la condición de alarma, SNS envía una notificación al correo configurado.

También se configuraron notificaciones al volver al estado normal.

### CloudWatch Logs

Se conservan los grupos de registros históricos de la implementación anterior:

- `/cloud-obligatorio/app/access`
- `/cloud-obligatorio/app/error`
- `/cloud-obligatorio/nginx/access`
- `/cloud-obligatorio/nginx/error`

Estos grupos tienen configurada una retención de 7 días.

No deben confundirse con una centralización completa de los logs actuales de Kubernetes.

## Estructura del repositorio

La estructura principal del proyecto es:

```text
Obligatorio-iISC/
|
|-- kubernetes/
|   |-- adservice.yaml
|   |-- cartservice.yaml
|   |-- checkoutservice.yaml
|   |-- currencyservice.yaml
|   |-- emailservice.yaml
|   |-- frontend.yaml
|   |-- frontend-hpa.yaml
|   |-- paymentservice.yaml
|   |-- productcatalogservice.yaml
|   |-- recommendationservice.yaml
|   |-- redis.yaml
|   |-- shippingservice.yaml
|
|-- terraform/
|   |-- modules/
|   |   |-- alb/
|   |   |-- bastion/
|   |   |-- database/
|   |   |-- k3s/
|   |   |-- monitoring/
|   |   |-- network/
|   |   |-- s3/
|   |   |-- security/
|   |
|   |-- backend.tf
|   |-- main.tf
|   |-- outputs.tf
|   |-- variables.tf
|   |-- terraform.tfvars.example
|
|-- Actualizar-SSH-Bastion.ps1
|-- .gitignore
|-- README.md
```

Además de los archivos principales, cada módulo contiene sus variables, recursos y outputs correspondientes.

Los módulos antiguos de Flask, Compute e IAM propio fueron retirados después de migrar a la arquitectura con K3s.

## Requisitos previos

Para trabajar con esta infraestructura se requiere:

1. Terraform instalado.
2. AWS CLI configurado con credenciales válidas.
3. Acceso a una cuenta AWS con permisos suficientes.
4. Región AWS `us-east-1`.
5. Un bucket S3 previamente preparado para el estado remoto.
6. Una clave pública SSH para los recursos que la requieran.
7. Un perfil IAM compatible con las necesidades de las instancias.
8. Acceso administrativo al servidor K3s para aplicar los manifiestos Kubernetes.

En el entorno utilizado se trabajó con:

- Windows.
- CMD y PowerShell.
- Terraform 1.16.6.
- AWS CLI.
- AWS Academy.
- `LabInstanceProfile`.

La configuración del módulo S3 para AWS Academy utiliza PowerShell y AWS CLI.

## Configuración de Terraform

Ingresar al directorio de Terraform:

```cmd
cd terraform
```

Crear el archivo de variables a partir del ejemplo, verificando previamente que coincida con las variables declaradas en `variables.tf`.

En PowerShell:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Configurar los valores requeridos para la cuenta AWS utilizada.

Entre los valores que deben revisarse se encuentran:

- Región AWS.
- Nombre del proyecto.
- Identificadores y rutas de claves SSH.
- Dirección IPv4 autorizada para el Bastion.
- Nombre del bucket de aplicación.
- Correo para las alertas.
- Configuración de RDS.
- Habilitación del clúster K3s.
- Nombre del perfil IAM de K3s.

En AWS Academy, los nodos K3s utilizan:

```hcl
nombre_perfil_iam_k3s = "LabInstanceProfile"
```

El archivo `terraform.tfvars` contiene valores específicos del entorno y no debe incluirse en el repositorio público.

Los nombres exactos de las demás variables deben consultarse en `terraform/variables.tf` y en el archivo de ejemplo actualizado.

## Backend remoto de Terraform

La infraestructura utiliza un backend remoto S3.

El estado remoto permite mantener la información de la infraestructura administrada fuera del equipo local.

Antes de ejecutar Terraform, se debe comprobar:

- Que el bucket de estado existe.
- Que las credenciales AWS son correctas.
- Que la configuración del backend corresponde al entorno deseado.
- Que se está utilizando el estado remoto correcto.

La configuración se encuentra en:

`terraform/backend.tf`

Inicializar Terraform:

```cmd
terraform init
```

No se debe reemplazar ni reinicializar el estado de una infraestructura existente utilizando otro bucket sin una migración controlada.

## Validación de Terraform

Comprobar el formato:

```cmd
terraform fmt -check -recursive
```

Validar la configuración:

```cmd
terraform validate
```

Revisar los cambios:

```cmd
terraform plan
```

Antes de ejecutar cualquier aplicación deben revisarse los recursos que Terraform propone crear, modificar o destruir.

Aplicar la configuración, únicamente después de revisar y autorizar el plan:

```cmd
terraform apply
```

**Advertencia:** ejecutar Terraform sobre una infraestructura ya desplegada puede modificar recursos existentes. No debe utilizarse `terraform apply` sin analizar previamente el plan.

## Despliegue de Kubernetes

Los manifiestos de Online Boutique se encuentran en:

`kubernetes/`

Para desplegar la aplicación es necesario disponer previamente de:

- Un clúster K3s operativo.
- Acceso administrativo mediante `kubectl`.
- Los nodos correctamente incorporados al clúster.
- Los componentes de red necesarios.
- Disponibilidad de las imágenes de los microservicios.
- Metrics Server operativo para utilizar el HPA.

### Comprobar los nodos

Desde el servidor K3s:

```bash
kubectl get nodes -o wide
```

### Desplegar Online Boutique

Desde un equipo con acceso administrativo al clúster y con los manifiestos disponibles:

```bash
kubectl apply -f kubernetes/
```

Este comando supone que el directorio `kubernetes/` está disponible localmente y que `kubectl` está configurado para acceder al clúster correspondiente.

Antes de utilizarlo en una infraestructura existente, revisar los cambios con:

```bash
kubectl diff -f kubernetes/
```

Para consultar los Deployments:

```bash
kubectl get deployments -n default
```

Consultar los Services:

```bash
kubectl get services -n default
```

Consultar los pods y sus nodos:

```bash
kubectl get pods -o wide -n default
```

### Verificar el HPA

```bash
kubectl get hpa -n default
```

Consultar más información:

```bash
kubectl describe hpa frontend-hpa -n default
```

La configuración del frontend incluye las restricciones de distribución entre zonas de disponibilidad.

El directorio `kubernetes/` contiene los manifiestos de los servicios y del HPA, pero no constituye por sí solo un instalador completo de K3s. La preparación de las instancias, sus permisos y la instalación del clúster también deben considerarse al reproducir el entorno.

## Pruebas y verificaciones

Durante el desarrollo se realizaron verificaciones de la infraestructura y del clúster.

### Acceso público

Se comprobó el acceso al ALB mediante HTTP.

Resultado observado:

`HTTP 200`

### Estado de K3s

Se comprobó que los tres nodos estuvieran registrados y en estado `Ready`.

### Disponibilidad de la aplicación

Se verificó que los 11 Deployments de Online Boutique estuvieran disponibles.

El frontend contaba con dos réplicas activas.

### Distribución entre zonas

Se comprobó la ejecución de una réplica del frontend en cada zona de disponibilidad.

### Escalado

Se verificó la existencia y funcionamiento del HPA con:

- Mínimo: 2 réplicas.
- Máximo: 4 réplicas.
- CPU objetivo: 60 %.

La presencia de un HPA operativo no constituye por sí sola una prueba completa de escalado bajo carga. Para verificar el aumento efectivo de réplicas se requiere generar y observar una carga suficiente.

### Monitoreo

Se comprobó la existencia de las alarmas de CloudWatch para K3s y RDS, junto con la integración con SNS.

## Tolerancia a fallos

La infraestructura incorpora mecanismos de redundancia:

- Dos zonas de disponibilidad.
- Dos subredes públicas.
- Dos NAT Gateway.
- Dos subredes de aplicación.
- Dos subredes privadas de base de datos.
- ALB distribuido entre zonas.
- Frontend replicado entre AZ.
- RDS Multi-AZ.

Estos mecanismos reducen el impacto de determinadas fallas.

Sin embargo, existen limitaciones:

- Un único servidor K3s Control Plane.
- Los nodos EC2 de K3s no se escalan automáticamente.
- Varios microservicios internos tienen una sola réplica.
- La distribución del frontend entre AZ no implica que todos los componentes de la aplicación tengan la misma redundancia.

Por lo tanto, la solución implementa tolerancia parcial a fallos, pero no garantiza alta disponibilidad completa de todos sus componentes.

## Mejoras futuras

Como posibles mejoras de la arquitectura se identifican:

1. Implementar alta disponibilidad del Control Plane de Kubernetes.
2. Incorporar escalado automático de nodos EC2.
3. Aumentar las réplicas de los microservicios internos críticos.
4. Implementar pruebas automáticas de carga y recuperación.
5. Centralizar los registros actuales de Kubernetes.
6. Incorporar HTTPS mediante un certificado TLS.
7. Implementar mecanismos adicionales de observabilidad y métricas de aplicación.
8. Automatizar de manera completa la preparación y configuración inicial de K3s.

Estas mejoras no forman parte de todos los componentes ya desplegados, sino que representan posibles ampliaciones futuras.

## Costos

La infraestructura utiliza servicios de AWS que pueden generar costos, incluso cuando la aplicación recibe poco tráfico.

Los principales componentes que deben considerarse son:

- Instancias EC2 de K3s.
- Instancia EC2 del Bastion.
- NAT Gateway.
- Application Load Balancer.
- Amazon RDS Multi-AZ.
- Amazon S3.
- CloudWatch.
- Transferencia de datos.

AWS Academy puede imponer restricciones de permisos, crédito disponible y duración del laboratorio.

Se recomienda revisar periódicamente los recursos y su consumo antes de mantener el entorno encendido durante períodos prolongados.

## Consideraciones de seguridad y operación

- No publicar credenciales ni claves privadas.
- Conservar la restricción SSH del Bastion.
- Utilizar siempre el estado remoto correcto.
- Revisar cualquier plan Terraform antes de aplicarlo.
- No eliminar buckets ni bases de datos sin verificar sus dependencias.
- No modificar las reglas de seguridad sin confirmar el impacto.
- Evitar aplicar manifiestos Kubernetes antiguos sobre configuraciones actualizadas.
- Verificar los recursos desplegados después de cada cambio importante.

## Uso de inteligencia artificial

Durante el desarrollo se utilizaron herramientas de inteligencia artificial como apoyo para el análisis de errores, consultas técnicas, revisión de configuraciones, preparación de comandos y documentación.

Las decisiones de arquitectura, las modificaciones sobre AWS y las validaciones de funcionamiento se realizaron y supervisaron durante el proceso de implementación.

## Conclusión

El proyecto implementa una infraestructura de nube en AWS administrada principalmente mediante Terraform y orientada a ejecutar la aplicación Online Boutique mediante un clúster K3s.

La solución combina separación de redes, balanceo de carga, contenedores, escalabilidad horizontal de pods, base de datos administrada, almacenamiento S3 y monitoreo mediante CloudWatch y SNS.

La utilización de dos zonas de disponibilidad mejora la distribución de la infraestructura, mientras que las pruebas y el análisis de limitaciones permiten identificar tanto las capacidades implementadas como las posibles mejoras de disponibilidad y escalabilidad.