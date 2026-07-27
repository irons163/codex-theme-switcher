# Codex Theme Switcher

[English](README.en.md) | [繁體中文](README.md) | [简体中文](README.zh-Hans.md) | [Français](README.fr.md) | **Español** | [日本語](README.ja.md) | [한국어](README.ko.md)

Un estudio de temas nativo para la barra de menús de macOS. No crea una ventana principal
convencional, no aparece en el Dock y no modifica, vuelve a firmar ni sobrescribe
`Codex.app` / `ChatGPT.app`.

Theme Switcher se conecta al proceso de renderizado de Codex mediante Chromium DevTools Protocol
(CDP) y escribe el CSS compilado en un elemento `<style>` con un espacio de nombres. Los cambios de
tema se sincronizan en tiempo real con todas las ventanas de Codex; el runtime también restaura
automáticamente el tema después de recargar Codex o al abrir una ventana nueva.

## Capturas de pantalla

### Estudio de temas de la barra de menús

![Estudio de temas de Codex Theme Switcher mostrando la biblioteca, la vista previa en directo y todas las pestañas de edición](docs/images/theme-studio.png)

### Vista previa del proceso de renderizado para agentes

| Paper · Claro / Inicio | Midnight · Oscuro / Chat |
| --- | --- |
| ![Vista previa de Paper claro en Inicio](docs/images/paper-light-home.png) | ![Vista previa de Midnight oscuro en Chat](docs/images/midnight-dark-chat.png) |

El Agent CLI puede generar PNG Light/Dark × Home/Chat en un entorno sin ventanas para que los
agentes de IA los inspeccionen de forma iterativa. Son aproximaciones estructuradas; el resultado
final de las selector rules, el raw CSS y el proceso de renderizado real de Codex debe comprobarse
después de aplicar el tema.

## Funciones

- App exclusivamente para la barra de menús; toda la biblioteca de temas, la edición, la vista
  previa y el estado del runtime se encuentran en el panel de la barra de menús.
- Tres plantillas integradas: Midnight, Paper y High Contrast.
- Aplicación con un clic, restauración del estilo original de Codex y reconexión del proceso
  de renderizado.
- Sistema visual de colores:
  - Colores semánticos básicos.
  - Tokens de interfaz, interacción, diff y terminal de Codex `--color-token-*`.
- Controles de tipo y tamaño de letra, altura de línea, ancho del contenido, espaciado, radio de
  las esquinas, sombra, desenfoque, escala y animaciones.
- Fondo y cristal (Image Skin): fondos claro/oscuro separados, siete modos de tamaño, incluidos
  Fit / Fill, recorte por punto focal, lienzo de fondo opcional que ocupa toda la ventana o evita
  la barra lateral, filtros, overlay, glass por sección y panel de contenido central.
- Declaraciones de componentes arbitrarias.
- CSS selector rules arbitrarias.
- Escape hatch de raw CSS completo.
- Múltiples layers con light / dark / custom media query.
- Se pueden integrar recursos PNG, JPEG, WebP, GIF, fuentes y otros archivos en las plantillas; el
  runtime los transfiere por fragmentos y crea Blob URL locales al proceso de renderizado, por lo
  que las imágenes 4K grandes no superan el límite de longitud de las declaraciones CSS.
- Importación y exportación en un único archivo `.codextheme` para facilitar el intercambio.
- Cambio automático entre inglés, chino tradicional, chino simplificado, francés, español,
  japonés y coreano según el idioma preferido de macOS; los demás idiomas usan inglés como
  alternativa.
- Actualizaciones automáticas con Sparkle 2: permite elegir el canal Stable o Beta, obtener el
  instalador correcto para Apple Silicon o Intel y consultar las notas de la versión en los mismos
  siete idiomas.
- Busca actualizaciones al iniciarse y cada 30 minutos; también se puede comprobar manualmente
  desde Ajustes o desde el menú superior derecho, omitir versiones concretas o usar la descarga
  manual.
- Incluye el Agent CLI `codex-theme`, diseñado JSON-first: los agentes de IA pueden obtener el
  esquema y los ejemplos, validar, normalizar, compilar, instalar, exportar y generar vistas previas
  PNG Light/Dark × Home/Chat; Codex solo cambia mediante una llamada explícita a `attach`, `apply`
  o `clear`.

