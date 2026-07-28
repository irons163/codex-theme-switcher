# Codex Theme Switcher 0.2.9-beta.2

## Conexiones con Codex más fiables

- Selecciona automáticamente el siguiente puerto loopback disponible cuando el puerto bridge predeterminado está ocupado, evitando que Theme Switcher pierda la comunicación con Codex.
- Guarda el puerto bridge seleccionado para cada directorio de datos de Theme Switcher, de modo que los comandos posteriores vuelvan a conectarse de forma coherente.
- Mantiene un comportamiento estricto para los puertos configurados explícitamente: los conflictos se notifican en lugar de cambiar de puerto silenciosamente.
- Añade pruebas de regresión del puerto bridge y una nueva imagen promocional del tema a las siete versiones del README.
