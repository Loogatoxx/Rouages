# T06a — Jouets lisibles sur le chemin crème
**Pour** : Codex · **Étape roadmap** : 6 · **Modèle/effort** : gpt-6.2-sol medium

## Objectif
Retour de playtest : les soldats-jouets (pastels clairs) se confondent avec le chemin `pierre_creme` (#EFE3C8).
On passe les jouets en « peinture de jouet » : teintes chaudes plus profondes et saturées, jamais néon ni sombres,
et on leur ajoute un petit chapeau foncé qui donne une silhouette lisible vue de haut.

## Fichiers autorisés
- game/core/materiaux.gd (modifier : ajouter des couleurs)
- game/swarm/nuee_visuel.gd (modifier)
- tests/test_contraste.gd (créer)

## À lire avant
- AGENTS.md · tests/test_socle.gd (format des tests)

## Contrat
1. `Materiaux.COULEURS` reçoit 4 entrées (ne pas toucher aux existantes) :
   `"jouet_rouge": "#C8553D"`, `"jouet_bleu": "#3D6FA8"`, `"jouet_vert": "#4F8A5B"`, `"jouet_prune": "#8A5A9E"`,
   et `"chapeau": "#4A3426"` (brun chocolat, pas de noir pur).
2. Ajouter `static func contraste(a: Color, b: Color) -> float` dans `Materiaux` : ratio WCAG
   ((L1+0.05)/(L2+0.05), L = luminance relative sur couleurs linéarisées, L1 = la plus claire).
3. `nuee_visuel.gd` : `PASTELS` devient `TEINTES := ["jouet_rouge", "jouet_bleu", "jouet_vert", "jouet_prune"]`.
   Ajouter un 3ᵉ MultiMesh « chapeaux » (CylinderMesh rayon 0.13, hauteur 0.14, couleur `chapeau`, non ombré inutilement),
   posé sur le dessus de chaque jouet (y = 0.2 + 0.2 + 0.07), même nombre d'instances et même cap que les jouets.
   Le chapeau ne doit **pas** être compté comme un camp : garder `_lots` indexé par camp et gérer les chapeaux à part.
4. Rien d'autre ne change (scarabées laiton, tailles, hauteurs).

## Hors périmètre
Pas de nouveaux fichiers .tres, pas de shader, pas de contour/outline, aucune modification de la simulation ou des données.

## Critère de fin
- `./scripts/tests.sh` au vert, avec `tests/test_contraste.gd` :
  `test_jouets_contrastent_avec_chemin` (chaque teinte de `TEINTES` a un contraste ≥ 3.0 avec `pierre_creme`),
  `test_jouets_contrastent_avec_herbe` (≥ 1.6 avec `herbe`), `test_chapeau_contraste` (≥ 3.0 avec chaque teinte… ou, si
  impossible pour une teinte foncée, ≥ 1.8 : documenter la valeur obtenue dans le compte rendu).
- `Godot --headless --path . --quit-after 60` sans erreur de script.