## Fondo y cristal / Image Skin

Image Skin permite convertir Codex en un tema gráfico completo, no solo sustituir una paleta de
colores:

- Light y Dark pueden utilizar imágenes de fondo distintas o compartir la misma imagen con efectos
  diferentes.
- Los fondos admiten Fit (mostrar la imagen completa), Fill (rellenar recortando
  proporcionalmente), Stretch, Fit Width, Fit Height, Original y Tile; cada modo puede combinarse
  con un punto focal u origen, zoom, opacidad y filtros de brillo, contraste, saturación y
  desenfoque.
- «El fondo evita la barra lateral» reorganiza como un conjunto la imagen, Fit / Fill, el punto
  focal, el overlay, el scrim y la vignette dentro del área de contenido principal; la barra
  lateral conserva su propio color de fondo y glass. Cuando cambia de ancho o se contrae, el límite
  del fondo sigue automáticamente el layout real de Codex.
- El Overlay puede usar un scrim de color sólido, un degradado lineal o una vignette para que la
  barra lateral, los títulos y el área de entrada sigan siendo legibles sobre imágenes complejas.
- Sidebar, main content, composer, card, menu, popover y code block se pueden configurar por
  separado con su propio glass fill, opacidad, backdrop blur, borde, radio de las esquinas y sombra;
  cambiar la opacidad de un panel no atenúa el texto.
- El «panel de contenido central» envuelve de forma independiente el Home Hero o el historial de
  conversaciones de Chat, sin incluir las Cards de sugerencias ni el Composer. Su color de fondo,
  borde, color de sombra y opacidad se pueden configurar por separado para Light y Dark; los
  controles de material incluyen blur, saturation, ancho del borde, radio de las esquinas,
  desplazamiento y expansión de la sombra, ancho máximo y relleno horizontal/vertical.
- La vista previa puede alternar entre Light / Dark y Home / Chat, lo que facilita comprobar a la
  vez el recorte del fondo, el contraste del texto y las superficies de los componentes.
- Los fondos usados por Image Skin se integran en el archivo `.codextheme`, por lo que los temas
  exportados no dependen de las rutas de los archivos originales y sus destinatarios pueden
  importarlos directamente.

Los controles visuales generan theme variables y component overrides portátiles. Cuando se
necesitan selectors más precisos, varios degradados, blend modes o animaciones, Raw CSS aún puede
sobrescribirlo todo al final; Raw CSS conserva el mayor grado de libertad en la theme cascade.

Los campos de imagen de Image Skin solo aceptan raster assets (PNG, JPEG, WebP, GIF, AVIF), con un
límite de 16 MB por asset. El límite combinado de todos los recursos es de 32 MB y cada archivo
`.codextheme` está limitado a 48 MB. Las fuentes se pueden seguir integrando mediante las funciones
avanzadas de recursos, pero no se pueden asignar como fondos de Image Skin.

## Flujo de trabajo

1. Abra la app y acceda al estudio de temas desde el icono de la paleta en la barra de menús de
   macOS.
2. Haga clic en «Iniciar y conectar Codex»; la primera conexión puede reiniciar Codex.
   La primera conexión no aplica automáticamente la plantilla preseleccionada. Las reconexiones
   posteriores restauran el último snapshot aplicado correctamente y guardado por el runtime, sin
   incluir los cambios que solo se hayan guardado posteriormente ni los que sigan en un borrador.
3. Aplique directamente una plantilla integrada o elija primero «Crear una copia editable»;
   también puede crear un tema vacío desde la esquina inferior izquierda.
4. Edite las pestañas Fondo y cristal, Colores, Tipografía y disposición, Componentes, Reglas, CSS
   avanzado, Recursos e Información. Un punto naranja indica que el tema aún tiene cambios sin
   guardar; el borrador no se pierde al cambiar a otro tema y volver.
5. Guarde y después aplique. Para compartir el tema, haga clic en Exportar y obtendrá un único
   archivo `.codextheme` con todos los recursos integrados. Los destinatarios pueden importarlo
   desde el mismo lugar.
6. La pestaña Ajustes permite activar o desactivar las actualizaciones automáticas, elegir
   Stable/Beta, buscar una versión nueva y volver a mostrar las «Novedades» de la versión actual.

## Modelo de seguridad

- No modifica `app.asar`, por lo que conserva la firma, la notarización y la integridad de ASAR de
  la app de OpenAI.
