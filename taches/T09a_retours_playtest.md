# T09a — Retours de playtest : ennemis visibles, pose en vague, rotation payante, plateaux, défi du jour, fourmis
**Pour** : Codex · **Étape roadmap** : 9 (retours playtest externe) · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Un testeur externe a « à peine vu un ennemi » : les jouets foncent camper sur les entrées et cassent les scarabées à leur
apparition ; ils s'empilent et cachent tout ; on s'ennuie pendant les vagues ; tourner une pièce posée étant gratuit, la
placer ne demande plus de réflexion ; la pose d'extension n'est pas claire ; il veut plus de cartes, d'ennemis, un défi du jour.

## Fichiers autorisés
- game/core/partie.gd (une ligne : appel de `configurer`), game/swarm/swarm_sim.gd, game/swarm/nuee_visuel.gd, game/core/run.gd, game/core/regles.gd, game/core/depart_def.gd
- game/board/pose_controleur.gd, game/board/plateau_visuel.gd (marqueurs de pose d'extension uniquement)
- data/regles.tres, data/depart.tres, data/unites/soldat_remontoir.tres, data/unites/lance_bille.tres
- data/departs/meandres.tres, data/departs/fourche.tres, data/unites/fourmi.tres (créer)
- data/vagues/vague_03.tres … vague_10.tres (ajout des fourmis en `renfort` si la vague n'a pas déjà de cuirassés : voir contrat)
- tests/test_garde.gd, tests/test_departs.gd (créer), tests adaptés si une valeur de données attendue change

## À lire avant
AGENTS.md · game/swarm/swarm_sim.gd (`configurer`, `_objectif_flux`, `_distances`) · game/swarm/champ_flux.gd ·
game/core/run.gd · game/board/pose_controleur.gd · game/board/extension.gd (`est_valide`) · data/depart.tres

## Contrat
1. **Garde des jouets** : `Regles.garde_ratio: float = 0.55`. Dans `SwarmSim.configurer`, mémoriser `distance_max` (plus
   grande distance de chemin à l'horloge). Un allié **sans cible en poursuite** dont la case a `distance > garde_ratio ×
   distance_max` n'avance plus vers les entrées : il reste sur place (il peut toujours poursuivre/frapper une cible à portée).
   `SwarmSim.garde_ratio` (var publique, défaut 1.0 = comportement actuel ; `Partie` n'est pas à modifier : `Run` ou le
   code appelant règle `sim.garde_ratio = Run.regles.garde_ratio` — fais-le dans `SwarmSim.configurer(plateau, garde_ratio
   := 1.0)` et adapte l'appel de `partie.gd` **en une ligne** (fichier autorisé pour cette seule ligne)).
   → Les ennemis parcourent visiblement ~45 % du chemin avant le contact.
2. **Moins d'empilement** : rayon des alliés 0.25 → 0.3 (`soldat_remontoir.tres`, `lance_bille.tres`) ; dans
   `nuee_visuel.gd`, soldat un peu plus petit (boîte 0.46 × 0.36 × 0.3) et ennemis dessinés 0,04 m plus haut que les alliés.
3. **Pose pendant les vagues** : `PoseControleur` autorise pose, rotation et sélection en CONSTRUCTION **et** en VAGUE
   (la désélection automatique ne se fait plus qu'en DRAFT et FIN).
4. **Rotation payante** : `Regles.prix_rotation: int = 2`. Tourner une pièce **déjà posée** appelle `Run.depenser(prix)` ;
   refus sans ressorts (son `rotation` seulement si réussi). Le fantôme avant la pose reste gratuit à tourner.
5. **Aide à la pose d'extension** : quand une extension est sélectionnée, `PlateauVisuel.afficher_marqueurs(cases:
   Array[Vector2i])` affiche un petit disque bleu `#3D8FD9` (alpha 0,7) au centre de chaque position valide ; le contrôleur
   calcule les positions valides (toutes cases à ≤ 2 du bord du terrain × 4 rotations, via `Extension.est_valide`) une fois
   à la sélection et après chaque `plateau_modifie`. Au survol d'une position valide dont la rotation courante est
   invalide, choisir automatiquement la première rotation valide. Marqueurs effacés à la désélection.
6. **Plateaux de départ** : `Regles.departs: Array[DepartDef]` = Prairie (`data/depart.tres`, ajouter `nom` « Prairie »),
   Méandres (chemin long en S depuis le bord nord), Fourche (deux chemins dès le départ, est et ouest, réserve +1 atelier).
   `DepartDef` gagne `@export var nom: String` et `@export var description: String`. Horloge en (0,0), terrain 9×9 comme
   Prairie ; chaque chemin doit relier un bord à une case voisine de l'horloge (vérifié par test avec `ChampFlux`).
   `Run.choisir_depart(i: int)` (à appeler avant `reinitialiser`), `Run.depart` devient la sélection.
7. **Défi du jour** : `Run.defi_du_jour: bool` ; `Run.preparer_defi(date: String)` → plateau = `departs[hash(date) %
   departs.size()]`, graine fixe = `hash(date)` appliquée à `rng.seed` **et** `seed()` global dans `reinitialiser()`
   (sinon graine aléatoire `randomize()`). `Run.graine_du_jour(date) -> int` publique et testée (déterministe).
8. **Fourmi mécanique** (`fourmi.tres`) : ennemi rapide et fragile — nom « Fourmi mécanique », pv 5, dégâts 1, cadence 1.5,
   portée 0.5, vitesse 3.6, rayon 0.18, butin 0. En renfort : V3 12, V5 20 (si la vague n'a pas de cuirassés, sinon ne rien
   changer). `VagueDef` ne gère qu'un renfort : n'en ajoute pas un second.

## Hors périmètre
Aucune UI (`game/ui/`), pas d'`events.gd`, pas de `project.godot`, pas d'`assets/`. Ne touche pas aux PV/nombres des vagues
(Claude rééquilibre au banc ensuite).

## Critère de fin
`./scripts/tests.sh` au vert avec au moins : garde (un allié loin de l'horloge sans cible reste immobile ; avec garde 1.0
il avance), 3 plateaux valides (chemins raccordés), `graine_du_jour` stable, prix de rotation, `choisir_depart`.
