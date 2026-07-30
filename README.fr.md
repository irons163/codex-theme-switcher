# Codex Theme Switcher

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | **Français** | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

![Codex avec un arrière-plan illustré, des effets de verre et des composants personnalisés par Codex Theme Switcher](docs/images/codex-theme-showcase.jpg)

Un studio de thèmes natif pour la barre des menus de macOS. Il ne crée pas de fenêtre principale
classique, n’apparaît pas dans le Dock et ne modifie, ne signe à nouveau ni n’écrase
`Codex.app` / `ChatGPT.app`.

Theme Switcher se connecte au moteur de rendu de Codex via le Chromium DevTools Protocol (CDP) et
écrit le CSS compilé dans un élément `<style>` placé dans un espace de noms. Les changements de
thème sont synchronisés en temps réel dans toutes les fenêtres Codex ; le runtime restaure aussi
automatiquement le thème après un rechargement de Codex ou l’ouverture d’une nouvelle fenêtre.

## Télécharger

**Version stable actuelle : 0.3.0**

[DMG Apple Silicon](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-apple-silicon.dmg)
·
[DMG Intel](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-intel.dmg)
·
[Notes de version, sommes de contrôle et tous les fichiers](https://github.com/irons163/codex-theme-switcher/releases/tag/v0.3.0)

Nécessite macOS 13 ou une version ultérieure. Les deux installateurs sont signés, certifiés par
Apple et intègrent Sparkle pour recevoir les prochaines mises à jour Stable ou Beta.

## Captures d’écran

### Studio de thèmes de la barre des menus

![Studio de thèmes Codex Theme Switcher affichant la bibliothèque, l’aperçu en direct et tous les onglets d’édition](docs/images/theme-studio.png)

### Aperçu du moteur de rendu pour agents

| Paper · Clair / Accueil | Midnight · Sombre / Discussion |
| --- | --- |
| ![Aperçu Paper clair de l’accueil](docs/images/paper-light-home.png) | ![Aperçu Midnight sombre d’une discussion](docs/images/midnight-dark-chat.png) |

L’Agent CLI peut générer des PNG Light/Dark × Home/Chat dans un environnement sans fenêtre afin
que les agents IA puissent les examiner de manière itérative. Il s’agit d’approximations
structurées ; le résultat final des selector rules, du raw CSS et du véritable moteur de rendu
Codex doit encore être vérifié après application du thème.

## Fonctionnalités

- Application exclusivement dans la barre des menus ; toute la bibliothèque de thèmes, l’édition,
  l’aperçu et l’état du runtime se trouvent dans le panneau de la barre des menus.
- Trois modèles intégrés : Midnight, Paper et High Contrast.
- Application en un clic, restauration du style d’origine de Codex et reconnexion du moteur de rendu.
- Détecte Codex via un emplacement enregistré, l’app en cours d’exécution, Launch Services et les
  dossiers courants ; les réglages permettent aussi de choisir Codex sur un disque externe ou dans
  tout autre dossier.
- Système visuel de couleurs :
  - Couleurs sémantiques de base.
  - Tokens d’interface, d’interaction, de diff et de terminal Codex `--color-token-*`.
- Réglages de police, taille de texte, hauteur de ligne, largeur du contenu, espacement, rayon des
  angles, ombre, flou, mise à l’échelle et animations.
- Arrière-plan et verre (Image Skin) : arrière-plans clair/sombre distincts, sept modes de
  dimensionnement dont Fit / Fill, recadrage par point focal, toile de fond d’écran couvrant toute
  la fenêtre ou évitant la barre latérale, filtres, overlay, glass par section et panneau de
  contenu central.
- Style expérimental de ChatGPT Voice : images Light/Dark distinctes avec Fit / Fill, point focal,
  zoom, opacité et flou, ainsi que réglages de l’orbe, filtres, lueur, arrière-plan et CSS avancé
  propre à Voice, envoyés uniquement au renderer `avatar-overlay`.
- Portraits Voice animés : une image de base bouche fermée et jusqu’à huit poses ordonnées,
  import direct de planches 2×2 / 3×3, clignements aléatoires, mouvement de repos, synchronisation
  avec la pulsation native et opacités indépendantes du portrait et de l’orbe natif.
- Les nouveaux thèmes contiennent un préréglage d’avatar Voice animé prêt à l’emploi. Ses images
  sont intégrées au thème : l’exportation et l’importation conservent toute l’animation sans
  dépendre des chemins locaux d’origine.
- Déclarations de composants arbitraires.
- CSS selector rules arbitraires.
- Escape hatch complet pour le raw CSS.
- Plusieurs layers avec light / dark / custom media query.
- Les ressources PNG, JPEG, WebP, GIF, les polices et d’autres fichiers peuvent être intégrés aux
  modèles ; le runtime les transfère par fragments et crée des Blob URL propres au moteur de rendu,
  afin que les grandes images 4K ne dépassent pas la limite de longueur des déclarations CSS.
- Importation et exportation dans un fichier `.codextheme` unique pour faciliter le partage.
- Suit par défaut la langue préférée de macOS, avec sélection manuelle dans Réglages parmi
  l’anglais, le chinois traditionnel, le chinois simplifié, le français, l’espagnol, le japonais
  et le coréen ; en mode automatique, les autres langues utilisent l’anglais.
- Mises à jour automatiques Sparkle 2 : choix du canal Stable ou Beta, téléchargement de
  l’installateur adapté à Apple Silicon ou Intel et notes de version dans les mêmes sept langues.
- Recherche de mises à jour au lancement puis toutes les 30 minutes ; il est aussi possible de la
  lancer manuellement depuis les réglages ou le menu en haut à droite, d’ignorer une version
  précise ou de choisir un téléchargement manuel.
- Agent CLI `codex-theme` JSON-first inclus : les agents IA peuvent obtenir le schéma et les
  exemples, valider, normaliser, compiler, installer, exporter et générer des aperçus PNG
  Light/Dark × Home/Chat ; Codex n’est modifié que par un appel explicite à `attach`, `apply` ou
  `clear`.

## Arrière-plan et verre / Image Skin

Image Skin permet de transformer Codex en un thème graphique complet plutôt que de simplement
remplacer une palette de couleurs :

- Light et Dark peuvent utiliser chacun une image d’arrière-plan distincte, ou partager la même
  image avec des effets différents.
- Les arrière-plans prennent en charge Fit (afficher l’image entière), Fill (remplir en recadrant
  proportionnellement), Stretch, Fit Width, Fit Height, Original et Tile ; chaque mode peut être
  combiné avec un point focal ou une origine, un zoom, une opacité, ainsi que des filtres de
  luminosité, contraste, saturation et flou.
- « Le fond d’écran évite la barre latérale » réorganise ensemble l’image, Fit / Fill, le point
  focal, l’overlay, le scrim et la vignette dans la zone de contenu principale ; la barre latérale
  conserve sa propre couleur d’arrière-plan et son glass. Quand sa largeur change ou qu’elle est
  repliée, la limite du fond d’écran suit automatiquement le layout Codex réel.
- L’Overlay peut utiliser un scrim de couleur unie, un dégradé linéaire ou une vignette pour que la
  barre latérale, les titres et la zone de saisie restent lisibles sur les images complexes.
- Sidebar, main content, composer, card, menu, popover et code block peuvent chacun être configurés
  séparément avec leur propre glass fill, opacité, backdrop blur, bordure, rayon des angles et
  ombre ; modifier l’opacité d’un panneau n’atténue pas le texte.
- Le « panneau de contenu central » enveloppe séparément le Home Hero ou l’historique de
  conversations dans Chat, sans inclure les Cards de suggestion ni le Composer. Sa couleur de fond,
  sa bordure, la couleur de son ombre et son opacité peuvent être définies séparément pour Light et
  Dark ; les réglages de matériau comprennent blur, saturation, largeur de bordure, rayon des
  angles, décalage/étalement de l’ombre, largeur maximale et marges internes
  horizontales/verticales.
- L’aperçu peut basculer entre Light / Dark et Home / Chat, ce qui permet de vérifier simultanément
  le recadrage de l’arrière-plan, le contraste du texte et les surfaces des composants.
- Les arrière-plans utilisés par Image Skin sont intégrés au fichier `.codextheme` ; les thèmes
  exportés ne dépendent donc pas des chemins des fichiers d’origine et peuvent être importés
  directement par leurs destinataires.

Les contrôles visuels génèrent des theme variables et des component overrides portables. Lorsqu’il
faut des selectors plus précis, plusieurs dégradés, des blend modes ou des animations, Raw CSS
peut toujours tout remplacer à la fin ; Raw CSS conserve le plus haut degré de liberté dans la
theme cascade.

Les champs d’image Image Skin n’acceptent que des raster assets (PNG, JPEG, WebP, GIF, AVIF), avec
une limite de 16 MB par asset. La limite cumulée de toutes les ressources est de 32 MB et un fichier
`.codextheme` unique est limité à 48 MB. Les polices peuvent toujours être intégrées grâce aux
fonctions avancées de ressources, mais ne peuvent pas servir d’arrière-plan Image Skin.

## Style de ChatGPT Voice

L’onglet Voice utilise une feuille de style indépendante pour les surfaces de ChatGPT Voice
accessibles en CSS. Le fond d’écran et les règles de composants de la fenêtre principale ne sont
jamais envoyés à `avatar-overlay`. Si Voice n’est pas activé, Theme Switcher ne s’y connecte pas ;
le désactiver efface la feuille de style et ferme la session.

Les images sont intégrées au fichier `.codextheme` et prennent en charge les sept modes de taille
d’Image Skin. Une image distincte peut aussi être découpée dans l’orbe DOM, avec ses propres mode de
taille, point focal, opacité, flou et marge intérieure. Cette image peut suivre la pulsation du
sprite Voice natif, avec une intensité réglable de 0 à 2×. Les autres contrôles de l’orbe restent
indépendants. Un portrait parlant peut contenir jusqu’à neuf images de bouche ordonnées. Le runtime
utilise l’intensité de sortie Voice avec sensibilité, seuil de silence, courbe de réponse, ouverture
rapide et fermeture douce, puis sélectionne directement la pose de bouche la plus proche. Il s’agit
d’une animation par amplitude, pas d’une synchronisation phonétique. Une planche
2×2 ou 3×3 peut être importée et découpée de gauche à droite, puis de haut en bas. Voir
les exemples de portrait animé
[2×2](Examples/voice-mouth-sprites/anime-girl-mouth-2x2.png) et
[3×3](Examples/voice-mouth-sprites/anime-girl-mouth-3x3.png).
Pendant le silence, un mode de repos facultatif balance légèrement le portrait et s’arrête en
douceur quand la parole commence. Un portrait correspondant avec les yeux fermés peut être intégré
pour des clignements aléatoires, avec intervalle moyen et durée réglables. Les deux effets se mettent
en pause pendant que Voice parle.
Avant le démarrage de l’animation audio, le runtime charge et décode toutes les images de bouche et
de clignement tout en maintenant l’image bouche fermée. L’animation ne commence que lorsque
l’ensemble est prêt ; si une image ne peut pas être décodée, le portrait bouche fermée reste affiché
au lieu d’une image vide, ancienne ou clignotante pendant la première seconde de parole.
Le renderer WebGL
actuel et l’ancienne implémentation `.codex-avatar-root` sont pris en charge ; un futur orbe
uniquement natif pourrait ne pas être contrôlable. L’aperçu suit
la géométrie observée `408:400`, mais un orbe déplacé peut occuper une autre position à l’exécution.

## Flux de travail

1. Ouvrez l’app et accédez au studio de thèmes depuis l’icône de palette dans la barre des menus
   de macOS.
2. Cliquez sur « Lancer et connecter Codex » ; la première connexion peut relancer Codex.
   La première connexion n’applique pas automatiquement le modèle présélectionné. Les reconnexions
   suivantes restaurent le dernier snapshot appliqué avec succès et enregistré par le runtime, à
   l’exclusion des changements enregistrés uniquement par la suite ou encore présents dans un
   brouillon.
3. Appliquez directement un modèle intégré ou commencez par « Créer une copie modifiable » ; vous
   pouvez aussi créer un thème vide depuis le coin inférieur gauche.
4. Modifiez les onglets Arrière-plan et verre, Voice, Couleurs, Typographie et disposition, Composants,
   Règles, CSS avancé, Ressources et Informations. Un point orange indique que le thème contient
   encore des modifications non enregistrées ; le brouillon reste intact si vous passez à un autre
   thème avant de revenir.
5. Enregistrez, puis appliquez. Pour partager le thème, cliquez sur Exporter afin d’obtenir un
   fichier `.codextheme` unique contenant toutes les ressources intégrées. Les destinataires
   peuvent l’importer depuis le même emplacement.
6. L’onglet Réglages permet d’activer ou de désactiver les mises à jour automatiques, de choisir
   Stable/Beta, de rechercher une nouvelle version et de réafficher les « Nouveautés » de la
   version actuelle.

## Modèle de sécurité

- Ne modifie pas `app.asar`, afin de préserver la signature, la notarisation et l’intégrité ASAR
  de l’app OpenAI.
- Le bridge Theme Switcher écoute uniquement sur `127.0.0.1` et utilise un bearer token privé de
  256 bits.
- `.codextheme` n’autorise pas JavaScript.
- L’importation et la compilation refusent `@import`, les URL `http:`, `https:`, protocol-relative
  et `file:`.
- Les ressources sont intégrées au modèle ; l’importation n’extrait pas de ZIP, ce qui élimine les
  risques de path traversal / zip-slip.
- Les arrière-plans Image Skin n’acceptent que des images matricielles ; le format, les données
  base64 et la limite de taille de 16 MB de chaque asset intégré sont vérifiés à l’importation.
- Le Runtime et les identifiants de style utilisent tous deux l’espace de noms
  `codex-theme-switcher` et n’effacent pas les autres outils d’injection.
- La barre des menus propose toujours « Restaurer le style de Codex », ce qui permet de récupérer
  l’interface même si un CSS personnalisé l’endommage.
- L’Agent CLI interdit explicitement d’exécuter `attach`, `apply` ou `clear` avec un `--root`
  différent de celui par défaut ; une racine personnalisée sert uniquement à isoler le dépôt et le
  travail hors ligne et ne constitue pas un environnement isolé pour le véritable runtime Codex.
- Le point de terminaison de débogage CDP de Chromium est lui aussi explicitement lié à
  `127.0.0.1`, mais CDP ne fournit pas d’authentification par bearer token ; d’autres processus
  locaux sur le même Mac peuvent donc encore s’y connecter. Si vous n’utilisez plus les fonctions
  de thème, quittez Codex et rouvrez-le normalement afin qu’il ne conserve plus les arguments de
  débogage distant.

## Compilation

Prérequis :

- macOS 13+
- Swift 6 toolchain
- Codex desktop app (l’app unifiée actuelle peut aussi se trouver dans
  `/Applications/ChatGPT.app`)
- Node.js 22+ ; le programme utilise d’abord
  `Contents/Resources/cua_node/bin/node` inclus dans l’app Codex, puis recherche Node dans
  PATH / Homebrew

```sh
swift build
swift test
npm test
npm run check
swift run CodexThemeSwitcher
swift run codex-theme capabilities
```

Créer une `.app` de barre des menus pouvant être ouverte d’un double-clic :

```sh
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

Le fichier `Info.plist` généré contient `LSUIElement=true` ; l’app n’apparaît donc ni dans le Dock
ni dans le sélecteur d’apps habituel. L’Agent CLI est empaqueté dans
`CodexThemeSwitcher.app/Contents/Helpers/codex-theme`, tandis que le JSON Schema se trouve dans
`Contents/Resources/Schemas/`. Le protocole complet et des exemples sont disponibles dans
[`docs/AGENT_API.md`](docs/AGENT_API.md). Si aucune identité de signature n’est fournie, le script
utilise une signature ad hoc ; pour une distribution en production, définissez :

```sh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
SPARKLE_PUBLIC_ED_KEY="<base64 Ed25519 public key>" \
  scripts/package-app.sh
```

Un paquet de production doit fournir la clé publique Sparkle EdDSA. Le script l’écrit dans
`SUPublicEDKey` et refuse tout réglage `SUAllowsInsecureUpdates`. Seuls les paquets de développement
locaux signés ad hoc bénéficient d’une dérogation limitée à l’environnement local pour les mises à
jour non sécurisées ; ils ne doivent pas être utilisés pour les versions de production.

## Mises à jour et publication de l’app

- Flux Stable :
  `appcast-arm64.xml`, `appcast-x86_64.xml`
- Flux Beta :
  `appcast-beta-arm64.xml`, `appcast-beta-x86_64.xml`
- Les flux de mise à jour se trouvent toujours dans la dernière version Stable sur GitHub ; une
  version Beta ne remplace que les fichiers `appcast-beta-*` correspondants. L’URL fixe ne cesse
  donc pas de fonctionner lorsque GitHub exclut les préversions.
- Chaque enclosure d’appcast doit posséder une `sparkle:edSignature`, et les apps de production
  doivent également contenir la `SUPublicEDKey` correspondante.
- Les sept fichiers de notes de version se trouvent dans
  `docs/release-notes/v<version>/release-notes.<language>.md`.

Consultez [`docs/UPDATES.md`](docs/UPDATES.md) pour tous les détails concernant les secrets, la
signature, la notarisation et le processus de publication.

## Première connexion

Codex n’ouvre pas de port CDP lorsqu’il est lancé normalement. La première fois que vous cliquez
sur « Lancer et connecter Codex », si aucun Codex debug target partageable n’est disponible, Theme
Switcher demande d’abord à Codex de se fermer normalement, puis le relance avec les arguments
suivants :

```text
--remote-debugging-address=127.0.0.1
--remote-debugging-port=57340
--remote-allow-origins=http://127.0.0.1:57340
```

Si `codex-desktop-switcher` a déjà créé un Codex target sur l’un des ports 57330–57341, le programme
le partage au lieu de relancer Codex.

## Format `.codextheme`

`.codextheme` est une enveloppe JSON unique et versionnée :

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

Des fichiers prêts à être importés sont disponibles dans
[`Examples/minimal.codextheme`](Examples/minimal.codextheme) et
[`Examples/full.codextheme`](Examples/full.codextheme). Les agents peuvent utiliser
[`codextheme.schema.json`](Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json) pour
générer et valider le JSON ; les dates sont toujours émises au format ISO-8601, tandis que
l’importation reste compatible avec les dates numériques des anciennes versions de Foundation. Le
JSON Schema accepte également les deux formes de date et fournit une vérification rapide de la
structure, des énumérations et des plages numériques ; le validateur Core demeure l’autorité finale
pour l’analyse de sécurité CSS et les limites de taille totales.

L’ordre de la theme cascade est fixe :

1. semantic variables et aliases des Codex stable tokens
2. advanced/custom variables
3. component overrides
4. selector rules
5. règles d’arrière-plan, de palette et de glass générées par Image Skin
6. raw CSS

Les éléments 1 à 4 sont compilés selon l’ordre des layers ; Image Skin remplace ensuite les
réglages d’interface structurés, puis le raw CSS est émis en dernier selon l’ordre des layers, ce
qui fait de Raw CSS le véritable escape hatch final. Par défaut, les conflits d’ID lors de
l’importation sont résolus en créant un clone doté d’un nouvel UUID et le thème importé n’est pas
appliqué automatiquement.

Les ressources intégrées sont référencées dans le CSS ainsi :

```css
body {
  background-image: theme-asset("ASSET-UUID");
}
```

Lors de la compilation, cette référence est réécrite de manière sûre en un placeholder court
`codex-theme-asset://`. Le runtime envoie les ressources à chaque moteur de rendu par fragments de
256 KiB et crée des Blob URL dans le moteur de rendu avant de changer le style de manière
atomique ; les ressources identiques réutilisent le même Blob et les URL qui ne sont plus utilisées
sont révoquées lors du changement ou de l’effacement d’un thème.

## Données locales

```text
~/Library/Application Support/CodexThemeSwitcher/
  Themes/                 # user theme JSON
  active-theme.json       # repository active pointer
  Runtime/
    active-theme.json     # runtime CSS template、asset manifest 與資料
    bridge-token          # mode 0600
  Logs/runtime.log
```

## Architecture

- `CodexThemeSwitcherCore` : schéma de thème, validateur, compilateur, dépôt et archive.
- `CodexThemeRuntime` : runner Swift asynchrone et runtime Node/CDP authentifié.
- `CodexThemeSwitcher` : studio AppKit/SwiftUI dans la barre des menus.
- `codex-theme` : CLI JSON structurée et moteur de rendu PNG sans fenêtre pour les agents IA et
  l’automatisation.
- `Tests/` : suites de tests Swift.
- `test/` : suites de tests du runtime Node.

Les selector rules constituent une couche experte et peuvent nécessiter des ajustements après une
mise à jour de Codex. Les layers de base et `--color-token-*` utilisent principalement le contrat
CSS actuel de Codex et dépendent moins des noms de classes React.
