# T07b — Horloge 3D depuis l'image validée
**Pour** : Antigravity · **Étape roadmap** : 7 · **Modèle** : gemini-4-neon-xhigh · **Crédits Hyper3D autorisés : 1**

## Objectif
Carlos a validé `art_refs/horloge_v1_b.png` (clocher, clé de remontoir). En faire le modèle final de l'horloge.

## Fichiers autorisés
- assets/final/horloge/horloge.glb (créer) · assets/final/horloge/apercu.png (créer : rendu Blender)
- assets/CREDITS_HYPER3D.md (ajouter une ligne : date, horloge, 1, T07b, 43)

## À lire avant
CLAUDE.md §5 · docs/architecture.md « Contrat d'assets » · assets/greybox/horloge/horloge.glb (échelle de référence)

## Contrat
1. **Un seul** appel Hyper3D Image-to-3D sur `art_refs/horloge_v1_b.png` (Carlos confirme l'appel). Si le résultat est
   inexploitable : s'arrêter et le dire, **pas de 2ᵉ appel**.
2. Blender MCP : nettoyer (supprimer le fond éventuel, fusionner les éléments flottants, la vapeur peut être retirée),
   réduire à moins de 15 000 triangles, garder les textures (embarquées dans le `.glb`).
3. Contrat d'assets : socle ≈ 2 m × 2 m (1 case), hauteur ≈ 3 m, origine au centre de la base, Y vers le haut, cadran tourné vers −Z.
4. Rendu `apercu.png` : vue 3/4 éclairée chaudement.

## Hors périmètre
Ne rien modifier dans `game/`, `data/`, `tests/` (l'intégration en jeu sera une fiche Codex séparée). Aucun autre crédit.

## Critère de fin
`horloge.glb` s'importe dans Godot (`Godot --headless --path . --import` sans erreur) ; compte rendu de 5 lignes
(triangles, dimensions mesurées, crédits restants).
