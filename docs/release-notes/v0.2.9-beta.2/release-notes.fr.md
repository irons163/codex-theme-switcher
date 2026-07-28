# Codex Theme Switcher 0.2.9-beta.2

## Connexions Codex plus fiables

- Sélectionne automatiquement le prochain port loopback disponible lorsque le port bridge par défaut est occupé, afin que Theme Switcher puisse continuer à communiquer avec Codex.
- Enregistre le port bridge choisi pour chaque dossier de données Theme Switcher afin que les commandes suivantes se reconnectent de façon cohérente.
- Maintient un comportement strict pour les ports configurés explicitement : un conflit produit une erreur au lieu de changer silencieusement de port.
- Ajoute des tests de régression du port bridge et une nouvelle image de présentation du thème aux sept versions linguistiques du README.