- El bridge de Theme Switcher solo escucha en `127.0.0.1` y utiliza un bearer token privado de
  256 bits.
- `.codextheme` no permite JavaScript.
- La importación y la compilación rechazan `@import`, URL `http:`, `https:`, protocol-relative y
  `file:`.
- Los recursos están integrados en la plantilla; la importación no extrae ningún ZIP, por lo que no
  existe riesgo de path traversal / zip-slip.
- Los fondos de Image Skin solo aceptan imágenes rasterizadas; al importar se validan el formato,
  los datos base64 y el límite de tamaño de 16 MB de cada asset integrado.
- El Runtime y los identificadores de estilo usan el espacio de nombres `codex-theme-switcher` y no
  eliminan otras herramientas de inyección.
- La barra de menús siempre ofrece «Restaurar el estilo de Codex», de modo que es posible recuperar
  la interfaz incluso si un CSS personalizado la daña.
- El Agent CLI prohíbe explícitamente ejecutar `attach`, `apply` o `clear` con un `--root` que no
  sea el predeterminado; una raíz personalizada solo sirve para aislar el repositorio y el trabajo
  sin conexión, y no puede utilizarse como entorno aislado del runtime real de Codex.
- El endpoint de depuración CDP de Chromium también está vinculado explícitamente a `127.0.0.1`,
  pero CDP no proporciona autenticación mediante bearer token; otros procesos locales del mismo
  Mac aún podrían conectarse. Si deja de usar la función de temas, cierre Codex y vuelva a abrirlo
  normalmente para que ya no se inicie con los argumentos de depuración remota.

## Compilación

Requisitos:

- macOS 13+
- Swift 6 toolchain
- Codex desktop app (la app unificada actual también puede estar en
  `/Applications/ChatGPT.app`)
- Node.js 22+; el programa usa primero
  `Contents/Resources/cua_node/bin/node` incluido en la app de Codex y después busca Node en
  PATH / Homebrew

```sh
swift build
swift test
npm test
npm run check
swift run CodexThemeSwitcher
swift run codex-theme capabilities
```

Crear una `.app` de barra de menús que se pueda abrir con doble clic:

```sh
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

El archivo `Info.plist` generado incluye `LSUIElement=true`, por lo que la app no aparece en el Dock
ni en el selector de apps convencional. El Agent CLI se empaqueta en
`CodexThemeSwitcher.app/Contents/Helpers/codex-theme`, mientras que el JSON Schema se encuentra en
`Contents/Resources/Schemas/`. Consulte
[`docs/AGENT_API.md`](docs/AGENT_API.md) para ver el protocolo completo y los ejemplos. Si no se
proporciona ninguna identidad de firma, el script usa una firma ad hoc; para una distribución de
producción, defina:

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
SPARKLE_PUBLIC_ED_KEY="<base64 Ed25519 public key>" \
  scripts/package-app.sh
```

Un paquete de producción debe proporcionar la clave pública Sparkle EdDSA. El script la escribe en
`SUPublicEDKey` y rechaza cualquier ajuste `SUAllowsInsecureUpdates`. Solo los paquetes locales de
desarrollo firmados ad hoc incluyen una excepción limitada al entorno local para permitir
actualizaciones no seguras y no deben utilizarse para versiones de producción.

## Actualizaciones y publicaciones de la app

- Canal Stable:
  `appcast-arm64.xml`, `appcast-x86_64.xml`
- Canal Beta:
  `appcast-beta-arm64.xml`, `appcast-beta-x86_64.xml`
- Los canales de actualización siempre se encuentran en la última versión Stable de GitHub; una
  versión Beta solo sustituye allí los archivos `appcast-beta-*`, por lo que la URL fija no deja de
  funcionar cuando GitHub excluye las versiones preliminares.
- Cada enclosure de appcast debe incluir una `sparkle:edSignature`, y las apps de producción también
  deben contener la `SUPublicEDKey` correspondiente.
- Los siete archivos de notas de la versión se encuentran en
  `docs/release-notes/v<version>/release-notes.<language>.md`.

Consulte [`docs/UPDATES.md`](docs/UPDATES.md) para obtener todos los detalles sobre secretos, firma,
notarización y el proceso de publicación.

## Primera conexión

