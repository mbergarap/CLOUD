# Soluciones Cloud — Obligatorio

## Descripción del proyecto

Proyecto de infraestructura en AWS desarrollado para la asignatura **Soluciones Cloud**.

La infraestructura se define mediante **Terraform**, utilizando módulos independientes para networking, seguridad, cómputo, almacenamiento, base de datos y monitoreo.

El proyecto admite dos modalidades de configuración:

- **AWS Academy:** utiliza los permisos y el perfil IAM proporcionados por el laboratorio.

- **AWS estándar:** permite crear un perfil IAM propio, administrar las credenciales de RDS mediante Secrets Manager y gestionar S3 con recursos nativos de Terraform.

## Arquitectura

La infraestructura está diseñada en la región `us-east-1` y utiliza dos zonas de disponibilidad: `us-east-1a` y `us-east-1b`.

### Networking

VPC principal: `192.168.0.0/16`.

| Tipo de subred | AZ | CIDR |

|---|---|---|

| Pública | us-east-1a | 192.168.1.0/24 |

| Pública | us-east-1b | 192.168.2.0/24 |

| Aplicación privada | us-east-1a | 192.168.10.0/24 |

| Aplicación privada | us-east-1b | 192.168.20.0/24 |

| Base de datos privada | us-east-1a | 192.168.30.0/24 |

| Base de datos privada | us-east-1b | 192.168.40.0/24 |

La VPC utiliza un Internet Gateway y dos NAT Gateway, uno por zona de disponibilidad.

### Componentes principales

- **Application Load Balancer:** distribuye tráfico HTTP hacia las instancias de aplicación.

- **Auto Scaling Group:** administra entre 2 y 4 instancias EC2.

- **Bastion Host:** proporciona un punto de acceso SSH a las instancias privadas.

- **Amazon RDS:** PostgreSQL 16, Multi-AZ, almacenamiento cifrado y respaldos automáticos.

- **Amazon S3:** almacena el paquete `app.zip` de la aplicación.

- **IAM:** configura permisos de acceso para las instancias EC2.

- **CloudWatch:** recopila logs y monitorea métricas de EC2 y RDS.

- **Amazon SNS:** envía notificaciones de las alarmas configuradas.

### Flujo de la aplicación

```text

Internet

&#x20;  |

&#x20;  v

Application Load Balancer

&#x20;  |

&#x20;  v

Auto Scaling Group

&#x20;  |

&#x20;  +-- EC2 App - AZ1

&#x20;  |

&#x20;  +-- EC2 App - AZ2

&#x20;         |

&#x20;         v

&#x20;   RDS PostgreSQL

&#x20;      Multi-AZ

```

Las instancias de aplicación se encuentran en subredes privadas. Nginx recibe el tráfico HTTP y lo redirige a la aplicación Flask ejecutada mediante Gunicorn.

## Estructura del repositorio

```text

CLOUD/

├── app/

├── bootstrap/

├── terraform/

│   ├── modules/

│   │   ├── network/

│   │   ├── security/

│   │   ├── bastion/

│   │   ├── alb/

│   │   ├── compute/

│   │   ├── database/

│   │   ├── iam/

│   │   ├── monitoring/

│   │   └── s3/

│   ├── backend.tf

│   ├── main.tf

│   ├── variables.tf

│   └── terraform.tfvars.example

├── .gitignore

└── README.md

```

## Requisitos previos

Para desplegar la infraestructura se necesitan:

1\. Terraform instalado.

2\. AWS CLI instalado y configurado con credenciales válidas.

3\. Permisos de AWS suficientes para crear los recursos utilizados.

4\. Un par de claves SSH, cuya clave pública se configurará en Terraform.

5\. Un bucket S3 previamente creado para almacenar el estado remoto de Terraform.

6\. Un nombre globalmente único para el bucket de la aplicación.

En AWS Academy, el módulo S3 utiliza PowerShell y AWS CLI, por lo que el equipo desde el que se ejecute Terraform debe contar con ambas herramientas.

## Configuración de variables

Dentro del directorio `terraform`, copiar el archivo de ejemplo:

**PowerShell (Windows):**

```powershell

Copy-Item terraform.tfvars.example terraform.tfvars

```

**Linux/macOS:**

```bash

cp terraform.tfvars.example terraform.tfvars

```

Editar `terraform.tfvars` y configurar los valores del entorno, especialmente:

- `db\_password`: contraseña de prueba segura para AWS Academy.

- `app\_bucket\_name`: nombre único del bucket de la aplicación.

- `ssh\_public\_key\_path`: ubicación de la clave pública SSH.

- `bastion\_ami\_id`: AMI válida para la región seleccionada.

- `alert\_email`: correo donde se recibirán las notificaciones.

- Variables que determinan la modalidad AWS Academy o AWS estándar.

El archivo `terraform.tfvars` no debe incluirse en GitHub.

## Modalidades de despliegue

### AWS Academy

Configurar:

```hcl

create\_iam\_profile          = false

manage\_master\_user\_password = false

use\_native\_s3               = false

ec2\_instance\_profile\_name = "LabInstanceProfile"

```

Esta modalidad utiliza un perfil IAM existente y AWS CLI para la administración del bucket S3 de la aplicación.

Su funcionamiento depende de los permisos habilitados en el laboratorio AWS Academy.

### AWS estándar

Configurar:

```hcl

create\_iam\_profile          = true

manage\_master\_user\_password = true

use\_native\_s3               = true

```

En esta modalidad:

- Terraform crea el rol y el perfil IAM de EC2.

- RDS administra la contraseña principal mediante AWS Secrets Manager.

- Terraform crea y configura el bucket S3 con recursos nativos.

El despliegue requiere una cuenta AWS con los permisos adecuados.

## Backend remoto de Terraform

El estado de Terraform se almacena en un bucket S3 independiente del bucket utilizado por la aplicación.

El archivo `terraform/backend.tf` contiene la configuración del backend.

El bucket de estado debe crearse antes de ejecutar `terraform init` y debe ser privado, con cifrado y versionado habilitados.

Para inicializar Terraform:

```bash

cd terraform

terraform init -reconfigure \\

&#x20; -backend-config="bucket=NOMBRE\_DEL\_BUCKET\_DE\_ESTADO"

```

En PowerShell, el comando puede ejecutarse en una sola línea:

```powershell

terraform init -reconfigure -backend-config="bucket=NOMBRE\_DEL\_BUCKET\_DE\_ESTADO"

```

Reemplazar `NOMBRE\_DEL\_BUCKET\_DE\_ESTADO` por el bucket correspondiente a la cuenta AWS utilizada.

No se debe utilizar un estado local de pruebas como reemplazo del estado remoto de una infraestructura ya desplegada.

## Validación y planificación

Verificar el formato:

```bash

terraform fmt -check -recursive

```

Validar la configuración:

```bash

terraform validate

```

Generar el plan:

```bash

terraform plan

```

Estos comandos permiten revisar la configuración antes de crear recursos.

## Despliegue

Después de revisar el plan, los permisos, los costos y el estado remoto correspondiente, la infraestructura puede desplegarse mediante:

```bash

terraform apply

```

La ejecución requiere confirmación del operador.

El despliegue puede generar costos por NAT Gateway, inst
