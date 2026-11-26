# T08a — Ressorts (monnaie), boutique, 2e ennemi, 2e atelier, extensions tentantes, vitesse x2
**Pour** : Codex · **Étape roadmap** : 7b (rush jouabilité) · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Donner une économie simple à la run (les **ressorts** récompensent les vagues et achètent des pièces), de la variété
(un scarabée cuirassé lent et costaud, un atelier de lance-billes à distance) et des extensions qui valent le coup.
Logique et données uniquement : l'interface viendra dans une autre fiche (ne crée aucune UI).

## Fichiers autorisés
- game/core/run.gd, game/core/regles.gd, game/core/lot.gd, game/core/partie.gd
- game/swarm/unite_def.gd, game/swarm/swarm_sim.gd (seulement le signal `unite_morte`, voir contrat)
- game/waves/vague_def.gd, game/waves/directeur_vagues.gd
- game/board/extension_def.gd, game/board/pose_controleur.gd
- data/regles.tres, data/vagues/vague_04.tres … vague_10.tres, data/extensions/sentier.tres, data/extensions/carrefour.tres,
  data/unites/scarabee.tres (ajout du butin)
- data/unites/scarabee_cuirasse.tres, data/unites/lance_bille.tres, data/tuiles/atelier_billes.tres (créer)
- tests/test_economie.gd (créer), tests/test_vagues.gd, tests/test_swarm_sim.gd (adapter si le signal change)

## À lire avant
AGENTS.md · game/core/events.gd (signaux `ressorts_changes`, `ennemi_casse`, `pause_demandee` déjà ajoutés par Claude) ·
game/core/run.gd · game/core/partie.gd · game/waves/directeur_vagues.gd · tests/test_draft.gd · data/regles.tres

## Contrat
- `Lot` : `@export var prix: int = 0` (prix en ressorts quand le lot est vendu en boutique).
- `UniteDef` : `@export var nom: String` et `@export var butin: int = 0` (ressorts gagnés quand l'ennemi est cassé).
- `VagueDef` : `@export var renfort: UniteDef` (peut être null) et `@export var nombre_renforts: int = 0`. Le directeur fait
  apparaître `nombre + nombre_renforts` unités ; les renforts sont **répartis régulièrement** dans la vague (pas tous à la fin),
  avec le même `multiplicateur_pv`. `est_terminee` compte le total.
- `SwarmSim.unite_morte` devient `signal unite_morte(camp: int, position: Vector2, def: UniteDef)`.
- `ExtensionDef` : `@export var ressorts: int = 0` (gagnés à la pose).
- `Regles` (+ valeurs dans `regles.tres`) : `ressorts_depart` 0 · `recompense_vague` 6 · `recompense_par_vague` 2 ·
  `bonus_sans_degat` 5 · `prix_relance` 5 · `prix_reparation` 10 · `pv_reparation` 5 · `boutique: Array[Lot]` =
  engrenage droit ×2 (prix 4), engrenage coude ×1 (3), engrenage croix ×1 (6), atelier de soldats ×1 (15),
  atelier de lance-billes ×1 (22, `vague_min` 3).
- `Run` (autoload) — nouveaux membres :
  - `var ressorts: int`, `var ennemis_casses: int`, `var ressorts_gagnes: int`, `var derniere_recompense: int`,
    `var vitesse: float = 1.0`.
  - `gagner(n: int) -> void` (ajoute, cumule `ressorts_gagnes`, émet `Events.ressorts_changes`) ·
    `depenser(n: int) -> bool` (refuse si solde insuffisant ; émet le signal si OK).
  - `acheter(i: int) -> bool` : seulement en CONSTRUCTION, refuse si `vague_min > vague_actuelle + 1` ou pas assez de ressorts ;
    ajoute le lot à la réserve.
  - `relancer_offre() -> bool` : seulement en DRAFT ; paie `prix_relance` et retire un nouveau tirage ; ré-émet
    `Events.phase_changee(Phase.DRAFT)` pour que l'UI réaffiche les lots.
  - `reparer_horloge() -> bool` : seulement en CONSTRUCTION, si PV < max ; paie et rend `pv_reparation` PV (plafonné) ;
    émet `ressorts_changes` (l'UI relira `pv_horloge`) ; **n'émet pas** `horloge_touchee`.
  - `casser_ennemi(def: UniteDef, position: Vector2) -> void` : `ennemis_casses += 1`, `gagner(def.butin)`,
    `Events.ennemi_casse.emit(position)`.
  - `terminer_vague()` : avant `vague_terminee`, calcule `derniere_recompense = recompense_vague + recompense_par_vague ×
    (vague_actuelle − 1) + (bonus_sans_degat si aucun PV perdu pendant cette vague)` et l'ajoute.
  - `basculer_vitesse() -> void` : alterne `vitesse` entre 1.0 et `regles.multiplicateur_acceleration`.
  - `reinitialiser()` remet tout à zéro (ressorts = `ressorts_depart`, stats, vitesse 1) et émet `ressorts_changes`.
- `Partie` : `dt *= Run.vitesse` (supprimer la lecture de `Input` « accelerer » maintenue) ; branche `sim.unite_morte` →
  `Run.casser_ennemi` pour le camp ENNEMI uniquement.
- `PoseControleur` : à la pose d'une extension, `Run.gagner(extension.ressorts)`. Action `annuler` : si une pièce est
  sélectionnée → désélection + `get_viewport().set_input_as_handled()` ; sinon → `Events.pause_demandee.emit()`, **quelle
  que soit la phase** (déplacer le test de phase en conséquence).
- Données : `scarabee.tres` butin 1, nom « Scarabée ». `scarabee_cuirasse.tres` : nom « Scarabée cuirassé », ennemi,
  pv 45, dégâts 5, cadence 0.8, portée 0.7, vitesse 1.2, rayon 0.4, butin 4. `lance_bille.tres` : nom « Lance-bille », allié,
  pv 8, dégâts 7, cadence 0.7, portée 2.4, vitesse 2.0, rayon 0.25. `atelier_billes.tres` : id `atelier_billes`,
  « Atelier de lance-billes », description courte (tire de loin, idéal contre les cuirassés), type ATELIER, ports 4,
  transmet false, cadence 0.3. Pioche : lot atelier de lance-billes ×1, poids 2, `vague_min` 3.
  Renforts cuirassés : V4 3 · V5 5 · V6 8 · V7 10 · V8 14 · V9 18 · V10 25 (Claude rééquilibrera au banc).
  Extensions : sentier `ressorts` 15 ; carrefour : bonus = 1 atelier de lance-billes + 2 engrenages droits, `ressorts` 25.
  Mettre à jour leurs descriptions (« À la pose : +1 entrée, … et +15 ressorts. Plus d'entrées = plus de butin. »).

## Hors périmètre
Aucune UI, aucun visuel, aucun son. Ne pas toucher `game/ui/`, `nuee_visuel.gd`, `plateau_visuel.gd`, `events.gd`, `scripts/`.

## Critère de fin
`./scripts/tests.sh` au vert (les 43 tests existants + nouveaux) avec au moins : récompense de fin de vague (avec et sans
dégât), achat refusé sans ressorts / accepté avec, `vague_min` respecté, relance payante, réparation plafonnée, butin à la mort
d'un ennemi (via `casser_ennemi`), renforts répartis et comptés dans `est_terminee`, `basculer_vitesse`.
