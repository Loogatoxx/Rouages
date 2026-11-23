# T02 — Caméra double vue, pose et rotation à la souris, plateau greybox visible
**Pour** : Codex · **Étape roadmap** : 2 · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Rendre le plateau de T01 visible et manipulable. Le joueur choisit une pièce dans une palette provisoire, voit un
fantôme sous la souris, pose (clic gauche), tourne (R / clic droit) et **voit l'énergie passer** : engrenages alimentés
qui tournent, pièces non alimentées grisées. La caméra bascule entre vue de dessus et vue 3D inclinée (Tab).

## Fichiers autorisés
- game/board/grille_monde.gd · game/board/plateau_noeud.gd · game/board/plateau_visuel.gd · game/board/pose_controleur.gd (créer)
- game/camera/camera_plateau.gd (créer) · game/ui/palette_debug.gd · game/ui/palette_debug.tscn (créer)
- game/main.tscn · game/main.gd (modifier) · tests/test_grille_monde.gd (créer)

## À lire avant
AGENTS.md · game/core/events.gd · game/board/plateau.gd · game/board/energie.gd · game/board/piece_def.gd · game/main.tscn

## Contrat
- `grille_monde.gd` — `class_name GrilleMonde` : `const TAILLE_CASE := 2.0` ; `static func vers_monde(c: Vector2i) -> Vector3`
  (= `Vector3(c.x * 2, 0, c.y * 2)`) ; `static func vers_case(p: Vector3) -> Vector2i` (arrondi au plus proche).
- `plateau_noeud.gd` — `Node3D`, possède `var plateau: Plateau` et `var alimentees: Dictionary`. Sur `plateau.modifie` :
  recalcule `Energie.calculer`, puis émet `Events.plateau_modifie` et `Events.energie_recalculee(alimentees.keys())`.
  Plateau de départ **provisoire** (sera déplacé dans `data/` à l'étape 5) : 9×9 HERBE centré sur (0,0), horloge en (0,0),
  une colonne CHEMIN en x = 4.
- `plateau_visuel.gd` — `Node3D` qui **lit** `plateau_noeud` (ne modifie jamais le plateau) et reconstruit l'affichage sur
  `Events.plateau_modifie` / `energie_recalculee`. Greybox en primitives : dalle 2×0,2×2 par case de sol ; horloge = cylindre haut ;
  engrenage = cylindre plat + **une petite dent (boîte) par port effectif**, pour que les ports se lisent d'un coup d'œil ;
  atelier = boîte + dent de port. Engrenages alimentés : rotation continue autour de Y. Pièces non alimentées : couleur désaturée.
- **Matériaux** : `func materiau(nom: String) -> Material` charge `res://assets/materials/<nom>.tres` s'il existe, sinon crée un
  `StandardMaterial3D` de secours. Noms et couleurs de secours : `herbe` #A9C98B · `pierre_creme` #EFE3C8 · `bois_plateau` #B9773E ·
  `bois_clair` #E2BE8C · `laiton` #D4A84B (métallique 0,8) · `pastel_bleu` #9EC3E6 · `pastel_rose` #F2B5C4 · `pastel_vert` #B8E0B0 · `pastel_jaune` #F5DC8A.
- `pose_controleur.gd` — raycast souris → plan y = 0 → `GrilleMonde.vers_case`. Fantôme semi-transparent de la pièce choisie
  (vert si `poser` serait accepté, rouge sinon). Actions InputMap uniquement : `poser_tuile`, `tourner_tuile` (tourne le fantôme,
  ou la pièce survolée si aucune pièce n'est choisie), `annuler` (désélectionne).
- `camera_plateau.gd` — `Camera3D`. Vue dessus = orthographique, plongée ~80°. Vue 3D = perspective, plongée ~50°.
  `basculer_camera` → transition douce (0,4 s). `camera_*` = déplacement, molette = zoom, avec des bornes.
- `palette_debug` — barre de boutons en bas de l'écran : un bouton par `.tres` de `data/tuiles/` sauf l'horloge.
  Provisoire (remplacée par le draft à l'étape 5).
- `main.tscn` : garde le décor existant, ajoute PlateauNoeud (avec PlateauVisuel et PoseControleur), la caméra et la palette.

## Hors périmètre
Pas d'ennemis, pas de vagues, pas de draft, pas de coût. Ne modifie pas `Plateau`, `Energie` ni `PieceDef`
(s'il manque quelque chose : dis-le). N'utilise aucun fichier de `assets/` à part les `.tres` de matériaux, s'ils existent.

## Critère de fin
- `./scripts/tests.sh` au vert, avec `test_grille_monde.gd` (aller-retour vers_monde/vers_case, arrondi d'un point proche d'un bord).
- `Godot --headless --path . --quit-after 60` se lance sans erreur de script.
- Décris en 5 lignes comment tester à la main (Carlos lancera le jeu).
