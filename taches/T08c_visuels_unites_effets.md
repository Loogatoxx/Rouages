# T08c — Visuels des nouvelles unités et ateliers, effets 3D
**Pour** : Codex · **Étape roadmap** : 7b (rush jouabilité) · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Le scarabée cuirassé, le lance-bille et l'atelier de lance-billes (ajoutés en T08a) doivent se reconnaître d'un coup d'œil
en vue de dessus. Ajouter des retours 3D légers : petit éclat quand un ennemi casse, horloge qui « sursaute » et caméra qui
tremble doucement quand l'horloge est touchée. DA : jouet en bois, laiton doux, pastels ; pas de néon, pas de sombre.

## Fichiers autorisés
- game/swarm/nuee_visuel.gd
- game/swarm/swarm_sim.gd (ajout d'un seul accesseur en lecture, voir contrat ; rien d'autre)
- game/board/plateau_visuel.gd
- game/camera/camera_plateau.gd
- game/core/materiaux.gd (ajout de couleurs uniquement)

## À lire avant
AGENTS.md · game/swarm/nuee_visuel.gd · game/swarm/swarm_sim.gd (classe `Nuee`, `modeles`) · game/board/plateau_visuel.gd ·
data/unites/*.tres (ids : `soldat_remontoir`, `lance_bille`, `scarabee`, `scarabee_cuirasse`) ·
data/tuiles/atelier_billes.tres · game/core/events.gd (`ennemi_casse`, `horloge_touchee`)

## Contrat
- `SwarmSim.modeles(camp: int) -> Array[UniteDef]` : renvoie le tableau des modèles (même indice que `positions`).
- `NueeVisuel` : un `MultiMesh` **par id d'unité** (créé à la première rencontre d'un id, capacité `SwarmSim.CAPACITE`),
  rempli chaque image en parcourant `positions`/`caps`/`modeles`. Formes :
  - `soldat_remontoir` : inchangé (boîte teintée + chapeau) ;
  - `lance_bille` : cylindre pastel vert menthe (couleur `jouet_menthe` `#6FB59A`, contraste ≥ 3 sur `pierre_creme`,
    vérifier avec `Materiaux.contraste`) surmonté d'une petite sphère laiton (la « bille ») ;
  - `scarabee` : inchangé ;
  - `scarabee_cuirasse` : sphère aplatie 1,6 × plus grande, couleur cuivre chaud `#B0643A` + petite crête claire ;
  - id inconnu : forme du soldat (allié) ou du scarabée (ennemi).
- Éclats : sur `Events.ennemi_casse(position)`, un petit `CPUParticles3D` à usage unique (8-12 copeaux crème/laiton,
  0,4 s, `one_shot`) tiré d'une **réserve recyclée** de 24 émetteurs (jamais d'allocation par mort).
- `PlateauVisuel` : l'atelier de lance-billes (`piece.id == &"atelier_billes"`) = boîte pastel vert + petite tour
  cylindrique et une sphère laiton au sommet ; l'atelier de soldats reste tel quel. Sur `Events.horloge_touchee`, la racine
  de l'horloge fait un petit rebond d'échelle (1 → 1,08 → 1 en 0,25 s, Tween).
- `CameraPlateau` : sur `Events.horloge_touchee`, secousse douce (amplitude ≈ 0,15 m, 0,25 s, décroissante), appliquée en
  décalage autour de la position calculée par `_appliquer_vue` (ne pas casser zoom, déplacement ni bascule).

## Hors périmètre
Aucune logique de jeu, aucune UI, aucun son, pas de `data/`, pas d'`assets/`. Le fantôme de pose (teinte) garde les mêmes formes.

## Critère de fin
`./scripts/tests.sh` au vert ; `Godot --headless --path . --quit-after 120` sans erreur de script.
