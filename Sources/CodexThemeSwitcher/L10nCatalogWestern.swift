enum L10nCatalogWestern {
    private struct Entry {
        let key: String
        let french: String
        let spanish: String
    }

    private static let entries: [Entry] = [
        Entry(key: " Copy", french: " Copie", spanish: " Copia"),
        Entry(
            key: "16 MB per asset; 32 MB total assets; 48 MB per template",
            french: "16 Mo par ressource ; 32 Mo de ressources au total ; 48 Mo par modèle",
            spanish: "16 MB por recurso; 32 MB de recursos en total; 48 MB por plantilla"
        ),
        Entry(key: "2XL radius", french: "Rayon 2XL", spanish: "Radio 2XL"),
        Entry(key: "Accent", french: "Accentuation", spanish: "Acento"),
        Entry(key: "ACTIVE", french: "ACTIF", spanish: "ACTIVO"),
        Entry(key: "Active selection", french: "Sélection active", spanish: "Selección activa"),
        Entry(
            key: "Add a background or font and it will travel with the export.",
            french: "Ajoutez un arrière-plan ou une police : ils seront inclus dans l’exportation.",
            spanish: "Añade un fondo o una fuente y se incluirán en la exportación."
        ),
        Entry(
            key: "Add any --color-token-*, --vscode-*, or custom CSS variable",
            french: "Ajoutez toute variable --color-token-*, --vscode-* ou CSS personnalisée",
            spanish: "Añade cualquier variable --color-token-*, --vscode-* o CSS personalizada"
        ),
        Entry(key: "Add asset", french: "Ajouter une ressource", spanish: "Añadir recurso"),
        Entry(
            key: "Add component override",
            french: "Ajouter un remplacement de composant",
            spanish: "Añadir reemplazo de componente"
        ),
        Entry(
            key: "Add conditional layer",
            french: "Ajouter un calque conditionnel",
            spanish: "Añadir capa condicional"
        ),
        Entry(key: "Add CSS rule", french: "Ajouter une règle CSS", spanish: "Añadir regla CSS"),
        Entry(key: "Add declaration", french: "Ajouter une déclaration", spanish: "Añadir declaración"),
        Entry(
            key: "Add image or font",
            french: "Ajouter une image ou une police",
            spanish: "Añadir imagen o fuente"
        ),
        Entry(key: "Add token", french: "Ajouter un jeton", spanish: "Añadir token"),
        Entry(key: "Advanced Tokens", french: "Jetons avancés", spanish: "Tokens avanzados"),
        Entry(key: "All modes", french: "Tous les modes", spanish: "Todos los modos"),
        Entry(key: "Always applied", french: "Toujours appliqué", spanish: "Siempre aplicado"),
        Entry(key: "App background", french: "Arrière-plan de l’app", spanish: "Fondo de la app"),
        Entry(key: "Appearance", french: "Apparence", spanish: "Apariencia"),
        Entry(
            key: "Apply earlier (lower cascade priority)",
            french: "Appliquer plus tôt (priorité de cascade inférieure)",
            spanish: "Aplicar antes (menor prioridad de cascada)"
        ),
        Entry(
            key: "Apply later (higher cascade priority)",
            french: "Appliquer plus tard (priorité de cascade supérieure)",
            spanish: "Aplicar después (mayor prioridad de cascada)"
        ),
        Entry(
            key: "Apply or export it as-is, or make a copy to customize it.",
            french: "Appliquez ou exportez le thème tel quel, ou créez une copie pour le personnaliser.",
            spanish: "Aplícalo o expórtalo tal cual, o crea una copia para personalizarlo."
        ),
        Entry(
            key: "Arbitrary selector rules are the second escape hatch. Selectors may change across Codex updates, so document compatible versions when sharing.",
            french: "Les règles de sélecteur libres constituent la seconde option avancée. Les sélecteurs peuvent changer au fil des mises à jour de Codex ; indiquez donc les versions compatibles lors du partage.",
            spanish: "Las reglas con selectores libres son la segunda vía avanzada. Los selectores pueden cambiar con las actualizaciones de Codex; indica las versiones compatibles al compartir."
        ),
        Entry(
            key: "Attached · No theme applied",
            french: "Connecté · Aucun thème appliqué",
            spanish: "Conectado · Ningún tema aplicado"
        ),
        Entry(key: "Author", french: "Auteur", spanish: "Autor"),
        Entry(key: "Backdrop blur", french: "Flou d’arrière-plan", spanish: "Desenfoque del fondo"),
        Entry(
            key: "Background & focal point",
            french: "Arrière-plan et point focal",
            spanish: "Fondo y punto focal"
        ),
        Entry(
            key: "Background base color",
            french: "Couleur de fond de base",
            spanish: "Color base del fondo"
        ),
        Entry(key: "Base type scale", french: "Échelle typographique de base", spanish: "Escala tipográfica base"),
        Entry(
            key: "Basic motion duration",
            french: "Durée d’animation standard",
            spanish: "Duración de animación básica"
        ),
        Entry(key: "Blend mode", french: "Mode de fusion", spanish: "Modo de fusión"),
        Entry(key: "Border", french: "Bordure", spanish: "Borde"),
        Entry(key: "Border / glow", french: "Bordure / halo", spanish: "Borde / resplandor"),
        Entry(key: "Border opacity", french: "Opacité de la bordure", spanish: "Opacidad del borde"),
        Entry(key: "Border width", french: "Épaisseur de la bordure", spanish: "Grosor del borde"),
        Entry(key: "Brightness", french: "Luminosité", spanish: "Brillo"),
        Entry(
            key: "Button background",
            french: "Arrière-plan du bouton",
            spanish: "Fondo del botón"
        ),
        Entry(key: "Button icon", french: "Icône du bouton", spanish: "Icono del botón"),
        Entry(key: "BUILT-IN", french: "INTÉGRÉ", spanish: "INTEGRADO"),
        Entry(key: "Cards / menus", french: "Cartes / menus", spanish: "Tarjetas / menús"),
        Entry(
            key: "Center content panel",
            french: "Panneau de contenu central",
            spanish: "Panel de contenido central"
        ),
        Entry(
            key: "Changing mode resets to 1.00×; use Image zoom for further adjustment.",
            french: "Changer de mode réinitialise le zoom à 1,00× ; utilisez Zoom de l’image pour l’ajuster davantage.",
            spanish: "Cambiar de modo restablece el zoom a 1,00×; usa Zoom de imagen para ajustarlo más."
        ),
        Entry(key: "Chat font size", french: "Taille du texte du chat", spanish: "Tamaño de fuente del chat"),
        Entry(
            key: "Choose Launch + Attach Codex first. The first attachment may restart Codex.",
            french: "Choisissez d’abord Lancer et connecter Codex. La première connexion peut redémarrer Codex.",
            spanish: "Elige primero Iniciar y conectar Codex. La primera conexión puede reiniciar Codex."
        ),
        Entry(
            key: "Choose dark background",
            french: "Choisir l’arrière-plan sombre",
            spanish: "Elegir fondo oscuro"
        ),
        Entry(key: "Choose image", french: "Choisir une image", spanish: "Elegir imagen"),
        Entry(
            key: "Choose light background",
            french: "Choisir l’arrière-plan clair",
            spanish: "Elegir fondo claro"
        ),
        Entry(
            key: "Choose or create a theme from the library.",
            french: "Choisissez ou créez un thème dans la bibliothèque.",
            spanish: "Elige o crea un tema en la biblioteca."
        ),
        Entry(key: "Clear", french: "Effacer", spanish: "Borrar"),
        Entry(key: "Clear canvas", french: "Toile transparente", spanish: "Lienzo transparente"),
        Entry(key: "Code block", french: "Bloc de code", spanish: "Bloque de código"),
        Entry(key: "Code blocks", french: "Blocs de code", spanish: "Bloques de código"),
        Entry(key: "Code font", french: "Police du code", spanish: "Fuente del código"),
        Entry(key: "Code font size", french: "Taille du code", spanish: "Tamaño de fuente del código"),
        Entry(
            key: "Codex attached. Choose a theme, then click Apply.",
            french: "Codex est connecté. Choisissez un thème, puis cliquez sur Appliquer.",
            spanish: "Codex está conectado. Elige un tema y haz clic en Aplicar."
        ),
        Entry(key: "Codex is not attached", french: "Codex n’est pas connecté", spanish: "Codex no está conectado"),
        Entry(
            key: "Codex is running, not attached",
            french: "Codex est en cours d’exécution, mais pas connecté",
            spanish: "Codex está en ejecución, pero no conectado"
        ),
        Entry(key: "Color system", french: "Système de couleurs", spanish: "Sistema de color"),
        Entry(
            key: "Complete ANSI base palette; add bright variants under advanced tokens",
            french: "Palette ANSI de base complète ; ajoutez les variantes claires dans les jetons avancés",
            spanish: "Paleta ANSI base completa; añade las variantes brillantes en los tokens avanzados"
        ),
        Entry(
            key: "Composer / project picker",
            french: "Composer / sélecteur de projet",
            spanish: "Composer / selector de proyecto"
        ),
        Entry(
            key: "Composer primary button",
            french: "Bouton principal du Composer",
            spanish: "Botón principal del Composer"
        ),
        Entry(key: "Composer radius", french: "Rayon du Composer", spanish: "Radio del Composer"),
        Entry(
            key: "Composer tray background",
            french: "Arrière-plan de la barre du Composer",
            spanish: "Fondo de la bandeja del Composer"
        ),
        Entry(key: "Condition", french: "Condition", spanish: "Condición"),
        Entry(key: "Contrast", french: "Contraste", spanish: "Contraste"),
        Entry(
            key: "Create full-window imagery, independent light/dark treatments, focal cropping, overlays, and per-region glass. Images and settings travel inside the .codextheme.",
            french: "Créez des visuels plein écran, des traitements clair et sombre indépendants, un recadrage focal, des superpositions et un verre propre à chaque zone. Les images et réglages sont intégrés au fichier .codextheme.",
            spanish: "Crea imágenes a pantalla completa, tratamientos claro y oscuro independientes, recorte focal, superposiciones y cristal por región. Las imágenes y los ajustes viajan dentro del archivo .codextheme."
        ),
        Entry(key: "Custom rule", french: "Règle personnalisée", spanish: "Regla personalizada"),
        Entry(key: "Dark", french: "Sombre", spanish: "Oscuro"),
        Entry(key: "dark, glass, neon", french: "sombre, verre, néon", spanish: "oscuro, cristal, neón"),
        Entry(key: "Darken bottom", french: "Assombrir le bas", spanish: "Oscurecer abajo"),
        Entry(key: "Darken left", french: "Assombrir la gauche", spanish: "Oscurecer la izquierda"),
        Entry(key: "Darken right", french: "Assombrir la droite", spanish: "Oscurecer la derecha"),
        Entry(key: "Darken top", french: "Assombrir le haut", spanish: "Oscurecer arriba"),
        Entry(key: "Delete", french: "Supprimer", spanish: "Eliminar"),
        Entry(key: "Delete this theme", french: "Supprimer ce thème", spanish: "Eliminar este tema"),
        Entry(key: "Description", french: "Description", spanish: "Descripción"),
        Entry(key: "Diff added", french: "Ajout Diff", spanish: "Adición en Diff"),
        Entry(key: "Diff removed", french: "Suppression Diff", spanish: "Eliminación en Diff"),
        Entry(
            key: "Directional scrims protect navigation text; vignette darkens the edges.",
            french: "Les dégradés directionnels protègent le texte de navigation ; le vignettage assombrit les bords.",
            spanish: "Los degradados direccionales protegen el texto de navegación; la viñeta oscurece los bordes."
        ),
        Entry(key: "Dropdown", french: "Liste déroulante", spanish: "Lista desplegable"),
        Entry(
            key: "Each appearance has independent brightness, contrast, saturation, and blur.",
            french: "Chaque apparence possède ses propres réglages de luminosité, contraste, saturation et flou.",
            spanish: "Cada apariencia tiene ajustes independientes de brillo, contraste, saturación y desenfoque."
        ),
        Entry(key: "Edit theme", french: "Modifier le thème", spanish: "Editar tema"),
        Entry(key: "Editable copy created", french: "Copie modifiable créée", spanish: "Copia editable creada"),
        Entry(key: "Editing", french: "Version modifiée", spanish: "Edición"),
        Entry(key: "Editor", french: "Éditeur", spanish: "Editor"),
        Entry(key: "Effects & Motion", french: "Effets et animations", spanish: "Efectos y animación"),
        Entry(key: "Embedded Assets", french: "Ressources intégrées", spanish: "Recursos integrados"),
        Entry(key: "Enable center content panel", french: "Activer le panneau de contenu central", spanish: "Activar panel de contenido central"),
        Entry(key: "Enable image skin", french: "Activer l’habillage d’image", spanish: "Activar apariencia con imagen"),
        Entry(key: "Enabled", french: "Activé", spanish: "Activado"),
        Entry(key: "Error / delete", french: "Erreur / suppression", spanish: "Error / eliminación"),
        Entry(key: "Examples", french: "Exemples", spanish: "Ejemplos"),
        Entry(key: "Existing assets", french: "Ressources existantes", spanish: "Recursos existentes"),
        Entry(
            key: "Families, scale, line height, and tracking",
            french: "Familles, échelle, interligne et approche",
            spanish: "Familias, escala, interlineado y espaciado"
        ),
        Entry(key: "Fill", french: "Remplir", spanish: "Rellenar"),
        Entry(key: "Fill · Crop to Fill", french: "Remplir · Recadrer", spanish: "Rellenar · Recortar para llenar"),
        Entry(key: "Fill opacity", french: "Opacité du fond", spanish: "Opacidad del relleno"),
        Entry(
            key: "Fill the window and crop edges; focal point controls the crop.",
            french: "Remplit la fenêtre et recadre les bords ; le point focal détermine le recadrage.",
            spanish: "Llena la ventana y recorta los bordes; el punto focal controla el recorte."
        ),
        Entry(
            key: "Final CSS with maximum freedom. For share safety, @import and http(s)/file URLs are rejected; embedded asset macros remain available.",
            french: "CSS final offrant une liberté maximale. Pour sécuriser le partage, @import et les URL http(s)/file sont refusés ; les macros de ressources intégrées restent disponibles.",
            spanish: "CSS final con máxima libertad. Para compartir con seguridad, se rechazan @import y las URL http(s)/file; las macros de recursos integrados siguen disponibles."
        ),
        Entry(key: "Fit", french: "Ajuster", spanish: "Ajustar"),
        Entry(key: "Fit · Show Whole Image", french: "Ajuster · Afficher toute l’image", spanish: "Ajustar · Mostrar imagen completa"),
        Entry(key: "Fit Height", french: "Ajuster à la hauteur", spanish: "Ajustar a la altura"),
        Entry(key: "Fit Width", french: "Ajuster à la largeur", spanish: "Ajustar al ancho"),
        Entry(
            key: "Fit, fill, focal point, and overlays use only the main content area; the sidebar keeps its own base color and glass.",
            french: "L’ajustement, le remplissage, le point focal et les superpositions utilisent uniquement la zone de contenu principale ; la barre latérale conserve sa couleur de base et son verre.",
            spanish: "El ajuste, el relleno, el punto focal y las superposiciones solo usan el área de contenido principal; la barra lateral conserva su propio color base y cristal."
        ),
        Entry(key: "Focus ring", french: "Contour de focus", spanish: "Anillo de enfoque"),
        Entry(key: "Foundation", french: "Fondations", spanish: "Base"),
        Entry(
            key: "Foundation colors compile to stable Codex tokens. Advanced colors target individual surfaces. Fields accept HEX, Display-P3, rgba, gradients, and color-mix.",
            french: "Les couleurs de fondation sont compilées en jetons Codex stables. Les couleurs avancées ciblent des surfaces individuelles. Les champs acceptent HEX, Display-P3, rgba, les dégradés et color-mix.",
            spanish: "Los colores base se compilan en tokens estables de Codex. Los colores avanzados actúan sobre superficies individuales. Los campos aceptan HEX, Display-P3, rgba, degradados y color-mix."
        ),
        Entry(key: "Geometry & Density", french: "Géométrie et densité", spanish: "Geometría y densidad"),
        Entry(
            key: "Give the text its own fill, border, spacing, blur, and shadow.",
            french: "Attribuez au texte son propre fond, sa bordure, son espacement, son flou et son ombre.",
            spanish: "Asigna al texto su propio relleno, borde, espaciado, desenfoque y sombra."
        ),
        Entry(key: "Glass material", french: "Matériau en verre", spanish: "Material de cristal"),
        Entry(key: "Glass saturation", french: "Saturation du verre", spanish: "Saturación del cristal"),
        Entry(key: "Glass targets", french: "Zones de verre", spanish: "Objetivos del cristal"),
        Entry(key: "Global overlay", french: "Superposition globale", spanish: "Superposición global"),
        Entry(key: "Global radius", french: "Rayon global", spanish: "Radio global"),
        Entry(key: "Global tracking", french: "Approche globale", spanish: "Espaciado global"),
        Entry(key: "Gothic gold", french: "Or gothique", spanish: "Oro gótico"),
        Entry(key: "Has unsaved changes", french: "Modifications non enregistrées", spanish: "Tiene cambios sin guardar"),
        Entry(key: "Home cards", french: "Cartes d’accueil", spanish: "Tarjetas de inicio"),
        Entry(key: "Horizontal focal point", french: "Point focal horizontal", spanish: "Punto focal horizontal"),
        Entry(key: "Horizontal padding", french: "Marge intérieure horizontale", spanish: "Relleno horizontal"),
        Entry(key: "Horizontal tile origin", french: "Origine horizontale du motif", spanish: "Origen horizontal del mosaico"),
        Entry(
            key: "Hover, selection, focus, links, and changes",
            french: "Survol, sélection, focus, liens et modifications",
            spanish: "Paso del puntero, selección, enfoque, enlaces y cambios"
        ),
        Entry(
            key: "Ignore aspect ratio and stretch the image to the window.",
            french: "Ignore les proportions et étire l’image aux dimensions de la fenêtre.",
            spanish: "Ignora la relación de aspecto y estira la imagen hasta llenar la ventana."
        ),
        Entry(key: "Image blur", french: "Flou de l’image", spanish: "Desenfoque de imagen"),
        Entry(key: "Image opacity", french: "Opacité de l’image", spanish: "Opacidad de la imagen"),
        Entry(key: "Image sizing", french: "Dimensionnement de l’image", spanish: "Tamaño de imagen"),
        Entry(key: "Image treatment", french: "Traitement de l’image", spanish: "Tratamiento de imagen"),
        Entry(key: "Image zoom", french: "Zoom de l’image", spanish: "Zoom de imagen"),
        Entry(
            key: "Images, textures, GIFs, and fonts are base64-embedded in one .codextheme file. Reference them with theme-asset(\"UUID\").",
            french: "Les images, textures, GIF et polices sont intégrés en base64 dans un seul fichier .codextheme. Référencez-les avec theme-asset(\"UUID\").",
            spanish: "Las imágenes, texturas, GIF y fuentes se integran en base64 en un único archivo .codextheme. Haz referencia a ellos con theme-asset(\"UUID\")."
        ),
        Entry(
            key: "Imports validate schema, CSS safety, size, and ID collisions, and never auto-apply.",
            french: "Les importations valident le schéma, la sécurité CSS, la taille et les conflits d’identifiants, et ne sont jamais appliquées automatiquement.",
            spanish: "Las importaciones validan el esquema, la seguridad del CSS, el tamaño y las colisiones de ID, y nunca se aplican automáticamente."
        ),
        Entry(key: "Input", french: "Champ de saisie", spanish: "Campo de entrada"),
        Entry(key: "Interaction & diff", french: "Interaction et Diff", spanish: "Interacción y Diff"),
        Entry(key: "Interface zoom", french: "Zoom de l’interface", spanish: "Zoom de la interfaz"),
        Entry(
            key: "Keep wallpaper out of sidebar",
            french: "Exclure le fond d’écran de la barre latérale",
            spanish: "Excluir el fondo de pantalla de la barra lateral"
        ),
        Entry(key: "Large blur", french: "Flou important", spanish: "Desenfoque grande"),
        Entry(key: "Large radius", french: "Grand rayon", spanish: "Radio grande"),
        Entry(key: "Large shadow", french: "Grande ombre", spanish: "Sombra grande"),
        Entry(key: "Layer name", french: "Nom du calque", spanish: "Nombre de la capa"),
        Entry(key: "License", french: "Licence", spanish: "Licencia"),
        Entry(key: "Light", french: "Clair", spanish: "Claro"),
        Entry(key: "Link", french: "Lien", spanish: "Enlace"),
        Entry(key: "List hover", french: "Survol de liste", spanish: "Paso del puntero por la lista"),
        Entry(key: "Live preview", french: "Aperçu en direct", spanish: "Vista previa en vivo"),
        Entry(key: "Live simulation of Codex surfaces, conversation, code, and composer.", french: "Simulation en direct des surfaces de Codex, de la conversation, du code et du Composer.", spanish: "Simulación en vivo de las superficies de Codex, la conversación, el código y el Composer."),
        Entry(key: "Main content", french: "Contenu principal", spanish: "Contenido principal"),
        Entry(key: "Markdown font size", french: "Taille de police Markdown", spanish: "Tamaño de fuente Markdown"),
        Entry(key: "Markdown line height", french: "Interligne Markdown", spanish: "Interlineado Markdown"),
        Entry(
            key: "Match the window height and preserve aspect ratio.",
            french: "S’adapte à la hauteur de la fenêtre tout en conservant les proportions.",
            spanish: "Se ajusta a la altura de la ventana y conserva la relación de aspecto."
        ),
        Entry(
            key: "Match the window width and preserve aspect ratio.",
            french: "S’adapte à la largeur de la fenêtre tout en conservant les proportions.",
            spanish: "Se ajusta al ancho de la ventana y conserva la relación de aspecto."
        ),
        Entry(key: "Maximum width", french: "Largeur maximale", spanish: "Ancho máximo"),
        Entry(key: "Menu", french: "Menu", spanish: "Menú"),
        Entry(key: "MENU BAR STUDIO", french: "STUDIO DE BARRE DES MENUS", spanish: "ESTUDIO DE BARRA DE MENÚS"),
        Entry(key: "Menus / popovers", french: "Menus / fenêtres contextuelles", spanish: "Menús / ventanas emergentes"),
        Entry(
            key: "Metadata travels with exports for attribution, versioning, and compatibility notes.",
            french: "Les métadonnées accompagnent les exportations pour l’attribution, la gestion des versions et les notes de compatibilité.",
            spanish: "Los metadatos se incluyen en las exportaciones para la atribución, el control de versiones y las notas de compatibilidad."
        ),
        Entry(key: "Name", french: "Nom", spanish: "Nombre"),
        Entry(key: "New conditional layer", french: "Nouveau calque conditionnel", spanish: "Nueva capa condicional"),
        Entry(key: "New theme created", french: "Nouveau thème créé", spanish: "Tema nuevo creado"),
        Entry(key: "No embedded assets", french: "Aucune ressource intégrée", spanish: "No hay recursos integrados"),
        Entry(key: "No image selected", french: "Aucune image sélectionnée", spanish: "Ninguna imagen seleccionada"),
        Entry(key: "No theme selected", french: "Aucun thème sélectionné", spanish: "Ningún tema seleccionado"),
        Entry(
            key: "No theme will be applied automatically. Choose one and click Apply after attaching. Codex may restart if CDP is not enabled.",
            french: "Aucun thème ne sera appliqué automatiquement. Après la connexion, choisissez-en un et cliquez sur Appliquer. Codex peut redémarrer si CDP n’est pas activé.",
            spanish: "No se aplicará ningún tema automáticamente. Tras conectar, elige uno y haz clic en Aplicar. Codex puede reiniciarse si CDP no está habilitado."
        ),
        Entry(key: "None", french: "Aucun", spanish: "Ninguno"),
        Entry(key: "Nothing to redo", french: "Aucune action à rétablir", spanish: "Nada que rehacer"),
        Entry(key: "Nothing to undo", french: "Aucune action à annuler", spanish: "Nada que deshacer"),
        Entry(
            key: "One file contains the theme, CSS, and every asset",
            french: "Un seul fichier contient le thème, le CSS et toutes les ressources",
            spanish: "Un único archivo contiene el tema, el CSS y todos los recursos"
        ),
        Entry(
            key: "Only the material background becomes translucent; child text keeps full opacity.",
            french: "Seul l’arrière-plan du matériau devient translucide ; le texte enfant conserve son opacité maximale.",
            spanish: "Solo el fondo del material se vuelve translúcido; el texto interno conserva la opacidad completa."
        ),
        Entry(key: "Opacity", french: "Opacité", spanish: "Opacidad"),
        Entry(key: "Original", french: "Taille d’origine", spanish: "Original"),
        Entry(
            key: "Overlay & legibility",
            french: "Superposition et lisibilité",
            spanish: "Superposición y legibilidad"
        ),
        Entry(key: "Overlay opacity", french: "Opacité de la superposition", spanish: "Opacidad de la superposición"),
        Entry(key: "Panel border", french: "Bordure du panneau", spanish: "Borde del panel"),
        Entry(key: "Panel fill", french: "Fond du panneau", spanish: "Relleno del panel"),
        Entry(key: "Panel radius", french: "Rayon du panneau", spanish: "Radio del panel"),
        Entry(
            key: "Per-region glass color",
            french: "Couleur du verre par zone",
            spanish: "Color del cristal por región"
        ),
        Entry(
            key: "Preserve aspect ratio and fill the window; overflow is cropped.",
            french: "Conserve les proportions et remplit la fenêtre ; le débordement est recadré.",
            spanish: "Conserva la relación de aspecto y llena la ventana; el contenido sobrante se recorta."
        ),
        Entry(key: "Preview surface", french: "Surface d’aperçu", spanish: "Superficie de vista previa"),
        Entry(key: "Primary text", french: "Texte principal", spanish: "Texto principal"),
        Entry(key: "Image focal point", french: "Point focal de l’image", spanish: "Punto focal de la imagen"),
        Entry(key: "Quick focal point", french: "Point focal rapide", spanish: "Punto focal rápido"),
        Entry(key: "Quick styles", french: "Styles rapides", spanish: "Estilos rápidos"),
        Entry(
            key: "Radius, spacing, density, and content width",
            french: "Rayon, espacement, densité et largeur du contenu",
            spanish: "Radio, espaciado, densidad y ancho del contenido"
        ),
        Entry(key: "Readability scrim", french: "Dégradé de lisibilité", spanish: "Degradado de legibilidad"),
        Entry(key: "Redo", french: "Rétablir", spanish: "Rehacer"),
        Entry(
            key: "Relaxed motion duration",
            french: "Durée d’animation détendue",
            spanish: "Duración de animación suave"
        ),
        Entry(key: "Remove skin", french: "Supprimer l’habillage", spanish: "Quitar apariencia"),
        Entry(
            key: "Repeat the image; zoom controls tile size.",
            french: "Répète l’image ; le zoom contrôle la taille des tuiles.",
            spanish: "Repite la imagen; el zoom controla el tamaño de los mosaicos."
        ),
        Entry(
            key: "Replace the UUID with the value shown above",
            french: "Remplacez l’UUID par la valeur affichée ci-dessus",
            spanish: "Sustituye el UUID por el valor mostrado arriba"
        ),
        Entry(
            key: "Restored the original Codex style",
            french: "Style d’origine de Codex restauré",
            spanish: "Se restauró el estilo original de Codex"
        ),
        Entry(
            key: "Row horizontal padding",
            french: "Marge intérieure horizontale des lignes",
            spanish: "Relleno horizontal de filas"
        ),
        Entry(
            key: "Row vertical padding",
            french: "Marge intérieure verticale des lignes",
            spanish: "Relleno vertical de filas"
        ),
        Entry(key: "Rule name", french: "Nom de la règle", spanish: "Nombre de la regla"),
        Entry(key: "Runtime unavailable", french: "Runtime indisponible", spanish: "Runtime no disponible"),
        Entry(key: "Saturation", french: "Saturation", spanish: "Saturación"),
        Entry(key: "Scrim strength", french: "Intensité du dégradé", spanish: "Intensidad del degradado"),
        Entry(key: "Scrollbar", french: "Barre de défilement", spanish: "Barra de desplazamiento"),
        Entry(key: "Search themes", french: "Rechercher des thèmes", spanish: "Buscar temas"),
        Entry(
            key: "Secondary background",
            french: "Arrière-plan secondaire",
            spanish: "Fondo secundario"
        ),
        Entry(key: "Secondary text", french: "Texte secondaire", spanish: "Texto secundario"),
        Entry(
            key: "Selectors are aligned with the current Codex 26 DOM.",
            french: "Les sélecteurs sont adaptés au DOM actuel de Codex 26.",
            spanish: "Los selectores están adaptados al DOM actual de Codex 26."
        ),
        Entry(key: "selectors, comma-separated", french: "sélecteurs, séparés par des virgules", spanish: "selectores, separados por comas"),
        Entry(key: "Shadow blur", french: "Flou de l’ombre", spanish: "Desenfoque de la sombra"),
        Entry(key: "Shadow color", french: "Couleur de l’ombre", spanish: "Color de la sombra"),
        Entry(key: "Shadow offset X", french: "Décalage horizontal de l’ombre", spanish: "Desplazamiento X de la sombra"),
        Entry(key: "Shadow offset Y", french: "Décalage vertical de l’ombre", spanish: "Desplazamiento Y de la sombra"),
        Entry(key: "Shadow opacity", french: "Opacité de l’ombre", spanish: "Opacidad de la sombra"),
        Entry(key: "Share template", french: "Partager le modèle", spanish: "Compartir plantilla"),
        Entry(
            key: "Shared by the enabled Codex regions.",
            french: "Partagé par les zones Codex activées.",
            spanish: "Compartido por las regiones de Codex habilitadas."
        ),
        Entry(
            key: "Show the whole image with its aspect ratio; empty space uses the base color.",
            french: "Affiche toute l’image en conservant ses proportions ; l’espace vide utilise la couleur de base.",
            spanish: "Muestra la imagen completa conservando su relación de aspecto; el espacio vacío usa el color base."
        ),
        Entry(
            key: "Show the whole image; empty space uses the base color.",
            french: "Affiche toute l’image ; l’espace vide utilise la couleur de base.",
            spanish: "Muestra la imagen completa; el espacio vacío usa el color base."
        ),
        Entry(key: "Sidebar", french: "Barre latérale", spanish: "Barra lateral"),
        Entry(
            key: "Sidebar, inputs, menus, code, and terminal",
            french: "Barre latérale, champs, menus, code et terminal",
            spanish: "Barra lateral, campos, menús, código y terminal"
        ),
        Entry(key: "Soft glass", french: "Verre doux", spanish: "Cristal suave"),
        Entry(key: "Spacing scale", french: "Échelle d’espacement", spanish: "Escala de espaciado"),
        Entry(
            key: "Stop theme runtime",
            french: "Arrêter le runtime de thème",
            spanish: "Detener el runtime de temas"
        ),
        Entry(key: "Stretch", french: "Étirer", spanish: "Estirar"),
        Entry(key: "Success", french: "Succès", spanish: "Éxito"),
        Entry(key: "Surface", french: "Surface", spanish: "Superficie"),
        Entry(key: "Surface / bubble", french: "Surface / bulle", spanish: "Superficie / burbuja"),
        Entry(key: "Surfaces", french: "Surfaces", spanish: "Superficies"),
        Entry(
            key: "Switch between Home and Chat to inspect the center-panel boundary. Glass is approximated here; Codex uses the exact blur / saturation values.",
            french: "Basculez entre Accueil et Chat pour vérifier les limites du panneau central. Le verre est approximé ici ; Codex utilise les valeurs exactes de flou et de saturation.",
            spanish: "Alterna entre Inicio y Chat para revisar los límites del panel central. Aquí el cristal es aproximado; Codex usa los valores exactos de desenfoque y saturación."
        ),
        Entry(key: "Tags", french: "Étiquettes", spanish: "Etiquetas"),
        Entry(key: "Terminal / Syntax Palette", french: "Terminal / palette syntaxique", spanish: "Terminal / paleta de sintaxis"),
        Entry(key: "Terminal background", french: "Arrière-plan du Terminal", spanish: "Fondo del Terminal"),
        Entry(key: "Terminal text", french: "Texte du Terminal", spanish: "Texto del Terminal"),
        Entry(key: "Text selection", french: "Sélection de texte", spanish: "Selección de texto"),
        Entry(key: "Text shadow", french: "Ombre du texte", spanish: "Sombra del texto"),
        Entry(
            key: "The most portable layer for shared themes",
            french: "La couche la plus portable pour les thèmes partagés",
            spanish: "La capa más portable para temas compartidos"
        ),
        Entry(
            key: "The preview uses the same theme data; verify expert selector rules in Codex.",
            french: "L’aperçu utilise les mêmes données de thème ; vérifiez les règles de sélecteur expertes dans Codex.",
            spanish: "La vista previa usa los mismos datos del tema; comprueba las reglas avanzadas de selectores en Codex."
        ),
        Entry(
            key: "The wallpaper uses a click-through pseudo-element and never blocks Codex controls.",
            french: "Le fond d’écran utilise un pseudo-élément transparent aux clics et ne bloque jamais les commandes de Codex.",
            spanish: "El fondo de pantalla usa un pseudoelemento que deja pasar los clics y nunca bloquea los controles de Codex."
        ),
        Entry(key: "Theme deleted", french: "Thème supprimé", spanish: "Tema eliminado"),
        Entry(key: "Theme metadata", french: "Métadonnées du thème", spanish: "Metadatos del tema"),
        Entry(key: "Theme saved", french: "Thème enregistré", spanish: "Tema guardado"),
        Entry(
            key: "Theme template exported",
            french: "Modèle de thème exporté",
            spanish: "Plantilla de tema exportada"
        ),
        Entry(
            key: "This is a built-in template",
            french: "Il s’agit d’un modèle intégré",
            spanish: "Esta es una plantilla integrada"
        ),
        Entry(key: "Thread max width", french: "Largeur maximale du fil", spanish: "Ancho máximo del hilo"),
        Entry(key: "Tile", french: "Répéter", spanish: "Mosaico"),
        Entry(
            key: "Tint, shadow, blur, zoom, and motion",
            french: "Teinte, ombre, flou, zoom et animation",
            spanish: "Tinte, sombra, desenfoque, zoom y animación"
        ),
        Entry(key: "Titlebar", french: "Barre de titre", spanish: "Barra de título"),
        Entry(key: "Titlebar tint", french: "Teinte de la barre de titre", spanish: "Tinte de la barra de título"),
        Entry(key: "Toolbar height", french: "Hauteur de la barre d’outils", spanish: "Altura de la barra de herramientas"),
        Entry(key: "Typography", french: "Typographie", spanish: "Tipografía"),
        Entry(key: "UI font", french: "Police de l’interface", spanish: "Fuente de la interfaz"),
        Entry(key: "Undo", french: "Annuler", spanish: "Deshacer"),
        Entry(key: "Unknown author", french: "Auteur inconnu", spanish: "Autor desconocido"),
        Entry(key: "Untitled Theme", french: "Thème sans titre", spanish: "Tema sin título"),
        Entry(
            key: "Use automatic colors",
            french: "Utiliser les couleurs automatiques",
            spanish: "Usar colores automáticos"
        ),
        Entry(
            key: "Use catalog components (app, sidebar, composer, codeBlock…) or supply any selectors. Property/value pairs are unrestricted.",
            french: "Utilisez les composants du catalogue (app, sidebar, composer, codeBlock…) ou fournissez vos propres sélecteurs. Les paires propriété/valeur ne sont pas limitées.",
            spanish: "Usa componentes del catálogo (app, sidebar, composer, codeBlock…) o proporciona cualquier selector. Los pares propiedad/valor no tienen restricciones."
        ),
        Entry(
            key: "Unset colors follow Primary text and Cards / menus.",
            french: "Les couleurs non définies suivent Texte principal et Cartes / menus.",
            spanish: "Los colores no definidos siguen Texto principal y Tarjetas / menús."
        ),
        Entry(
            key: "Use the image's natural size; focal point controls placement.",
            french: "Utilise la taille naturelle de l’image ; le point focal détermine son placement.",
            spanish: "Usa el tamaño natural de la imagen; el punto focal controla la posición."
        ),
        Entry(
            key: "Values map directly to Codex tokens, so variable fonts, clamp(), calc(), custom shadows, and motion are all supported.",
            french: "Les valeurs correspondent directement aux jetons Codex ; les polices variables, clamp(), calc(), les ombres personnalisées et les animations sont donc pris en charge.",
            spanish: "Los valores se asignan directamente a los tokens de Codex, por lo que se admiten fuentes variables, clamp(), calc(), sombras personalizadas y animaciones."
        ),
        Entry(key: "Version", french: "Version", spanish: "Versión"),
        Entry(key: "Vertical focal point", french: "Point focal vertical", spanish: "Punto focal vertical"),
        Entry(key: "Vertical padding", french: "Marge intérieure verticale", spanish: "Relleno vertical"),
        Entry(key: "Vertical tile origin", french: "Origine verticale du motif", spanish: "Origen vertical del mosaico"),
        Entry(key: "Vignette", french: "Vignettage", spanish: "Viñeta"),
        Entry(key: "Warning", french: "Avertissement", spanish: "Advertencia"),
        Entry(key: "Wide block max width", french: "Largeur maximale des blocs larges", spanish: "Ancho máximo de bloques amplios"),
        Entry(
            key: "Wraps only the Home heading or Chat transcript, without changing suggestion cards, the Composer, or the full main-content background.",
            french: "Entoure uniquement l’en-tête d’Accueil ou la transcription du Chat, sans modifier les cartes de suggestion, le Composer ni l’arrière-plan complet du contenu principal.",
            spanish: "Envuelve solo el encabezado de Inicio o la conversación del Chat, sin cambiar las tarjetas de sugerencias, el Composer ni el fondo completo del contenido principal."
        ),

        // User-facing repository, archive, validation, and runtime errors.
        Entry(
            key: "Operation failed: {0}",
            french: "Échec de l’opération : {0}",
            spanish: "La operación falló: {0}"
        ),
        Entry(
            key: "The Codex app could not be found.",
            french: "L’app Codex est introuvable.",
            spanish: "No se encontró la app Codex."
        ),
        Entry(
            key: "The selected application is not a valid Codex app.",
            french: "L’application sélectionnée n’est pas une app Codex valide.",
            spanish: "La aplicación seleccionada no es una app Codex válida."
        ),
        Entry(
            key: "No attachable Codex renderer was found.",
            french: "Aucun processus de rendu Codex disponible pour la connexion n’a été trouvé.",
            spanish: "No se encontró ningún proceso de renderizado de Codex al que conectarse."
        ),
        Entry(
            key: "Could not communicate with the Codex renderer.",
            french: "Impossible de communiquer avec le processus de rendu Codex.",
            spanish: "No se pudo comunicar con el proceso de renderizado de Codex."
        ),
        Entry(
            key: "The theme data is too large.",
            french: "Les données du thème sont trop volumineuses.",
            spanish: "Los datos del tema son demasiado grandes."
        ),
        Entry(
            key: "The theme data is invalid.",
            french: "Les données du thème sont invalides.",
            spanish: "Los datos del tema no son válidos."
        ),
        Entry(
            key: "A theme asset is invalid.",
            french: "Une ressource du thème est invalide.",
            spanish: "Un recurso del tema no es válido."
        ),
        Entry(
            key: "A theme asset is too large.",
            french: "Une ressource du thème est trop volumineuse.",
            spanish: "Un recurso del tema es demasiado grande."
        ),
        Entry(
            key: "The theme assets are too large in total.",
            french: "La taille totale des ressources du thème est trop importante.",
            spanish: "El tamaño total de los recursos del tema es demasiado grande."
        ),
        Entry(
            key: "The theme references a missing asset.",
            french: "Le thème référence une ressource manquante.",
            spanish: "El tema hace referencia a un recurso que falta."
        ),
        Entry(
            key: "The theme contains an unreferenced asset.",
            french: "Le thème contient une ressource non référencée.",
            spanish: "El tema contiene un recurso sin referencias."
        ),
        Entry(
            key: "The theme CSS contains unsafe content.",
            french: "Le CSS du thème contient du contenu non sécurisé.",
            spanish: "El CSS del tema contiene contenido no seguro."
        ),
        Entry(
            key: "The runtime rejected the request.",
            french: "Le runtime a refusé la requête.",
            spanish: "El runtime rechazó la solicitud."
        ),
        Entry(
            key: "The runtime endpoint was not found.",
            french: "Le point de terminaison du runtime est introuvable.",
            spanish: "No se encontró el punto de conexión del runtime."
        ),
        Entry(
            key: "The runtime command is invalid.",
            french: "La commande du runtime est invalide.",
            spanish: "El comando del runtime no es válido."
        ),
        Entry(
            key: "Could not communicate with Codex.",
            french: "Impossible de communiquer avec Codex.",
            spanish: "No se pudo comunicar con Codex."
        ),
        Entry(
            key: "The Codex runtime operation failed.",
            french: "L’opération du runtime Codex a échoué.",
            spanish: "La operación del runtime de Codex falló."
        ),
        Entry(
            key: "The bundled Codex Theme runtime helper was not found.",
            french: "L’utilitaire du runtime Codex Theme intégré est introuvable.",
            spanish: "No se encontró la herramienta incluida del runtime Codex Theme."
        ),
        Entry(
            key: "A compatible Node.js runtime was not found.",
            french: "Aucun runtime Node.js compatible n’a été trouvé.",
            spanish: "No se encontró un runtime Node.js compatible."
        ),
        Entry(
            key: "Theme {0} was not found.",
            french: "Le thème {0} est introuvable.",
            spanish: "No se encontró el tema {0}."
        ),
        Entry(
            key: "Theme {0} already exists.",
            french: "Le thème {0} existe déjà.",
            spanish: "El tema {0} ya existe."
        ),
        Entry(
            key: "Built-in theme {0} cannot be replaced.",
            french: "Le thème intégré {0} ne peut pas être remplacé.",
            spanish: "El tema integrado {0} no se puede reemplazar."
        ),
        Entry(
            key: "Built-in theme {0} cannot be deleted.",
            french: "Le thème intégré {0} ne peut pas être supprimé.",
            spanish: "El tema integrado {0} no se puede eliminar."
        ),
        Entry(
            key: "Theme file {0} is corrupt or unsupported.",
            french: "Le fichier de thème {0} est corrompu ou non pris en charge.",
            spanish: "El archivo de tema {0} está dañado o no es compatible."
        ),
        Entry(
            key: "Theme {0} cannot be made active because it does not exist.",
            french: "Le thème {0} ne peut pas être activé, car il n’existe pas.",
            spanish: "El tema {0} no se puede activar porque no existe."
        ),
        Entry(
            key: "The theme archive is {0} bytes; the maximum is {1} bytes.",
            french: "L’archive du thème fait {0} octets ; la taille maximale est de {1} octets.",
            spanish: "El archivo del tema ocupa {0} bytes; el máximo es de {1} bytes."
        ),
        Entry(
            key: "Unsupported theme archive format: {0}.",
            french: "Format d’archive de thème non pris en charge : {0}.",
            spanish: "Formato de archivo de tema no compatible: {0}."
        ),
        Entry(
            key: "Unsupported theme archive version: {0}.",
            french: "Version d’archive de thème non prise en charge : {0}.",
            spanish: "Versión de archivo de tema no compatible: {0}."
        ),
        Entry(
            key: "The theme archive could not be read.",
            french: "Impossible de lire l’archive du thème.",
            spanish: "No se pudo leer el archivo del tema."
        ),
        Entry(
            key: "CSS references missing theme asset {0}.",
            french: "Le CSS référence la ressource de thème manquante {0}.",
            spanish: "El CSS hace referencia al recurso de tema ausente {0}."
        ),
        Entry(
            key: "Malformed theme asset reference: {0}",
            french: "Référence de ressource de thème incorrecte : {0}",
            spanish: "Referencia de recurso de tema con formato incorrecto: {0}"
        ),
        Entry(
            key: "Theme validation failed.",
            french: "La validation du thème a échoué.",
            spanish: "La validación del tema falló."
        ),
        Entry(
            key: "Theme validation failed. Check: {0}",
            french: "La validation du thème a échoué. Vérifiez : {0}",
            spanish: "La validación del tema falló. Comprueba: {0}"
        ),

        // Primary app navigation and actions.
        Entry(
            key: "Codex Theme Switcher",
            french: "Sélecteur de thèmes Codex",
            spanish: "Selector de temas de Codex"
        ),
        Entry(key: "Themes", french: "Thèmes", spanish: "Temas"),
        Entry(key: "Preview", french: "Aperçu", spanish: "Vista previa"),
        Entry(key: "Skin", french: "Habillage", spanish: "Apariencia"),
        Entry(key: "Colors", french: "Couleurs", spanish: "Colores"),
        Entry(
            key: "Type & Layout",
            french: "Typographie et mise en page",
            spanish: "Tipografía y diseño"
        ),
        Entry(key: "Components", french: "Composants", spanish: "Componentes"),
        Entry(key: "Rules", french: "Règles", spanish: "Reglas"),
        Entry(key: "Advanced CSS", french: "CSS avancé", spanish: "CSS avanzado"),
        Entry(key: "Assets", french: "Ressources", spanish: "Recursos"),
        Entry(key: "Info", french: "Informations", spanish: "Información"),
        Entry(key: "Apply", french: "Appliquer", spanish: "Aplicar"),
        Entry(key: "Save", french: "Enregistrer", spanish: "Guardar"),
        Entry(key: "Rename", french: "Renommer", spanish: "Cambiar nombre"),
        Entry(
            key: "Rename theme",
            french: "Renommer le thème",
            spanish: "Cambiar el nombre del tema"
        ),
        Entry(key: "Theme name", french: "Nom du thème", spanish: "Nombre del tema"),
        Entry(
            key: "Make editable copy",
            french: "Créer une copie modifiable",
            spanish: "Crear copia editable"
        ),
        Entry(key: "Import", french: "Importer", spanish: "Importar"),
        Entry(key: "Export", french: "Exporter", spanish: "Exportar"),
        Entry(
            key: "Launch + Attach Codex",
            french: "Lancer et connecter Codex",
            spanish: "Iniciar y conectar Codex"
        ),
        Entry(
            key: "Restore Codex style",
            french: "Restaurer le style de Codex",
            spanish: "Restaurar el estilo de Codex"
        ),
        Entry(key: "Quit", french: "Quitter", spanish: "Salir"),
        Entry(key: "New theme", french: "Nouveau thème", spanish: "Nuevo tema"),

        // Additional strings shown directly by the live preview and blend controls.
        Entry(key: "New task", french: "Nouvelle tâche", spanish: "Nueva tarea"),
        Entry(key: "Scheduled", french: "Planifié", spanish: "Programado"),
        Entry(key: "Plugins", french: "Extensions", spanish: "Complementos"),
        Entry(
            key: "Pull requests",
            french: "Demandes d’intégration",
            spanish: "Solicitudes de cambios"
        ),
        Entry(key: "Select project", french: "Sélectionner un projet", spanish: "Seleccionar proyecto"),
        Entry(key: "Composer", french: "Composer", spanish: "Composer"),
        Entry(key: "Custom", french: "Personnalisé", spanish: "Personalizado"),
        Entry(
            key: "Image skin studio",
            french: "Atelier d’habillage visuel",
            spanish: "Estudio de apariencia con imágenes"
        ),
        Entry(
            key: "Shareable templates",
            french: "Modèles partageables",
            spanish: "Plantillas para compartir"
        ),
        Entry(key: "Normal", french: "Normal", spanish: "Normal"),
        Entry(key: "Multiply", french: "Produit", spanish: "Multiplicar"),
        Entry(key: "Screen", french: "Superposition", spanish: "Trama"),
        Entry(key: "Overlay", french: "Incrustation", spanish: "Superponer"),
        Entry(key: "Soft Light", french: "Lumière tamisée", spanish: "Luz suave"),
        Entry(key: "CSS value", french: "Valeur CSS", spanish: "Valor CSS"),
        Entry(key: "CSS color", french: "Couleur CSS", spanish: "Color CSS"),
        Entry(key: "Property", french: "Propriété", spanish: "Propiedad"),
        Entry(key: "Always", french: "Toujours", spanish: "Siempre"),
        Entry(key: "Base", french: "Base", spanish: "Base"),

        // Canonical format keys for dynamic messages.
        Entry(key: "Undo: {0} (⌘Z)", french: "Annuler : {0} (⌘Z)", spanish: "Deshacer: {0} (⌘Z)"),
        Entry(key: "Redo: {0} (⇧⌘Z)", french: "Rétablir : {0} (⇧⌘Z)", spanish: "Rehacer: {0} (⇧⌘Z)"),
        Entry(
            key: "{0} component overrides",
            french: "{0} remplacements de composant",
            spanish: "{0} reemplazos de componentes"
        ),
        Entry(
            key: "{0} component override",
            french: "{0} remplacement de composant",
            spanish: "{0} reemplazo de componente"
        ),
        Entry(key: "{0} · {1} rule", french: "{0} · {1} règle", spanish: "{0} · {1} regla"),
        Entry(key: "{0} · {1} rules", french: "{0} · {1} règles", spanish: "{0} · {1} reglas"),
        Entry(key: "Undo {0}", french: "Annuler {0}", spanish: "Deshacer {0}"),
        Entry(key: "Redo {0}", french: "Rétablir {0}", spanish: "Rehacer {0}"),
        Entry(
            key: "Attached · “{0}” active",
            french: "Connecté · « {0} » actif",
            spanish: "Conectado · «{0}» activo"
        ),
        Entry(
            key: "Attaching will restore “{0}”. Codex may restart if CDP is not enabled.",
            french: "La connexion restaurera « {0} ». Codex peut redémarrer si CDP n’est pas activé.",
            spanish: "Al conectar se restaurará «{0}». Codex puede reiniciarse si CDP no está habilitado."
        ),
        Entry(
            key: "Codex attached. Restored “{0}”.",
            french: "Codex est connecté. « {0} » a été restauré.",
            spanish: "Codex está conectado. Se restauró «{0}»."
        ),
        Entry(key: "Applied “{0}”", french: "« {0} » appliqué", spanish: "Se aplicó «{0}»"),
        Entry(key: "Imported “{0}”", french: "« {0} » importé", spanish: "Se importó «{0}»"),
        Entry(
            key: "Asset “{0}” is larger than 16 MB.",
            french: "La ressource « {0} » dépasse 16 Mo.",
            spanish: "El recurso «{0}» supera los 16 MB."
        ),
        Entry(
            key: "Assets would total {0}, above the 32 MB limit.",
            french: "Les ressources totaliseraient {0}, au-delà de la limite de 32 Mo.",
            spanish: "Los recursos sumarían {0}, por encima del límite de 32 MB."
        ),
        Entry(
            key: "“{0}” is not a decodable PNG, JPEG, WebP, GIF, or AVIF image.",
            french: "« {0} » n’est pas une image PNG, JPEG, WebP, GIF ou AVIF décodable.",
            spanish: "«{0}» no es una imagen PNG, JPEG, WebP, GIF o AVIF que se pueda decodificar."
        ),
        Entry(
            key: "Added {0} asset",
            french: "{0} ressource ajoutée",
            spanish: "{0} recurso añadido"
        ),
        Entry(
            key: "Added {0} assets",
            french: "{0} ressources ajoutées",
            spanish: "{0} recursos añadidos"
        ),
        Entry(
            key: "{0} background set",
            french: "Arrière-plan {0} défini",
            spanish: "Fondo {0} establecido"
        ),
        Entry(
            key: "Copy {0} to {1}",
            french: "Copier {0} vers {1}",
            spanish: "Copiar {0} a {1}"
        ),
        Entry(key: "Copy to {0}", french: "Copier vers {0}", spanish: "Copiar a {0}"),

        // Strings rendered by the live preview.
        Entry(key: "Home", french: "Accueil", spanish: "Inicio"),
        Entry(key: "Chat", french: "Discussion", spanish: "Chat"),
        Entry(key: "Projects", french: "Projets", spanish: "Proyectos"),
        Entry(key: "Settings", french: "Réglages", spanish: "Ajustes"),
        Entry(key: "About {0}", french: "À propos de {0}", spanish: "Acerca de {0}"),
        Entry(
            key: "What should we build?",
            french: "Que devons-nous créer ?",
            spanish: "¿Qué deberíamos crear?"
        ),
        Entry(
            key: "Explore and understand code",
            french: "Explorer et comprendre le code",
            spanish: "Explorar y comprender el código"
        ),
        Entry(
            key: "Build a new feature",
            french: "Créer une nouvelle fonctionnalité",
            spanish: "Crear una nueva funcionalidad"
        ),
        Entry(
            key: "Review and suggest changes",
            french: "Examiner et suggérer des modifications",
            spanish: "Revisar y sugerir cambios"
        ),
        Entry(
            key: "Fix issues and failures",
            french: "Corriger les problèmes et les erreurs",
            spanish: "Corregir problemas y fallos"
        ),
        Entry(
            key: "Ask Codex anything",
            french: "Demandez ce que vous voulez à Codex",
            spanish: "Pregúntale lo que quieras a Codex"
        ),
        Entry(
            key: "Do anything",
            french: "Que souhaitez-vous faire ?",
            spanish: "¿Qué quieres hacer?"
        ),
        Entry(key: "Theme applied", french: "Thème appliqué", spanish: "Tema aplicado"),
        Entry(
            key: "All open Codex renderer surfaces are synchronized.",
            french: "Toutes les surfaces de rendu Codex ouvertes sont synchronisées.",
            spanish: "Todas las superficies de renderizado de Codex abiertas están sincronizadas."
        ),
        Entry(
            key: "Make the customization as flexible as possible.",
            french: "Rendez la personnalisation aussi flexible que possible.",
            spanish: "Haz que la personalización sea lo más flexible posible."
        ),
        Entry(
            key: "I’ll turn this into a menu bar app with live theme switching, a visual skin editor, and portable templates.",
            french: "Je vais en faire une app de barre des menus avec changement de thème en direct, éditeur visuel d’habillage et modèles portables.",
            spanish: "Lo convertiré en una app de barra de menús con cambio de tema en vivo, editor visual de apariencia y plantillas portátiles."
        ),
        Entry(
            key: "Manage the interface language, Codex application, and update preferences.",
            french: "Gérez la langue de l’interface, l’emplacement de l’app Codex et les préférences de mise à jour.",
            spanish: "Gestiona el idioma de la interfaz, la ubicación de la app Codex y las preferencias de actualización."
        ),
        Entry(key: "Current version", french: "Version actuelle", spanish: "Versión actual"),
        Entry(key: "Version {0} ({1})", french: "Version {0} ({1})", spanish: "Versión {0} ({1})"),
        Entry(
            key: "Automatic update checks",
            french: "Recherche automatique des mises à jour",
            spanish: "Comprobaciones automáticas de actualizaciones"
        ),
        Entry(
            key: "Checks at launch and every 30 minutes.",
            french: "Vérifie au lancement, puis toutes les 30 minutes.",
            spanish: "Busca actualizaciones al iniciar y cada 30 minutos."
        ),
        Entry(key: "Update channel", french: "Canal de mise à jour", spanish: "Canal de actualización"),
        Entry(key: "Stable", french: "Stable", spanish: "Estable"),
        Entry(key: "Beta", french: "Bêta", spanish: "Beta"),
        Entry(key: "Recommended releases.", french: "Versions recommandées.", spanish: "Versiones recomendadas."),
        Entry(
            key: "Prerelease builds may be less stable.",
            french: "Les versions préliminaires peuvent être moins stables.",
            spanish: "Las versiones preliminares pueden ser menos estables."
        ),
        Entry(
            key: "Check for Updates…",
            french: "Rechercher les mises à jour…",
            spanish: "Buscar actualizaciones…"
        ),
        Entry(
            key: "Checking for updates…",
            french: "Recherche de mises à jour…",
            spanish: "Buscando actualizaciones…"
        ),
        Entry(
            key: "You're up to date ({0}).",
            french: "Vous utilisez la dernière version ({0}).",
            spanish: "Estás al día ({0})."
        ),
        Entry(
            key: "Version {0} is available.",
            french: "La version {0} est disponible.",
            spanish: "La versión {0} está disponible."
        ),
        Entry(
            key: "Update check failed: {0}",
            french: "Échec de la recherche de mises à jour : {0}",
            spanish: "Error al buscar actualizaciones: {0}"
        ),
        Entry(
            key: "Update available",
            french: "Mise à jour disponible",
            spanish: "Actualización disponible"
        ),
        Entry(
            key: "Install update",
            french: "Installer la mise à jour",
            spanish: "Instalar actualización"
        ),
        Entry(
            key: "Download manually",
            french: "Télécharger manuellement",
            spanish: "Descargar manualmente"
        ),
        Entry(
            key: "Skip this version",
            french: "Ignorer cette version",
            spanish: "Omitir esta versión"
        ),
        Entry(key: "Later", french: "Plus tard", spanish: "Más tarde"),
        Entry(key: "Release notes", french: "Notes de version", spanish: "Notas de la versión"),
        Entry(
            key: "No release notes were provided.",
            french: "Aucune note de version n’a été fournie.",
            spanish: "No se proporcionaron notas de la versión."
        ),
        Entry(key: "Published {0}", french: "Publié le {0}", spanish: "Publicado el {0}"),
        Entry(key: "Powered by Sparkle", french: "Propulsé par Sparkle", spanish: "Con tecnología de Sparkle"),
        Entry(
            key: "Show What's New",
            french: "Afficher les nouveautés",
            spanish: "Mostrar novedades"
        ),
        Entry(key: "What's New in {0}", french: "Nouveautés de {0}", spanish: "Novedades de {0}"),
        Entry(
            key: "Theme updates, your way.",
            french: "Mettez les thèmes à jour à votre façon.",
            spanish: "Actualiza los temas a tu manera."
        ),
        Entry(
            key: "Follow your Mac automatically or choose from seven interface languages.",
            french: "Suivez automatiquement la langue de votre Mac ou choisissez parmi sept langues d’interface.",
            spanish: "Sigue automáticamente el idioma de tu Mac o elige entre siete idiomas de interfaz."
        ),
        Entry(
            key: "Choose Stable or Beta updates from Settings.",
            french: "Choisissez les mises à jour stables ou bêta dans Réglages.",
            spanish: "Elige actualizaciones estables o beta en Ajustes."
        ),
        Entry(
            key: "Sparkle verifies and installs signed app updates.",
            french: "Sparkle vérifie et installe les mises à jour signées de l’app.",
            spanish: "Sparkle verifica e instala actualizaciones firmadas de la app."
        ),
        Entry(key: "Done", french: "Terminé", spanish: "Listo"),
        Entry(key: "Open Releases", french: "Ouvrir les versions", spanish: "Abrir versiones"),
        Entry(
            key: "Invalid update response.",
            french: "Réponse de mise à jour non valide.",
            spanish: "Respuesta de actualización no válida."
        ),
        Entry(
            key: "Failed to decode update metadata.",
            french: "Échec du décodage des métadonnées de mise à jour.",
            spanish: "No se pudieron decodificar los metadatos de actualización."
        ),
        Entry(
            key: "No update is available on this channel.",
            french: "Aucune mise à jour n’est disponible sur ce canal.",
            spanish: "No hay actualizaciones disponibles en este canal."
        ),
        Entry(
            key: "Unable to start Sparkle. Open the download page instead.",
            french: "Impossible de démarrer Sparkle. Ouvrez plutôt la page de téléchargement.",
            spanish: "No se pudo iniciar Sparkle. Abre la página de descarga."
        ),
        Entry(
            key: "Sparkle is available in the packaged app.",
            french: "Sparkle est disponible dans la version distribuée de l’app.",
            spanish: "Sparkle está disponible en la versión empaquetada de la app."
        ),
        Entry(
            key: "Sparkle is unavailable when running from SwiftPM.",
            french: "Sparkle n’est pas disponible lors de l’exécution depuis SwiftPM.",
            spanish: "Sparkle no está disponible al ejecutar desde SwiftPM."
        ),
        Entry(
            key: "Automatic checks are off.",
            french: "Les recherches automatiques sont désactivées.",
            spanish: "Las comprobaciones automáticas están desactivadas."
        ),
        Entry(
            key: "Choose Codex application",
            french: "Choisir l’application Codex",
            spanish: "Elegir la aplicación Codex"
        ),
        Entry(
            key: "Choose",
            french: "Choisir",
            spanish: "Elegir"
        ),
        Entry(
            key: "Codex application",
            french: "Application Codex",
            spanish: "Aplicación Codex"
        ),
        Entry(
            key: "Automatically finds a running or installed Codex, or lets you choose another location.",
            french: "Détecte automatiquement Codex en cours d’exécution ou installé, avec la possibilité de choisir un autre emplacement.",
            spanish: "Encuentra automáticamente Codex en ejecución o instalado, o permite elegir otra ubicación."
        ),
        Entry(
            key: "Using a custom location",
            french: "Emplacement personnalisé utilisé",
            spanish: "Usando una ubicación personalizada"
        ),
        Entry(
            key: "Codex detected automatically",
            french: "Codex détecté automatiquement",
            spanish: "Codex detectado automáticamente"
        ),
        Entry(
            key: "Codex application not found",
            french: "Application Codex introuvable",
            spanish: "No se encontró la aplicación Codex"
        ),
        Entry(
            key: "Choose…",
            french: "Choisir…",
            spanish: "Elegir…"
        ),
        Entry(
            key: "Use Automatic",
            french: "Utiliser la détection automatique",
            spanish: "Usar detección automática"
        ),
        Entry(
            key: "Codex application location saved",
            french: "Emplacement de l’application Codex enregistré",
            spanish: "Ubicación de la aplicación Codex guardada"
        ),
        Entry(
            key: "Automatic Codex discovery enabled",
            french: "Détection automatique de Codex activée",
            spanish: "Detección automática de Codex activada"
        ),
        Entry(
            key: "Interface language",
            french: "Langue de l’interface",
            spanish: "Idioma de la interfaz"
        ),
        Entry(
            key: "Follow your Mac automatically or choose a language for this app.",
            french: "Suivez automatiquement la langue de votre Mac ou choisissez une langue pour cette app.",
            spanish: "Sigue automáticamente el idioma de tu Mac o elige un idioma para esta app."
        ),
        Entry(
            key: "Automatic (System)",
            french: "Automatique (système)",
            spanish: "Automático (sistema)"
        ),
        Entry(
            key: "Language changes take effect immediately.",
            french: "Les changements de langue prennent effet immédiatement.",
            spanish: "Los cambios de idioma se aplican inmediatamente."
        ),
        Entry(
            key: "“{0}” is not a valid Codex application.",
            french: "« {0} » n’est pas une application Codex valide.",
            spanish: "«{0}» no es una aplicación Codex válida."
        ),
        Entry(key: "Voice", french: "Voice", spanish: "Voice"),
        Entry(
            key: "Customize the ChatGPT Voice orb and surrounding effects. The custom orb appears both in the main window and the isolated Voice overlay; full-page backgrounds remain isolated.",
            french: "Personnalisez l’orbe ChatGPT Voice et ses effets. L’orbe personnalisé apparaît dans la fenêtre principale et dans la superposition Voice isolée ; les arrière-plans pleine page restent limités à la superposition.",
            spanish: "Personaliza la esfera de ChatGPT Voice y sus efectos. La esfera personalizada aparece tanto en la ventana principal como en la superposición aislada de Voice; los fondos de página completa permanecen aislados."
        ),
        Entry(
            key: "Enable Voice styling",
            french: "Activer le style Voice",
            spanish: "Activar estilo de Voice"
        ),
        Entry(
            key: "Disable Voice styling",
            french: "Désactiver le style Voice",
            spanish: "Desactivar estilo de Voice"
        ),
        Entry(
            key: "Experimental",
            french: "Expérimental",
            spanish: "Experimental"
        ),
        Entry(
            key: "Codex versions may use DOM, Canvas, WebGL, or native layers. The embedded image works on the current DOM orb, while native or Canvas orbs may not expose their inside to CSS.",
            french: "Selon la version de Codex, l’orbe peut utiliser le DOM, Canvas, WebGL ou des calques natifs. L’image intégrée fonctionne avec l’orbe DOM actuel, mais l’intérieur des orbes natifs ou Canvas peut ne pas être accessible en CSS.",
            spanish: "Según la versión de Codex, la esfera puede usar DOM, Canvas, WebGL o capas nativas. La imagen integrada funciona con la esfera DOM actual, pero el interior de las esferas nativas o Canvas puede no estar disponible para CSS."
        ),
        Entry(
            key: "Reset current appearance",
            french: "Réinitialiser l’apparence actuelle",
            spanish: "Restablecer apariencia actual"
        ),
        Entry(
            key: "Remove Voice style",
            french: "Supprimer le style Voice",
            spanish: "Eliminar estilo de Voice"
        ),
        Entry(
            key: "Effect preview",
            french: "Aperçu des effets",
            spanish: "Vista previa de efectos"
        ),
        Entry(
            key: "The preview uses the measured Voice overlay ratio and initial orb position. Its runtime position can differ after you drag the orb.",
            french: "L’aperçu utilise le rapport mesuré de la superposition Voice et la position initiale de l’orbe. Sa position réelle peut différer après un déplacement.",
            spanish: "La vista previa usa la proporción medida de la superposición Voice y la posición inicial de la esfera. Su posición real puede variar después de arrastrarla."
        ),
        Entry(
            key: "Orb surface",
            french: "Surface de l’orbe",
            spanish: "Superficie de la esfera"
        ),
        Entry(
            key: "Native orb opacity",
            french: "Opacité de l’orbe natif",
            spanish: "Opacidad de la esfera nativa"
        ),
        Entry(
            key: "Applied to Canvas and recognizable orb containers inside the Voice overlay.",
            french: "Appliqué aux Canvas et aux conteneurs d’orbe reconnaissables dans la superposition Voice.",
            spanish: "Se aplica a Canvas y contenedores de esfera reconocibles dentro de la superposición de Voice."
        ),
        Entry(key: "Scale", french: "Échelle", spanish: "Escala"),
        Entry(
            key: "Hue rotation",
            french: "Rotation de teinte",
            spanish: "Rotación de tono"
        ),
        Entry(key: "Blur", french: "Flou", spanish: "Desenfoque"),
        Entry(
            key: "Outer glow",
            french: "Halo extérieur",
            spanish: "Resplandor exterior"
        ),
        Entry(
            key: "Glow color",
            french: "Couleur du halo",
            spanish: "Color del resplandor"
        ),
        Entry(
            key: "Glow opacity",
            french: "Opacité du halo",
            spanish: "Opacidad del resplandor"
        ),
        Entry(
            key: "Glow spread",
            french: "Étendue du halo",
            spanish: "Extensión del resplandor"
        ),
        Entry(
            key: "Voice backdrop",
            french: "Arrière-plan Voice",
            spanish: "Fondo de Voice"
        ),
        Entry(
            key: "Transparent by default. Raising opacity adds a tint behind the Voice overlay.",
            french: "Transparent par défaut. Augmenter l’opacité ajoute une teinte derrière la superposition Voice.",
            spanish: "Transparente de forma predeterminada. Aumentar la opacidad añade un color detrás de la superposición de Voice."
        ),
        Entry(
            key: "Backdrop color",
            french: "Couleur d’arrière-plan",
            spanish: "Color de fondo"
        ),
        Entry(
            key: "Backdrop opacity",
            french: "Opacité de l’arrière-plan",
            spanish: "Opacidad del fondo"
        ),
        Entry(
            key: "Voice Advanced CSS",
            french: "CSS avancé Voice",
            spanish: "CSS avanzado de Voice"
        ),
        Entry(
            key: "Delivered only to avatar-overlay, never the main Codex window. theme-asset(\"UUID\") is supported; imports, external URLs, and file URLs remain blocked.",
            french: "Envoyé uniquement à avatar-overlay, jamais à la fenêtre principale de Codex. theme-asset(\"UUID\") est pris en charge ; les imports, URL externes et URL file restent bloqués.",
            spanish: "Se envía solo a avatar-overlay, nunca a la ventana principal de Codex. Se admite theme-asset(\"UUID\"); las importaciones, URL externas y URL file siguen bloqueadas."
        ),
        Entry(
            key: "Copy Voice appearance",
            french: "Copier l’apparence Voice",
            spanish: "Copiar apariencia de Voice"
        ),
        Entry(
            key: "Reset Voice appearance",
            french: "Réinitialiser l’apparence Voice",
            spanish: "Restablecer apariencia de Voice"
        ),
        Entry(
            key: "Voice renderer connected",
            french: "Renderer Voice connecté",
            spanish: "Renderer de Voice conectado"
        ),
        Entry(
            key: "Waiting for a Voice conversation",
            french: "En attente d’une conversation Voice",
            spanish: "Esperando una conversación de Voice"
        ),
        Entry(
            key: "Voice background image",
            french: "Image d’arrière-plan Voice",
            spanish: "Imagen de fondo de Voice"
        ),
        Entry(
            key: "Keep orb centered in Voice overlay",
            french: "Garder l’orbe centré dans la fenêtre Voice",
            spanish: "Mantener la esfera centrada en Voice"
        ),
        Entry(
            key: "Turn this off to use ChatGPT's native dragging and move the orb to screen edges.",
            french: "Désactivez cette option pour utiliser le déplacement natif de ChatGPT et placer l’orbe au bord de l’écran.",
            spanish: "Desactiva esta opción para usar el arrastre nativo de ChatGPT y mover la esfera hasta los bordes de la pantalla."
        ),
        Entry(
            key: "Light and Dark can use different images. The image is embedded in the .codextheme and sent only to the Voice overlay.",
            french: "Light et Dark peuvent utiliser des images différentes. L’image est intégrée au fichier .codextheme et envoyée uniquement à la superposition Voice.",
            spanish: "Light y Dark pueden usar imágenes distintas. La imagen se integra en el archivo .codextheme y se envía únicamente a la superposición de Voice."
        ),
        Entry(
            key: "Choose light Voice background",
            french: "Choisir l’arrière-plan Voice clair",
            spanish: "Elegir fondo claro de Voice"
        ),
        Entry(
            key: "Choose dark Voice background",
            french: "Choisir l’arrière-plan Voice sombre",
            spanish: "Elegir fondo oscuro de Voice"
        ),
        Entry(
            key: "{0} Voice background set",
            french: "Arrière-plan Voice {0} défini",
            spanish: "Fondo {0} de Voice configurado"
        ),
        Entry(
            key: "Adjust Voice background focal point",
            french: "Ajuster le point focal de l’arrière-plan Voice",
            spanish: "Ajustar el punto focal del fondo de Voice"
        ),
        Entry(
            key: "Image inside orb",
            french: "Image dans l’orbe",
            spanish: "Imagen dentro de la esfera"
        ),
        Entry(
            key: "Places a separate image inside the current DOM orb. Lower the image opacity to let the original animated orb show through.",
            french: "Place une image distincte dans l’orbe DOM actuel. Réduisez l’opacité de l’image pour laisser transparaître l’orbe animé d’origine.",
            spanish: "Coloca una imagen independiente dentro de la esfera DOM actual. Reduce la opacidad de la imagen para que se vea la esfera animada original."
        ),
        Entry(
            key: "Follow Voice pulse",
            french: "Suivre la pulsation de Voice",
            spanish: "Seguir el pulso de Voice"
        ),
        Entry(
            key: "Synchronizes the orb image scale with the native Voice animation.",
            french: "Synchronise l’échelle de l’image de l’orbe avec l’animation Voice native.",
            spanish: "Sincroniza la escala de la imagen de la esfera con la animación nativa de Voice."
        ),
        Entry(
            key: "Pulse strength",
            french: "Intensité de la pulsation",
            spanish: "Intensidad del pulso"
        ),
        Entry(
            key: "Choose light orb image",
            french: "Choisir l’image de l’orbe clair",
            spanish: "Elegir imagen de la esfera clara"
        ),
        Entry(
            key: "Choose dark orb image",
            french: "Choisir l’image de l’orbe sombre",
            spanish: "Elegir imagen de la esfera oscura"
        ),
        Entry(
            key: "{0} orb image set",
            french: "Image de l’orbe {0} définie",
            spanish: "Imagen {0} de la esfera configurada"
        ),
        Entry(
            key: "Adjust orb image focal point",
            french: "Ajuster le point focal de l’image de l’orbe",
            spanish: "Ajustar el punto focal de la imagen de la esfera"
        ),
        Entry(
            key: "Orb image opacity",
            french: "Opacité de l’image de l’orbe",
            spanish: "Opacidad de la imagen de la esfera"
        ),
        Entry(
            key: "Orb image blur",
            french: "Flou de l’image de l’orbe",
            spanish: "Desenfoque de la imagen de la esfera"
        ),
        Entry(
            key: "Orb image inset",
            french: "Marge intérieure de l’image de l’orbe",
            spanish: "Margen interior de la imagen de la esfera"
        ),
        Entry(
            key: "Test speech intensity",
            french: "Tester l’intensité de la parole",
            spanish: "Probar intensidad del habla"
        ),
        Entry(
            key: "Talking mouth frames",
            french: "Images de bouche parlante",
            spanish: "Fotogramas de boca al hablar"
        ),
        Entry(
            key: "Add images",
            french: "Ajouter des images",
            spanish: "Añadir imágenes"
        ),
        Entry(
            key: "1 · Closed",
            french: "1 · Fermée",
            spanish: "1 · Cerrada"
        ),
        Entry(
            key: "Mouth sensitivity",
            french: "Sensibilité de la bouche",
            spanish: "Sensibilidad de la boca"
        ),
        Entry(
            key: "Choose mouth images (least to most open)",
            french: "Choisir les images de bouche (de la moins à la plus ouverte)",
            spanish: "Elegir imágenes de boca (de menos a más abierta)"
        ),
        Entry(
            key: "Add mouth images",
            french: "Ajouter des images de bouche",
            spanish: "Añadir imágenes de boca"
        ),
        Entry(
            key: "Add mouth image",
            french: "Ajouter une image de bouche",
            spanish: "Añadir imagen de boca"
        ),
        Entry(
            key: "Remove mouth image",
            french: "Supprimer l’image de bouche",
            spanish: "Eliminar imagen de boca"
        ),
        Entry(
            key: "Reorder mouth images",
            french: "Réorganiser les images de bouche",
            spanish: "Reordenar imágenes de boca"
        ),
        Entry(
            key: "Import 2×2 sheet",
            french: "Importer une planche 2×2",
            spanish: "Importar hoja 2×2"
        ),
        Entry(key: "closed", french: "fermée", spanish: "cerrada"),
        Entry(
            key: "Frame 1 is closed. Order the rest from least to most open; Voice opens quickly, closes smoothly, and directly selects the nearest pose.",
            french: "L’image 1 montre la bouche fermée. Classez les autres de la moins à la plus ouverte ; Voice ouvre rapidement, referme en douceur et sélectionne directement la pose la plus proche.",
            spanish: "La imagen 1 es la boca cerrada. Ordena las demás de menos a más abierta; Voice abre rápido, cierra suavemente y selecciona directamente la pose más cercana."
        ),
        Entry(
            key: "Set speech intensity to 0 to preview idle sway and blinking.",
            french: "Réglez l’intensité de parole sur 0 pour prévisualiser le balancement au repos et les clignements.",
            spanish: "Ajusta la intensidad de voz a 0 para previsualizar el balanceo en reposo y los parpadeos."
        ),
        Entry(
            key: "Idle animation",
            french: "Animation au repos",
            spanish: "Animación en reposo"
        ),
        Entry(
            key: "Gently sways the portrait during silence and smoothly stops when speech begins.",
            french: "Balance légèrement le portrait pendant le silence et s’arrête en douceur quand la parole commence.",
            spanish: "Balancea suavemente el retrato durante el silencio y se detiene gradualmente al comenzar a hablar."
        ),
        Entry(
            key: "Enable idle sway",
            french: "Activer le balancement au repos",
            spanish: "Activar balanceo en reposo"
        ),
        Entry(
            key: "Sway strength",
            french: "Intensité du balancement",
            spanish: "Intensidad del balanceo"
        ),
        Entry(
            key: "Sway period",
            french: "Période du balancement",
            spanish: "Periodo del balanceo"
        ),
        Entry(
            key: "Closed-eye image",
            french: "Image avec les yeux fermés",
            spanish: "Imagen con ojos cerrados"
        ),
        Entry(
            key: "Choose a matching closed-eye portrait with the same framing as the closed-mouth image.",
            french: "Choisissez un portrait aux yeux fermés avec le même cadrage que l’image bouche fermée.",
            spanish: "Elige un retrato con los ojos cerrados y el mismo encuadre que la imagen con la boca cerrada."
        ),
        Entry(
            key: "Average blink interval",
            french: "Intervalle moyen des clignements",
            spanish: "Intervalo medio de parpadeo"
        ),
        Entry(
            key: "Blink duration",
            french: "Durée du clignement",
            spanish: "Duración del parpadeo"
        ),
        Entry(
            key: "Choose closed-eye image",
            french: "Choisir l’image aux yeux fermés",
            spanish: "Elegir imagen con ojos cerrados"
        ),
        Entry(
            key: "Set closed-eye image",
            french: "Définir l’image aux yeux fermés",
            spanish: "Definir imagen con ojos cerrados"
        ),
        Entry(
            key: "Clear closed-eye image",
            french: "Effacer l’image aux yeux fermés",
            spanish: "Quitar imagen con ojos cerrados"
        ),
        Entry(
            key: "Import 3×3 sheet",
            french: "Importer une planche 3×3",
            spanish: "Importar hoja 3×3"
        ),
        Entry(
            key: "Choose a {0} mouth sprite sheet",
            french: "Choisir une planche {0} de bouches",
            spanish: "Elegir una hoja {0} de bocas"
        ),
        Entry(
            key: "Import {0} mouth sprite sheet",
            french: "Importer une planche {0} de bouches",
            spanish: "Importar hoja {0} de bocas"
        ),
        Entry(
            key: "Imported {0} mouth frames from left to right, top to bottom.",
            french: "{0} images de bouche ont été importées de gauche à droite et de haut en bas.",
            spanish: "Se importaron {0} bocas de izquierda a derecha y de arriba abajo."
        ),
        Entry(
            key: "You can use up to nine mouth images, including the closed-mouth base image.",
            french: "Vous pouvez utiliser jusqu’à neuf images de bouche, y compris l’image de base avec la bouche fermée.",
            spanish: "Puedes usar hasta nueve imágenes de boca, incluida la imagen base con la boca cerrada."
        ),
        Entry(
            key: "“{0}” could not be decoded or split into a 2×2 or 3×3 mouth sprite sheet.",
            french: "Impossible de décoder « {0} » ou de le diviser en une planche 2×2 ou 3×3 de bouches.",
            spanish: "No se pudo decodificar «{0}» ni dividirla en una hoja 2×2 o 3×3 de bocas."
        ),
        Entry(
            key: "Mouth attack",
            french: "Vitesse d’ouverture",
            spanish: "Velocidad de apertura"
        ),
        Entry(
            key: "Mouth release",
            french: "Vitesse de fermeture",
            spanish: "Velocidad de cierre"
        ),
        Entry(
            key: "Noise gate",
            french: "Seuil de silence",
            spanish: "Umbral de silencio"
        ),
        Entry(
            key: "Mouth response curve",
            french: "Courbe de réponse de la bouche",
            spanish: "Curva de respuesta de la boca"
        ),
        Entry(
            key: "Midnight",
            french: "Minuit",
            spanish: "Medianoche"
        ),
        Entry(
            key: "Paper",
            french: "Papier",
            spanish: "Papel"
        ),
        Entry(
            key: "High Contrast",
            french: "Contraste élevé",
            spanish: "Alto contraste"
        ),
        Entry(
            key: "A deep blue-black theme with a cool cyan accent.",
            french: "Un thème bleu-noir profond rehaussé d’un accent cyan froid.",
            spanish: "Un tema azul oscuro casi negro con un acento cian frío."
        ),
        Entry(
            key: "A warm, low-glare light theme inspired by natural paper.",
            french: "Un thème clair, chaleureux et peu éblouissant, inspiré du papier naturel.",
            spanish: "Un tema claro, cálido y de bajo deslumbramiento inspirado en el papel natural."
        ),
        Entry(
            key: "Maximum contrast with strong focus and selection indicators.",
            french: "Un contraste maximal avec des indicateurs de focus et de sélection bien visibles.",
            spanish: "Contraste máximo con indicadores claros de enfoque y selección."
        ),
        Entry(key: "open", french: "ouverte", spanish: "abierta"),
    ]

    static let french: [String: String] = Dictionary(
        uniqueKeysWithValues: entries.map { ($0.key, $0.french) }
    )

    static let spanish: [String: String] = Dictionary(
        uniqueKeysWithValues: entries.map { ($0.key, $0.spanish) }
    )
}
