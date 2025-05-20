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

Para detener el contenedor:
```sh
docker stop nagios
```
Para eliminarlo:
```sh
docker rm nagios
```
