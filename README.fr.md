# Codex Theme Switcher

[English](README.md) | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | **Français** | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

![Codex avec un arrière-plan illustré, des effets de verre et des composants personnalisés par Codex Theme Switcher](docs/images/codex-theme-showcase.jpg)

Une app native pour la barre des menus de macOS permettant de créer, prévisualiser, appliquer et partager des thèmes pour l’app de bureau Codex / ChatGPT.

Theme Switcher injecte des styles temporaires lorsqu’il lance Codex. Il ne modifie, ne remplace et ne signe à nouveau jamais l’app d’origine.

## Télécharger

**Version stable actuelle : 0.3.0**

[DMG Apple Silicon](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-apple-silicon.dmg)
·
[DMG Intel](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-intel.dmg)
·
[Notes de version et sommes de contrôle](https://github.com/irons163/codex-theme-switcher/releases/tag/v0.3.0)

Nécessite macOS 13 ou une version ultérieure. Les deux programmes d’installation sont signés et notariés par Apple.

## Points forts

- Bibliothèque de thèmes, éditeur, aperçu en direct et état de connexion dans la barre des menus.
- Couleurs, polices, espacements, arrondis, ombres, flou, mise à l’échelle et animations.
- Images distinctes en mode clair et sombre avec Fit, Fill, point focal, filtres, voiles et verre.
- Personnalisation expérimentale de ChatGPT Voice : arrière-plan, orbe, portrait animé, formes de bouche, clignement des yeux et mouvement au repos.
- Réglages avancés des composants, règles de sélecteur, variables personnalisées et CSS brut.
- Importation et exportation dans un seul fichier `.codextheme` avec images et polices intégrées.
- Anglais, chinois traditionnel, chinois simplifié, français, espagnol, japonais et coréen.

## Démarrage rapide

1. Installez et ouvrez Codex Theme Switcher, puis cliquez sur son icône dans la barre des menus de macOS.
2. Cliquez sur **Lancer et connecter Codex**. La première connexion peut relancer Codex.
3. Choisissez un thème intégré, créez une copie modifiable ou créez un nouveau thème.
4. Ajustez le design et vérifiez les aperçus Clair / Sombre et Accueil / Chat.
5. Enregistrez le thème, puis cliquez sur **Appliquer** pour l’envoyer à Codex.
6. Utilisez **Exporter** pour partager un `.codextheme` et **Importer** pour installer un thème reçu.

La première connexion n’applique pas automatiquement le thème sélectionné. Les connexions suivantes restaurent le dernier thème correctement appliqué, mais pas les brouillons non appliqués.

## Captures d’écran

### Studio de thèmes

![Studio Codex Theme Switcher avec bibliothèque, aperçu en direct et onglets d’édition](docs/images/theme-studio.png)

### Aperçus du moteur de rendu

| Paper · Clair / Accueil | Midnight · Sombre / Chat |
| --- | --- |
| ![Aperçu Paper clair sur l’accueil](docs/images/paper-light-home.png) | ![Aperçu Midnight sombre dans le chat](docs/images/midnight-dark-chat.png) |

Les aperçus générés par un agent restent des approximations fidèles. Vérifiez toujours le CSS avancé et les règles de sélecteur dans l’app Codex avant de partager un thème.

## Guide de personnalisation

### Arrière-plan et verre

- Choisissez des images différentes pour les modes Clair et Sombre, ou réutilisez la même image avec des effets distincts.
- Utilisez Fit, Fill, Stretch, Fit Width, Fit Height, Original ou Tile, puis ajustez le point focal et le zoom.
- Réglez l’opacité et les filtres de l’image indépendamment du verre de la barre latérale, du contenu, du composeur, des cartes, des menus et des blocs de code.
- Étendez le fond d’écran à toute la fenêtre ou excluez la barre latérale.
- Ajoutez un panneau central avec son propre fond, bordure, ombre, flou, rayon, largeur et espacement interne.

### ChatGPT Voice (expérimental)

- Définissez un arrière-plan Voice et une image distincte dans l’orbe animé.
- Ajoutez un portrait bouche fermée et jusqu’à huit formes de bouche, ou importez une planche 2×2 / 3×3.
- Réglez la sensibilité, le seuil de silence, la vitesse d’ouverture et de fermeture, le clignement, le mouvement au repos, la pulsation et la visibilité de l’orbe natif.
- La bouche suit l’intensité sonore ; il ne s’agit pas d’une synchronisation labiale par phonèmes.

Le style Voice dépend du moteur de rendu interne de ChatGPT et peut nécessiter une mise à jour après une nouvelle version de Codex / ChatGPT.

## Importation et exportation

- L’exportation crée un seul `.codextheme` contenant les réglages et les ressources intégrées.
- Un thème importé n’est pas appliqué automatiquement : vérifiez-le, puis cliquez sur **Appliquer**.
- Image Skin prend en charge PNG, JPEG, WebP, GIF et AVIF.
- Limites : 16 Mo par ressource, 32 Mo au total et 48 Mo par `.codextheme`.

Exemples : [`minimal.codextheme`](Examples/minimal.codextheme) et [`full.codextheme`](Examples/full.codextheme).

## Créer avec un agent IA

Après l’installation, donnez cette instruction à un agent IA :

```text
Utilise cet Agent CLI pour créer un thème Codex :
/Applications/CodexThemeSwitcher.app/Contents/Helpers/codex-theme

Exécute d’abord capabilities et schema. Termine validate, compile et les quatre aperçus.
N’applique pas le thème sans ma confirmation.
```

Le CLI peut créer, valider, compiler, importer, exporter et générer les aperçus Clair / Sombre × Accueil / Chat. Seules les commandes explicites `attach`, `apply` ou `clear` modifient Codex.

Consultez [`docs/AGENT_API.md`](docs/AGENT_API.md) pour la référence des commandes.

## Langues et mises à jour

- L’app suit automatiquement la langue de macOS ; les langues non prises en charge utilisent l’anglais.
- Choisissez manuellement une langue dans **Réglages → Langue de l’interface**.
- Choisissez le canal Stable ou Beta dans les réglages.
- Les mises à jour utilisent Sparkle et fournissent la bonne version Apple Silicon ou Intel.

## Sécurité et restauration

- Theme Switcher ne modifie pas `app.asar` et ne remplace aucun fichier de Codex / ChatGPT.
- Les thèmes et le pont de connexion restent sur le Mac local.
- Les thèmes importés ne peuvent pas exécuter de JavaScript ni charger d’URL distantes ou de fichiers locaux.
- Si du CSS personnalisé rend Codex illisible, choisissez **Restaurer les styles Codex d’origine** dans l’app de la barre des menus.
- Quitter Codex et le rouvrir normalement supprime les styles injectés temporairement.

Ce projet est indépendant et n’est ni affilié à OpenAI ni approuvé par OpenAI.

## Compiler depuis les sources

Prérequis : macOS 13+, Swift 6, Node.js 22+ et l’app de bureau Codex / ChatGPT.

```sh
swift build
swift test
npm test
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

Documentation pour les développeurs :

- [Agent CLI](docs/AGENT_API.md)
- [Mises à jour, signature, notarisation et publication](docs/UPDATES.md)