Codex no abre ningún puerto CDP cuando se inicia normalmente. La primera vez que haga clic en
«Iniciar y conectar Codex», si no hay disponible ningún Codex debug target que se pueda compartir,
Theme Switcher primero pide a Codex que se cierre con normalidad y después lo reinicia con los
siguientes argumentos:

```text
--remote-debugging-address=127.0.0.1
--remote-debugging-port=57340
--remote-allow-origins=http://127.0.0.1:57340
```

Si `codex-desktop-switcher` ya ha creado un Codex target en alguno de los puertos 57330–57341, el
programa lo comparte en lugar de reiniciar Codex.

## Formato `.codextheme`

`.codextheme` es un envoltorio JSON único y versionado:

```json
{
  "format": "com.codex-theme-switcher.theme",
  "archiveVersion": 1,
  "exportedAt": "2026-07-25T00:00:00Z",
  "theme": {
    "schemaVersion": 1,
    "id": "9d9028d5-f76a-4e99-a5e5-da3533fe646d",
    "metadata": {
      "name": "My Theme",
      "author": "Author",
      "description": "",
      "version": "1.0.0",
      "tags": ["dark", "glass"],
      "createdAt": "2026-07-25T00:00:00Z",
      "updatedAt": "2026-07-25T00:00:00Z"
    },
    "layers": [],
    "assets": []
  }
}
```

Hay archivos listos para importar en
[`Examples/minimal.codextheme`](Examples/minimal.codextheme) y
[`Examples/full.codextheme`](Examples/full.codextheme). Los agentes pueden usar
[`codextheme.schema.json`](Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json) para
generar y validar JSON; las fechas siempre se emiten en formato ISO-8601, mientras que la
importación sigue siendo compatible con las fechas numéricas de versiones anteriores de
Foundation. El JSON Schema también acepta ambas formas de fecha y permite comprobar rápidamente la
estructura, las enumeraciones y los intervalos numéricos; el validador Core sigue siendo la
autoridad final para el análisis de seguridad del CSS y los límites de tamaño totales.

El orden de la theme cascade es fijo:

1. semantic variables y aliases de los Codex stable tokens
2. advanced/custom variables
3. component overrides
4. selector rules
5. reglas de fondo, paleta y glass generadas por Image Skin
6. raw CSS

Los elementos 1–4 se compilan según el orden de los layers; después Image Skin sobrescribe los
ajustes estructurados de la interfaz y el raw CSS se emite al final según el orden de los layers,
lo que convierte Raw CSS en el verdadero escape hatch final. De forma predeterminada, los
conflictos de ID durante la importación se resuelven clonando el tema con un UUID nuevo y el tema
importado no se aplica automáticamente.

Los recursos integrados se referencian en el CSS de esta forma:

```css
body {
  background-image: theme-asset("ASSET-UUID");
}
```

Durante la compilación, la referencia se reescribe de forma segura como un placeholder corto
`codex-theme-asset://`. El runtime envía los recursos a cada proceso de renderizado en fragmentos de
256 KiB y crea Blob URL dentro del proceso de renderizado antes de cambiar el estilo de forma
atómica; los recursos idénticos reutilizan el mismo Blob y las URL que ya no se utilizan se revocan
al cambiar o borrar temas.

## Datos locales

```text
~/Library/Application Support/CodexThemeSwitcher/
  Themes/                 # user theme JSON
  active-theme.json       # repository active pointer
  Runtime/
    active-theme.json     # runtime CSS template、asset manifest 與資料
    bridge-token          # mode 0600
  Logs/runtime.log
```

## Arquitectura

- `CodexThemeSwitcherCore`: esquema de tema, validador, compilador, repositorio y archivo.
- `CodexThemeRuntime`: runner Swift asíncrono y runtime Node/CDP autenticado.
- `CodexThemeSwitcher`: estudio AppKit/SwiftUI en la barra de menús.
- `codex-theme`: CLI JSON estructurada y proceso de renderizado PNG sin ventanas para agentes de IA
  y automatización.
- `Tests/`: suites de pruebas Swift.
- `test/`: suites de pruebas del runtime Node.

Las selector rules son una capa experta y pueden requerir ajustes después de las actualizaciones de
Codex. Los layers básicos y `--color-token-*` utilizan principalmente el contrato CSS actual de
Codex y dependen menos de los nombres de clases de React.
