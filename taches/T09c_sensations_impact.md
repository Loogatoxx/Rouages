# T09c — Sensations d'impact (« ça paraît mou »)
**Pour** : Codex · **Étape roadmap** : 9 · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Le testeur trouve le combat « mou ». Rendre chaque coup lisible et satisfaisant, sans changer l'équilibrage : billes des
lance-billes visibles en vol, ennemis qui flashent quand ils sont touchés, petit rebond de l'atelier quand un jouet sort.
DA : jouet en bois, laiton doux, crème ; pas de néon.

## Fichiers autorisés
- game/swarm/swarm_sim.gd (ajouts en lecture/signal uniquement, aucun changement de règle)
- game/swarm/nuee_visuel.gd
- game/board/plateau_visuel.gd (rebond des ateliers uniquement)
- game/workshops/production.gd (signal uniquement), game/main.gd (deux lignes de branchement)
- tests/test_swarm_sim.gd (ajout d'un test pour le signal de tir)

## À lire avant
AGENTS.md · game/swarm/swarm_sim.gd (`_decider`, `Nuee`) · game/swarm/nuee_visuel.gd · game/workshops/production.gd ·
game/board/plateau_visuel.gd · game/core/partie.gd (lecture seule : relie sim et production)

## Contrat
- `SwarmSim` : `signal tir(depart: Vector2, arrivee: Vector2)` émis quand une unité **alliée de portée > 1,0 m** frappe
  (une fois par frappe effective, pas par pas de simulation). Tableau parallèle `touches: PackedFloat32Array` par nuée
  (temps restant du flash, 0,12 s à chaque coup reçu, décrémenté dans `avancer`, maintenu par `_retirer`) et accesseur
  `touches(camp) -> PackedFloat32Array`.
- `Production` : `signal jouet_produit(case: Vector2i)` émis à chaque jouet ajouté.
- `NueeVisuel` : réserve recyclée de 48 billes (petites sphères laiton) qui volent de `depart` à `arrivee` en 0,18 s avec un
  léger arc (hauteur max 0,5 m) ; les ennemis dont `touches > 0` sont dessinés en crème clair `#FFF3D6` (couleur par
  instance) et légèrement grossis (×1,12). `NueeVisuel` se branche à `sim.tir` quand `sim` est assigné (setter).
- `PlateauVisuel` : `rebondir(case: Vector2i)` → la racine de la pièce fait 1 → 1,1 → 1 en 0,16 s (Tween, pas de cumul :
  ignorer si un rebond est déjà en cours sur cette case). Le branchement `production.jouet_produit → rebondir` se fait dans
  `game/main.gd` (autorisé pour **deux lignes** : `$Partie.production.jouet_produit.connect($PlateauNoeud/PlateauVisuel.rebondir)`).

## Hors périmètre
Aucun changement de dégâts, PV, cadence, portée ; pas d'UI ; pas de `data/`.

## Critère de fin
`./scripts/tests.sh` au vert (+ test : un lance-bille à portée émet `tir`, un soldat au contact n'en émet pas) ;
`Godot --headless --path . --quit-after 120` sans erreur ; perf : `test_performance` ne régresse pas de plus de 15 %.
