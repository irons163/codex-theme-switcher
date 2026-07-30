# Codex Theme Switcher

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | [Français](README.fr.md) | **Español** | [日本語](README.ja.md) | [한국어](README.ko.md)

[![Vídeo de demostración de Codex Theme Switcher](docs/media/codex-theme-switcher-demo.gif)](https://github.com/irons163/codex-theme-switcher/raw/refs/heads/main/docs/media/codex-theme-switcher-demo.mp4)

Una app nativa para la barra de menús de macOS que permite diseñar, previsualizar, aplicar y compartir temas para la app de escritorio Codex / ChatGPT.

Theme Switcher inyecta estilos temporales al iniciar Codex. No modifica, sustituye ni vuelve a firmar la app original.

## Descargar

**Versión estable actual: 0.3.1**

[DMG para Apple Silicon](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.1/CodexThemeSwitcher-0.3.1-apple-silicon.dmg)
·
[DMG para Intel](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.1/CodexThemeSwitcher-0.3.1-intel.dmg)
·
[Notas de la versión y sumas de comprobación](https://github.com/irons163/codex-theme-switcher/releases/tag/v0.3.1)

Requiere macOS 13 o posterior. Ambos instaladores están firmados y notarizados por Apple.

## Funciones principales

- Biblioteca de temas, editor, vista previa en tiempo real y estado de conexión en la barra de menús.
- Colores, fuentes, espaciado, radios, sombras, desenfoque, escala y movimiento.
- Imágenes claras y oscuras con Fit, Fill, punto focal, filtros, capas y cristal.
- Personalización experimental de ChatGPT Voice: fondo, orbe, retrato animado, formas de boca, parpadeo y movimiento en reposo.
- Controles avanzados de componentes, reglas de selectores, variables personalizadas y CSS sin procesar.
- Importación y exportación en un único archivo `.codextheme` con imágenes y fuentes integradas.
- Inglés, chino tradicional, chino simplificado, francés, español, japonés y coreano.

## Inicio rápido

1. Instala y abre Codex Theme Switcher; después, haz clic en su icono de la barra de menús de macOS.
2. Haz clic en **Iniciar y conectar Codex**. La primera conexión puede reiniciar Codex.
3. Elige un tema integrado, crea una copia editable o crea un tema nuevo.
4. Ajusta el diseño y revisa las vistas previas Claro / Oscuro e Inicio / Chat.
5. Guarda el tema y haz clic en **Aplicar** para enviarlo a Codex.
6. Usa **Exportar** para compartir un `.codextheme` e **Importar** para instalar uno recibido.

La primera conexión no aplica automáticamente el tema seleccionado. Las conexiones posteriores restauran el último tema aplicado correctamente, no los cambios de borradores sin aplicar.

## Capturas de pantalla

### Estudio de temas

![Estudio de Codex Theme Switcher con biblioteca, vista previa y pestañas de edición](docs/images/theme-studio.png)

### Vistas previas del renderizador

| Paper · Claro / Inicio | Midnight · Oscuro / Chat |
| --- | --- |
| ![Vista previa de Paper claro en Inicio](docs/images/paper-light-home.png) | ![Vista previa de Midnight oscuro en Chat](docs/images/midnight-dark-chat.png) |

Las vistas previas generadas por un agente son aproximaciones cercanas. Verifica siempre el CSS avanzado y las reglas de selectores en la app Codex antes de compartir un tema.

## Guía de personalización

### Fondo y cristal

- Usa imágenes diferentes en Claro y Oscuro, o reutiliza una imagen con efectos distintos.
- Elige Fit, Fill, Stretch, Fit Width, Fit Height, Original o Tile y ajusta el punto focal y el zoom.
- Controla la opacidad y los filtros de la imagen de forma independiente al cristal de la barra lateral, contenido, cuadro de entrada, tarjetas, menús y bloques de código.
- Extiende el fondo por toda la ventana o excluye la barra lateral.
- Añade un panel de contenido central con fondo, borde, sombra, desenfoque, radio, ancho y relleno propios.

### ChatGPT Voice (experimental)

- Configura un fondo de Voice y otra imagen dentro del orbe animado.
- Añade un retrato con la boca cerrada y hasta ocho formas de boca, o importa una cuadrícula 2×2 / 3×3.
- Ajusta la sensibilidad, el umbral de silencio, la velocidad de apertura y cierre, el parpadeo, el movimiento en reposo, el pulso y la visibilidad del orbe original.
- La boca sigue la intensidad del audio; no es una sincronización labial por fonemas.

El estilo de Voice depende del renderizador interno de ChatGPT y puede necesitar cambios después de una actualización de Codex / ChatGPT.

## Importar y exportar

- Exportar crea un único `.codextheme` con la configuración y los recursos integrados.
- Los temas importados no se aplican automáticamente; revísalos y haz clic en **Aplicar**.
- Image Skin admite PNG, JPEG, WebP, GIF y AVIF.
- Límites: 16 MB por recurso, 32 MB en total y 48 MB por `.codextheme`.

Ejemplos: [`minimal.codextheme`](Examples/minimal.codextheme) y [`full.codextheme`](Examples/full.codextheme).

## Diseñar con un agente de IA

Después de instalar la app, entrega esta instrucción a un agente de IA:

```text
Usa este Agent CLI para diseñar un tema de Codex:
/Applications/CodexThemeSwitcher.app/Contents/Helpers/codex-theme

Ejecuta primero capabilities y schema. Completa validate, compile y las cuatro vistas previas.
No apliques el tema sin mi confirmación.
```

El CLI puede crear, validar, compilar, importar, exportar y generar vistas previas Claro / Oscuro × Inicio / Chat. Solo las órdenes explícitas `attach`, `apply` o `clear` cambian Codex.

Consulta [`docs/AGENT_API.md`](docs/AGENT_API.md) para ver la referencia de comandos.

## Idiomas y actualizaciones

- La app usa automáticamente el idioma de macOS; los idiomas no admitidos utilizan el inglés.
- Elige un idioma manualmente en **Ajustes → Idioma de la interfaz**.
- Elige el canal Stable o Beta en Ajustes.
- Las actualizaciones usan Sparkle y ofrecen la versión correcta para Apple Silicon o Intel.

## Seguridad y recuperación

- Theme Switcher no modifica `app.asar` ni sustituye archivos de Codex / ChatGPT.
- Los datos de los temas y el puente de conexión permanecen en el Mac local.
- Los temas importados no pueden ejecutar JavaScript ni cargar URL remotas o de archivos locales.
- Si el CSS personalizado hace que Codex sea ilegible, elige **Restaurar estilos originales de Codex** en la app de la barra de menús.
- Cerrar Codex y volver a abrirlo normalmente elimina los estilos temporales inyectados.

Este es un proyecto independiente, sin afiliación ni respaldo de OpenAI.

## Compilar desde el código fuente

Requisitos: macOS 13+, Swift 6, Node.js 22+ y la app de escritorio Codex / ChatGPT.

```sh
swift build
swift test
npm test
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

Documentación para desarrolladores:

- [Agent CLI](docs/AGENT_API.md)
- [Actualizaciones, firma, notarización y publicación](docs/UPDATES.md)
