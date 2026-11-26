# Architecture — Rouages

## Principes (et pourquoi)
1. **La logique ne connaît pas les visuels.** `board/`, `swarm/`, `waves/`… sont du calcul pur ; les scènes `*_visuel`
   observent l'état et l'affichent. → On remplace le greybox par la vraie 3D sans toucher au gameplay ;
   Codex (`game/`) et Antigravity (`assets/`) ne se marchent pas dessus ; la logique se teste en headless.
2. **Données en Resources `.tres`** (`data/`). → L'équilibrage se fait sans code ; fichiers minuscules = peu de tokens.
3. **Énergie par propagation (BFS) depuis l'horloge**, recalculée **uniquement** sur `Events.plateau_modifie`.
   Chaque tuile a 4 côtés, chacun avec ou sans port d'engrenage ; tourner une tuile fait tourner ses ports.
4. **Nuées orientées données** : `SwarmSim` manipule des tableaux (positions, PV, cibles). Les ennemis suivent un
   **champ de flux** vers l'horloge (recalculé sur changement de plateau). Les combats passent par une **grille spatiale**.
   Le rendu utilise 1 `MultiMeshInstance3D` par type d'unité. Pas de physique Godot. Objectif : 300 contre 300 à 60 FPS.
5. **Bus d'événements minimal** (`Events`) : un signal n'existe que s'il est écouté par un autre système.

## Boucle de run (`Run`, autoload)
`DRAFT` (1 lot parmi 3, tiré d'une pioche pondérée) → `CONSTRUCTION` (poser et orienter ce qu'on possède) → `VAGUE` → … ×10
→ `FIN` (victoire/défaite → rejouer). Toutes les transitions passent par `Run` (`choisir_lot`, `lancer_vague`,
`terminer_vague`, `subir_degats`) : la machine à états tient dans un seul fichier, testable en headless.
- **Réserve** (`Run.reserve`) : on ne pose que ce qu'on a drafté. Le plateau et la réserve de départ sont dans `data/depart.tres`,
  la pioche et la liste des vagues dans `data/regles.tres`.
- **Extensions de terrain** (`data/extensions/`) : un morceau de sol 3×3 accolé au bord. Son chemin doit se raccorder au réseau et
  ajouter **au moins une entrée** (sinon la pose est refusée). Le bonus de pièces arrive à la pose, jamais au draft.
- **Remontage** : en CONSTRUCTION, les ateliers alimentés produisent et les jouets rejoignent leur poste (aucun ennemi).
  → Pas de spirale de défaite (une vague ratée ne vide plus l'armée de la suivante), et un retour visuel immédiat à la pose.
- **Répartition aux embranchements** : chaque jouet tire une branche au hasard à sa naissance. → Chaque front reçoit sa part.

## Arborescence
| Dossier | Contenu | Qui |
|---|---|---|
| `game/core/` | autoloads `Events`, `Run` | Claude |
| `game/board/` | grille, tuiles, rotation, énergie | Codex |
| `game/swarm/` | SwarmSim, champ de flux, grille spatiale, rendu MultiMesh | Codex (spec Claude) |
| `game/workshops/ waves/ draft/ camera/ ui/` | ateliers, vagues, draft, caméra, interface | Codex |
| `data/tuiles/ unites/ vagues/` | `.tres` d'équilibrage | Claude (valeurs) / Codex (classes) |
| `assets/` | greybox, final, matériaux, audio | Antigravity |
| `tests/` | tests de logique headless (`./scripts/tests.sh`) | Codex + Claude |
| `taches/` | fiches de délégation, `revues/` | Claude |
| `scripts/` | bridges, tests, `banc_equilibrage.gd` (simule une run headless, mesure les fuites) | Claude |

## Contrat d'assets
1 tuile = 2 m × 2 m · origine au centre de la base · Y vers le haut · `.glb` · `assets/final/<nom>/`.

## Signaux (`game/core/events.gd`)
`plateau_modifie` · `energie_recalculee(alimentees)` · `phase_changee(phase)` · `vague_commencee(n)` ·
`vague_terminee(n)` · `horloge_touchee(pv)` · `tuile_choisie(id)` · `run_terminee(victoire)`

## Entrées (InputMap)
`poser_tuile` (clic gauche) · `tourner_tuile` (R / clic droit) · `annuler` (Échap) · `basculer_camera` (Tab) ·
`camera_gauche/droite/haut/bas` (Q·D·Z·S en AZERTY : touches physiques) · `camera_zoom_avant/arriere` (molette) · `accelerer` (Espace).

## Journal des décisions
- 2026-11-23 : Godot 4.7.2, Forward+, GDScript, PC d'abord (itch.io puis Steam). Mini-lanceur de tests maison (zéro addon).
- 2026-11-23 : Codex écrit directement dans le dépôt (pas de `drafts/`), limité aux fichiers de la fiche ; git sert de filet.
- 2026-11-26 : étape 5. Draft par **lots** (`Lot` = objet + quantité + poids + vague minimale), réutilisés pour la pioche, la réserve
  de départ et les bonus d'extension. Équilibrage mesuré au banc (`scripts/banc_equilibrage.gd`) plutôt que deviné : un atelier à
  plein stock encaisse environ 30 PV de scarabée par seconde ; le débit d'une vague vaut `10 × multiplicateur / intervalle`.
  Le banc a fait ajouter la répartition aux embranchements et le remontage (voir « Boucle de run »).
