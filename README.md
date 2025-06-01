# Contenedor Docker para Nagios Core

Este proyecto proporciona un contenedor Docker basado en `php:8.4.8RC1-apache-bullseye` que instala y configura `Nagios Core en la version 4.5.9` junto con los `plugins oficiales en su versión 2.4.9`.

## Estructura del proyecto

- **Dockerfile**: Define la imagen, instala dependencias, compila Nagios y plugins, y configura Apache.
- **start.sh**: Script de inicio que ajusta permisos, habilita módulos de Apache, valida la configuración de Nagios y lanza los servicios.
- **README.md**: Este archivo de documentación.
- **main.tf**: Archivo principal de configuración de Terraform para desplegar la infraestructura en AWS.
- **terraform.tfvars.example**: Archivo de ejemplo para definir variables requeridas por Terraform (como la URI de la imagen Docker y el nombre del servicio ECS).

## Uso

1. **Construir la imagen:**
   ```sh
   docker build -t nagios-ea2 .
   ```

2. **Ejecutar el contenedor:**
   ```sh
   docker run -d -p 80:80 --name nagios nagios-ea2
   ```

3. **Acceder a Nagios:**
   - Abre tu navegador en `http://localhost:80/nagios`
   - Usuario: `nagiosadmin`
   - Contraseña: `nagiosadmin`

## Replicación de la infraestructura con Terraform
Requiere antes haber creado un repositorio en AWS ECR, haber subido la imagen Docker y agregar la uri de la imagen en el archivo `terraform.tfvars`.

### Para replicar la infraestructura definida en el archivo main.tf, puedes utilizar el siguiente comando de Terraform:

1. Inicializa Terraform en el directorio del proyecto:
   ```sh
   terraform init
   ```
2. Realiza un plan para ver los cambios que se aplicarán:
   ```sh
   terraform plan
   ```
3. Aplica los cambios para crear la infraestructura:
   ```sh
   terraform apply
   ```
4. Confirma la creación de los recursos cuando se te solicite.
5. Una vez completado, podrás acceder a Nagios a través de la URL del DNS proporcionada por el Application Load Balancer (ALB) creado por Terraform.

6. **Destruir la infraestructura** (opcional):
   Si deseas eliminar todos los recursos creados por Terraform, puedes ejecutar:
   ```sh
   terraform destroy
   ```

## Notas

- El contenedor expone el puerto 80.
- El usuario y grupo `nagios` y `nagcmd` son creados para la correcta ejecución de Nagios.
- El script [`start.sh`](start.sh) asegura los permisos, la creacion de directorios necesarios y el correcto arranque de los servicios.

## Mantenimiento

Para eliminar la imagen:
```sh
docker rmi nagios-ea2
```
Para detener el contenedor:
```sh
docker stop nagios
```
Para eliminarlo:
```sh
docker rm nagios
```
# Encargo

Esta evaluación tiene como objetivo medir tu capacidad para crear imágenes Docker, desplegar aplicaciones en AWS ECS y configurar servicios de monitoreo con Nagios. A través de esta actividad práctica, demostrarás tus habilidades en la gestión de contenedores, la administración de infraestructura en la nube y la implementación de herramientas de monitoreo esenciales.

## Lo que debes realizar:

1. Creación de la Imagen Docker:
   -	[x] Redacta un archivo Dockerfile que construya una imagen Docker con Nagios Core.
   -	[x] La imagen debe incluir todas las dependencias necesarias para que Nagios funcione correctamente.
   -	[x] Configura Nagios para que inicie automáticamente al arrancar el contenedor.
   -	[x] Considera exponer el puerto 80 para acceder a la interfaz web de Nagios.
   -	[x] Construye la imagen y verifica que Nagios sea accesible localmente.
   -	[x] Sube el código del Dockerfile y otros archivos que requieras para construir la imagen a un repositorio GitHub.
   -	[x] Crea un archivo README.md en el repositorio que explique detalladamente los pasos para construir la imagen y ejecutar el contenedor.

2. Despliegue en AWS ECS:
   -	[x] Sube la imagen Docker creada a un repositorio de Elastic Container Registry (ECR).
   -	[x] Crea un sistema de archivos EFS y configúralo para que sea accesible desde ECS.
   -	[x] Define una tarea en ECS que utilice la imagen de Nagios del ECR.
   -	[x] Configura el montaje del EFS en el directorio principal de Nagios en cada contenedor.
   -	[x] Crea un servicio ECS con 3 tareas deseadas.
   -	[x] Configura un Application Load Balancer (ALB) para distribuir el tráfico entre las tareas.
   -	[x] Verifica que Nagios sea accesible a través de la URL del ALB.
   -	[x] Confirma que los datos de Nagios se almacenan persistentemente en el EFS.
