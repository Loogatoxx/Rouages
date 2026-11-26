# T04 — Ateliers producteurs, vagues de scarabées, PV de l'horloge, victoire et défaite
**Pour** : Codex · **Étape roadmap** : 4 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Première boucle jouable dans `main.tscn`. En phase CONSTRUCTION, le joueur pose et oriente ses pièces, puis clique sur « Lancer la vague ».
En phase VAGUE, les scarabées arrivent par les entrées du chemin et les **ateliers alimentés** produisent des jouets. Chaque scarabée
qui atteint l'horloge lui retire des PV. Vague vidée → retour en CONSTRUCTION. PV à 0 → défaite. Dernière vague gagnée → victoire.
« Rejouer » relance tout. (Le draft viendra à l'étape 5 : la palette provisoire reste.)

## Fichiers autorisés
- game/board/piece_def.gd · data/tuiles/atelier_soldats.tres · game/swarm/champ_flux.gd · game/core/run.gd · game/board/pose_controleur.gd (modifier)
- game/core/regles.gd · data/regles.tres · game/core/partie.gd (créer)
- game/workshops/production.gd · game/waves/vague_def.gd · game/waves/directeur_vagues.gd (créer)
- data/vagues/vague_01.tres · vague_02.tres · vague_03.tres (créer)
- game/ui/hud.gd · game/ui/hud.tscn (créer) · game/main.tscn · game/main.gd (modifier)
- tests/test_production.gd · tests/test_vagues.gd (créer)

## À lire avant
AGENTS.md · game/core/events.gd · game/core/run.gd · game/swarm/swarm_sim.gd (API publique seulement) · game/swarm/champ_flux.gd ·
game/board/plateau_noeud.gd · game/board/pose_controleur.gd · game/main.tscn

## Contrat
- `PieceDef` : ajoute `@export var unite_produite: UniteDef` et `@export var cadence_production: float` (jouets/s, 0 = ne produit pas).
  atelier_soldats : soldat_remontoir, 0,6.
- `regles.gd` — `class_name Regles extends Resource` : `pv_horloge: int` (20), `plafond_allies_par_atelier: int` (15),
  `multiplicateur_acceleration: float` (2,0). Valeurs dans `data/regles.tres`.
- `ChampFlux` : ajoute `static func entrees(plateau: Plateau, distances: Dictionary) -> Array[Vector2i]` = cases du champ
  (distance > 0) qui touchent une case **sans sol**, triées. Sur le plateau de départ : (4, -4) et (4, 4).
- `run.gd` : ajoute `var regles: Regles` (chargé depuis `data/regles.tres`), `var pv_horloge: int`, `var nb_vagues: int`
  (= nombre de vagues chargées) et `func subir_degats(d: float) -> void` (émet `Events.horloge_touchee`, puis passe en FIN avec
  `Events.run_terminee(false)` à 0). Phase de départ **provisoire** : CONSTRUCTION. `reinitialiser()` remet les PV et la vague à zéro.
- `vague_def.gd` — `class_name VagueDef extends Resource` : `unite: UniteDef`, `nombre: int`, `intervalle: float` (s), `multiplicateur_pv: float`.
  Données : v01 = 20 scarabées / 0,6 s / ×1 · v02 = 45 / 0,35 s / ×1,2 · v03 = 90 / 0,2 s / ×1,5.
- `directeur_vagues.gd` — `class_name DirecteurVagues extends RefCounted`, logique pure : `commencer(vague: VagueDef, entrees: Array[Vector2i])`,
  `avancer(dt: float, sim: SwarmSim)` (fait apparaître les unités en alternant les entrées, avec un léger décalage aléatoire ≤ 0,5 m),
  `func est_terminee(sim: SwarmSim) -> bool` (toutes les unités sont apparues et `nombre(ENNEMI) == 0`). Le multiplicateur de PV
  s'applique via une copie de l'UniteDef (`duplicate()`) : ne modifie jamais le `.tres`.
- `production.gd` — `class_name Production extends RefCounted`, logique pure : `avancer(dt, plateau, alimentees: Dictionary, sim, regles)`.
  Chaque atelier **alimenté** avec `cadence_production > 0` accumule du temps et fait apparaître son unité au bord de sa case, côté
  de son port, tant que `sim.nombre(ALLIE) < plafond_allies_par_atelier × nb d'ateliers alimentés`.
- `partie.gd` — `Node`, chef d'orchestre de la scène : possède `sim: SwarmSim`, `production`, `directeur`. Il écoute
  `Events.plateau_modifie` → `sim.configurer`. En phase VAGUE seulement : `production.avancer`, `directeur.avancer`, `sim.avancer`
  (dt × multiplicateur si l'action `accelerer` est maintenue). `sim.ennemi_arrive` → `Run.subir_degats`. Vague terminée →
  `Events.vague_terminee`, puis CONSTRUCTION, ou FIN + `run_terminee(true)` après la dernière. La sim est **figée** hors VAGUE.
- `pose_controleur.gd` : pose et rotation autorisées **seulement** en phase CONSTRUCTION (fantôme masqué sinon).
- `hud` — `CanvasLayer` : PV de l'horloge, « Vague n / N », bouton « Lancer la vague » (visible en CONSTRUCTION), et en FIN
  un panneau « Victoire ! » / « L'horloge s'est arrêtée… » avec un bouton « Rejouer » (`Run.reinitialiser()` + `reload_current_scene()`).
  Ton doux et joyeux, pas de rouge agressif.
- `main.tscn` : ajoute Partie, un NueeVisuel branché sur `Partie.sim`, et le HUD.

## Hors périmètre
Pas de draft, pas de coût de pièces, pas de loot, pas de nouveaux signaux dans Events (demande-les si besoin), pas d'assets 3D.

## Critère de fin
`./scripts/tests.sh` au vert, avec au minimum :
1. `entrees` sur le plateau de départ → [(4, -4), (4, 4)].
2. un atelier alimenté produit environ `cadence × t` unités ; un atelier non alimenté n'en produit aucune ; le plafond est respecté.
3. le directeur fait apparaître exactement `nombre` unités, en alternant les entrées ; `est_terminee` reste faux tant qu'un ennemi vit.
4. le multiplicateur de PV ne modifie pas `data/unites/scarabee.tres`.
5. `data/regles.tres` et les 3 vagues se chargent avec les bons types.
Plus : `Godot --headless --path . --quit-after 60` sans erreur, et 5 lignes de test manuel pour Carlos.
