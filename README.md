# Contenedor Docker para Nagios Core

Este proyecto proporciona un contenedor Docker basado en Ubuntu 25.10 que instala y configura Nagios Core junto con los plugins oficiales y Apache2 para la interfaz web.

## Estructura del proyecto

- **Dockerfile**: Define la imagen, instala dependencias, compila Nagios y plugins, y configura Apache.
- **start.sh**: Script de inicio que ajusta permisos, habilita módulos de Apache, valida la configuración de Nagios y lanza los servicios.
- **readme.md**: Este archivo de documentación.

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
   - Abre tu navegador en `http://localhost:8080`
   - Usuario: `nagiosadmin`
   - Contraseña: `nagiosadmin`

## Notas

- El contenedor expone el puerto 80.
- El usuario y grupo `nagios` y `nagcmd` son creados para la correcta ejecución de Nagios.
- El script [`start.sh`](start.sh) asegura los permisos y el correcto arranque de los servicios.

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
   -	Redacta un archivo Dockerfile que construya una imagen Docker con Nagios Core.
   -	La imagen debe incluir todas las dependencias necesarias para que Nagios funcione correctamente.
   -	Configura Nagios para que inicie automáticamente al arrancar el contenedor.
   -	Considera exponer el puerto 80 para acceder a la interfaz web de Nagios.
   -	Construye la imagen y verifica que Nagios sea accesible localmente.
   -	Sube el código del Dockerfile y otros archivos que requieras para construir la imagen a un repositorio GitHub.
   -	Crea un archivo README.md en el repositorio que explique detalladamente los pasos para construir la imagen y ejecutar el contenedor.

2. Despliegue en AWS ECS:
   -	Sube la imagen Docker creada a un repositorio de Elastic Container Registry (ECR).
   -	Crea un sistema de archivos EFS y configúralo para que sea accesible desde ECS.
   -	Define una tarea en ECS que utilice la imagen de Nagios del ECR.
   -	Configura el montaje del EFS en el directorio principal de Nagios en cada contenedor.
   -	Crea un servicio ECS con 3 tareas deseadas.
   -	Configura un Application Load Balancer (ALB) para distribuir el tráfico entre las tareas.
   -	Verifica que Nagios sea accesible a través de la URL del ALB.
   -	Confirma que los datos de Nagios se almacenan persistentemente en el EFS.
