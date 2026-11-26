# T11b — Reprendre et déplacer une pièce posée (playtest 1 : PT-31)
**Pour** : Codex · **Étape roadmap** : Après playtest 1 · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Carlos : « Vague 0 : déplacement totalement gratuit. À partir de la vague 1, un système qui punit les mauvais choix de
placement. » Règle retenue par Claude : **clic gauche sur une pièce posée, sans rien en main = la reprendre** (elle revient
dans la réserve et reste sélectionnée pour être reposée ailleurs). Gratuit avant la vague 1 ; ensuite « déménagement »
payant et **croissant** dans une même pause (3, puis 5, puis 7… ressorts ; compteur remis à zéro au lancement de chaque
vague). Un atelier déjà remonté pendant la pause et déplacé **n'est pas remonté une 2e fois** (sinon on gagnerait des
jouets gratuits en déplaçant). L'horloge ne se reprend jamais.

## Fichiers autorisés
- `game/board/plateau.gd` (ajouter `retirer`) · `game/core/run.gd` · `game/core/regles.gd` · `data/regles.tres`
- `game/board/pose_controleur.gd` · `game/core/partie.gd` · `game/workshops/production.gd` · `game/ui/info_survol.gd`
- `traductions/textes.csv` (ajouter les nouvelles chaînes FR/EN/PT) · `tests/test_deplacement.gd` (créer)

## À lire avant
`AGENTS.md`, `docs/architecture.md` (§ « Après playtest 1 »), les fichiers autorisés, `game/core/events.gd`
(le signal `piece_reprise(case, def)` existe déjà : émets-le, n'en ajoute pas).

## Contrat
- `Plateau.retirer(coord: Vector2i) -> PieceDef` : enlève la pièce (sauf horloge → `null`), efface sa rotation, émet `modifie`.
- `Regles` : `@export var prix_deplacement: int = 3` et `@export var prix_deplacement_pas: int = 2` (valeurs dans `regles.tres`).
- `Run.deplacements_pause: int` (remis à 0 dans `lancer_vague` et `reinitialiser`) ;
  `Run.prix_deplacement: int` (propriété : 0 si `vague_actuelle == 0`, sinon `prix_deplacement + prix_deplacement_pas × deplacements_pause`) ;
  `Run.reprendre_piece(plateau, case) -> bool` : refuse hors CONSTRUCTION/VAGUE, case vide, horloge, solde insuffisant ;
  sinon paie, retire, ajoute la pièce à `reserve` (+1), incrémente le compteur, émet `Events.piece_reprise`.
- `pose_controleur.gd` : `poser_tuile` sans sélection sur une pièce → `Run.reprendre_piece` ; succès → `Sons.jouer(&"pose")`
  et `Events.tuile_choisie.emit(id)` ; refus faute de ressorts → `Events.message_joueur.emit(tr("Déplacer coûte %d ressorts") % prix)`.
- `Production.atelier_repris(case: Vector2i)` : si la case était déjà remontée pendant la pause, le prochain atelier
  nouvellement remonté ne reçoit aucun jouet (un « jeton » consommé) ; `nouvelle_pause()` remet les jetons à 0.
  `partie.gd` branche `Events.piece_reprise` → `production.atelier_repris` pour les ateliers.
- `info_survol.gd` : ligne en plus sur une pièce posée (hors horloge) : « Clic : reprendre (gratuit avant la vague 1) »
  ou « Clic : reprendre (%d ressorts) ».

## Hors périmètre
Pas de nouveau signal, pas de visuel 3D, ne touche pas `project.godot`, `hud.gd`, `events.gd`.

## Critère de fin
`./scripts/tests.sh` vert avec `tests/test_deplacement.gd` : gratuit en vague 0 ; prix 3 puis 5 en vague 1 ; compteur remis
à zéro au lancement ; refus sans ressorts (solde et plateau intacts) ; horloge refusée ; pas de 2e remontage d'un atelier
déplacé (`Production`). Godot sans erreur de script (`--headless --quit-after 60`).
