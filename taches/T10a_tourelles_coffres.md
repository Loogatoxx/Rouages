# T10a — Tourelles de loot rare et coffres
**Pour** : Codex · **Étape roadmap** : 10 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Idée phare de Carlos : les tourelles reviennent comme **loot rare**. Après les vagues 3, 6 et 9, le draft est remplacé
par un **coffre** : 3 tourelles tirées au sort, chacune avec une rareté (commune, rare, épique). Une tourelle se pose sur
l'herbe comme un atelier, doit être **alimentée** par la chaîne d'engrenages et tire seule sur les ennemis à portée.

## Fichiers autorisés
- game/board/piece_def.gd · game/core/regles.gd · game/core/run.gd · game/core/partie.gd
- game/swarm/swarm_sim.gd (ajout d'une méthode, aucune règle existante modifiée)
- game/workshops/tourelles.gd (créer)
- game/board/plateau_visuel.gd (silhouette des tourelles) · game/ui/hud.gd et game/ui/hud.tscn (cartes du coffre)
- game/ui/info_survol.gd (afficher portée/dégâts d'une tourelle)
- data/tuiles/tourelle_canon.tres, tourelle_carillon.tres, tourelle_mortier.tres (créer) · data/regles.tres
- traductions/textes.csv (ajout de lignes uniquement) · tests/test_tourelles.gd (créer)

## À lire avant
AGENTS.md · les fichiers ci-dessus · game/board/energie.gd · game/workshops/production.gd · game/draft/draft.gd ·
data/tuiles/atelier_billes.tres

## Contrat
- `PieceDef` : `enum Type { HORLOGE, ENGRENAGE, ATELIER, TOURELLE }` (ajout **en fin**), `enum Rarete { COMMUNE, RARE, EPIQUE }`,
  `@export var rarete`, `@export var portee_tir: float`, `degats_tir: float`, `cadence_tir: float` (tirs/s), `zone_tir: float`
  (0 = une seule cible ; > 0 = tous les ennemis dans ce rayon autour de la cible).
- `SwarmSim.blesser_zone(centre: Vector2, portee: float, degats: float, zone: float) -> bool` : cible l'ennemi le plus proche
  de `centre` à moins de `portee` (balayage linéaire, ≤ 400 unités) ; sinon `false`. Applique les dégâts (à la cible, ou à
  tous dans `zone` autour d'elle), met `touches = 0.12`, émet `tir(centre, cible)`, renvoie `true`. Les morts sont retirées
  par le prochain `avancer` (même chemin que d'habitude, donc butin et `unite_morte` inchangés).
- `Tourelles` (RefCounted) : `avancer(dt, plateau, alimentees: Dictionary, sim)` ; une recharge par case ; une tourelle
  alimentée prête tire via `blesser_zone` et ne se recharge (`1 / cadence_tir`) **que si** elle a touché.
  Centre = `Vector2(case) * GrilleMonde.TAILLE_CASE`. `Partie` l'appelle **pendant les vagues seulement**, avant `sim.avancer`.
- `Regles` : `@export var vagues_coffre: Array[int] = [3, 6, 9]`, `@export var coffre: Array[Lot]`.
  `Run.offre_coffre: bool` ; `_tirer_offre()` tire dans `coffre` quand la vague qui vient de finir est dans `vagues_coffre`
  (jamais au tirage initial), sinon dans `pioche`. `relancer_offre` relance dans le même sac.
- Données (ports = 4, `transmet = false`) : canon (commune, portée 5, dégâts 6, cadence 1.0, zone 0) ; carillon (rare,
  portée 3, dégâts 4, cadence 0.8, zone 2) ; mortier (épique, portée 8, dégâts 18, cadence 0.35, zone 1.6).
  Coffre : poids 6 / 3 / 1, quantité 1. Noms et descriptions courts, ton jouet (« Canon à billes », « Carillon », « Mortier à ressort »).
- Visuel : socle bois + fût ; teinte par rareté — commune laiton `#D4A84B`, rare bleu porcelaine `#8FB3D9`, épique miel
  doré `#E8B04A` (StandardMaterial3D, pas d'émission néon). Gris si non alimentée, comme les ateliers.
- HUD : en coffre, titre « Coffre ! » au lieu du titre du draft ; chaque carte affiche la rareté (« Commune », « Rare »,
  « Épique ») et une bordure de la teinte de rareté (StyleBoxFlat dérivé du thème, pas de dégradé). Textes via `tr()` +
  lignes FR/EN/PT dans le CSV.

## Hors périmètre
Pas de changement d'équilibrage des unités ni des vagues, pas de nouveau signal `Events`, pas de `project.godot`.

## Critère de fin
`./scripts/tests.sh` au vert avec test_tourelles : touche à portée / rien hors portée / zone blesse plusieurs /
non alimentée ne tire pas / ne se recharge pas sans cible / offre de coffre après la vague 3 et pas après la 2.
`Godot --headless --path . --quit-after 120` sans erreur.
