# T11f — Craft enrichi : démonter et assembler (playtest 1 : PT-39)
**Pour** : Codex · **Étape roadmap** : Après playtest 1 · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Carlos : « base du craft bien pensée, à enrichir avec plus de features ». Entre les vagues (phase CONSTRUCTION seulement),
le joueur peut **démonter** une pièce de sa réserve contre quelques ressorts, et **assembler** des pièces de sa réserve
selon des recettes simples (une pièce en trop devient utile, sans alourdir l'interface).

## Fichiers autorisés
`game/core/recette_def.gd` (créer, `class_name RecetteDef extends Resource`), `data/recettes/*.tres` (créer),
`game/core/regles.gd`, `data/regles.tres`, `game/core/run.gd`, `game/ui/reserve_ui.gd`, `game/ui/reserve_ui.tscn`,
`traductions/textes.csv` (ajouter FR/EN/PT), `tests/test_craft.gd` (créer).

## À lire avant
`AGENTS.md`, `game/core/reserve.gd`, `game/core/lot.gd`, les fichiers autorisés, `game/ui/menu_titre.gd`
(`vignette_de`, `preparer_bouton`, `caler_hauteur`).

## Contrat
- `RecetteDef` : `@export var id: StringName`, `@export var entrees: Array[Lot]` (objet + quantité), `@export var sortie: Lot`.
- Recettes (`Regles.recettes`) : 3 engrenages droits → 1 engrenage en croix ; 2 engrenages coudés → 1 engrenage en T ;
  2 ateliers de soldats → 1 atelier de lance-billes.
- `Regles` : `demontage_engrenage = 1`, `demontage_atelier = 6`, `demontage_tourelle = 8` (ressorts rendus).
- `Run.peut_assembler(recette) -> bool`, `Run.assembler(recette) -> bool` (CONSTRUCTION, retire les entrées, ajoute la
  sortie, `Sons.jouer(&"pose")` n'est PAS appelé ici : Run reste sans son) ; `Run.valeur_demontage(objet) -> int` ;
  `Run.demonter(id) -> bool` (CONSTRUCTION, retire 1, `gagner(valeur)`, refuse les extensions et l'horloge).
- `reserve_ui` : **clic droit** sur un bouton de la réserve en construction = démonter un exemplaire (infobulle :
  « Clic droit : démonter (+%d ressorts) ») ; un bouton texte « Assembler » à droite de la réserve (visible en
  construction, actif si au moins une recette est possible) ouvre une petite fiche papier (variation « Fiche ») listant
  chaque recette : vignettes des entrées ×N → vignette de la sortie, bouton « Assembler » désactivé si impossible.
  Vignettes via `Interface.vignette_de` ; textes sur papier en variation `CarteTexte` (encre foncée).

## Hors périmètre
Pas de nouveau signal, ne touche ni `hud.gd` ni `events.gd` ni `project.godot`. Pas de nouvelle icône (texte seulement).

## Critère de fin
`./scripts/tests.sh` vert avec `tests/test_craft.gd` : assemblage qui consomme et produit ; refus sans les entrées ou hors
construction ; démontage qui rend les ressorts et refuse une extension. Godot sans erreur (`--headless --quit-after 60`).
