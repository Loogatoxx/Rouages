# T11d — Améliorer bâtiments et engrenages + panneau contextuel (playtest 1 : PT-50, PT-51 partie main)
**Pour** : Codex · **Étape roadmap** : Après playtest 1 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Carlos : « tous les bâtiments et engrenages améliorables, 3 niveaux minimum, jusqu'à 10 si le design le justifie ;
niveaux intermédiaires enrichis à la main (accessoires, matériaux, pièces) ». Règle Claude : engrenages 3 niveaux,
ateliers et tourelles 5 niveaux. Coût = `prix_amelioration × niveau actuel` (en ressorts). Un **clic gauche sur une pièce
posée** (rien en main) ouvre un **panneau contextuel** près d'elle (menus radiaux de Kingdom Rush) : Améliorer · Tourner
· Reprendre, chacun avec icône et prix. Le clic droit garde la rotation rapide. Reprendre une pièce lui fait perdre ses
niveaux (le placement compte).

## Fichiers autorisés
`game/board/piece_def.gd`, `game/board/plateau.gd`, `game/core/run.gd`, `game/core/regles.gd`, `data/regles.tres`,
`data/tuiles/*.tres` (sauf horloge), `game/workshops/placement.gd`, `game/board/pose_controleur.gd`,
`game/board/plateau_visuel.gd`, `game/ui/info_survol.gd`, `game/ui/panneau_piece.gd` (créer),
`traductions/textes.csv` (ajouter FR/EN/PT), `tests/test_ameliorations.gd` (créer).

## À lire avant
`AGENTS.md`, `docs/architecture.md` (§ « Après playtest 1 », lots 3 et 5), `docs/benchmark_td.md` (D5), les fichiers autorisés.

## Contrat
- `PieceDef` : `@export var niveau_max: int = 1` ; `@export var prix_amelioration: int = 0`. Données : engrenages
  `niveau_max = 3`, `prix_amelioration = 4` ; ateliers 5 / 10 ; tourelles 5 / 12.
- `Plateau` : niveaux par case (1 par défaut), `niveau_de(c) -> int`, `ameliorer(c) -> bool` (refus au max ou sans pièce,
  émet `modifie`), remis à 1 par `poser`/`retirer`, copiés par `dupliquer`.
- `Regles` (groupe « Améliorations ») : `gain_niveau_atelier = 0.2` (cadence par niveau au-delà du 1er),
  `plafond_niveau_atelier = 3`, `gain_niveau_tourelle = 0.25` (dégâts), `gain_niveau_engrenage = 0.5` (multiplie les
  `bonus_voisins_*`).
- `Placement` applique ces gains dans `cadence_atelier`, `plafond_atelier` (+ plafond propre de l'atelier),
  `degats_tourelle`, `cadence_tourelle` et le bonus des engrenages voisins ; `effets()` ajoute « Niveau %d / %d ».
- `Run.prix_amelioration(plateau, case) -> int` ; `Run.ameliorer_piece(plateau, case) -> bool` (CONSTRUCTION ou VAGUE,
  paie, refuse horloge/max/solde) ; refus faute de ressorts → `Events.message_joueur`.
- `panneau_piece.gd` (Control, thème `res://game/ui/theme_rouages.tres`, variation « Fiche ») : nom + niveau, 3 boutons
  avec icônes `assets/ui/icones/ameliorer.png`, `tourner.png`, `deplacer.png` et prix (icône `ressort.png`), désactivés si
  impossible ; se ferme sur Échap, clic ailleurs, changement de phase ou action faite. Créé par `pose_controleur.gd` dans un
  `CanvasLayer` (couche 6) ; positionné près de la pièce (`Camera3D.unproject_position`), gardé dans l'écran.
- `plateau_visuel.gd` (ajouts faits main, sans Hyper3D) : niveaux 2+ = petites billes de laiton (une par niveau au-delà du
  1er) en rangée sur l'avant du socle ; niveau 3 = anneau de laiton (TorusMesh) autour du socle ; niveau 5 = fanion doré
  sur un mât fin. Recalcul à chaque `plateau_modifie`.

## Hors périmètre
Pas de nouveau signal, ne touche pas `hud.gd`, `events.gd`, `project.godot`, ni aux fichiers de la libellule.

## Critère de fin
`./scripts/tests.sh` vert avec `tests/test_ameliorations.gd` : prix croissant ; refus au niveau max (engrenage 3,
atelier 5) ; reprise = niveau perdu ; cadence/plafond d'atelier et dégâts de tourelle qui montent ; bonus d'un
démultiplicateur niveau 3 = ×2 ; `dupliquer` copie les niveaux. Godot sans erreur de script (`--headless --quit-after 60`).
