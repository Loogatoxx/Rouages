# T05a — Draft d'un lot parmi 3, réserve de pièces, machine à états de la run
**Pour** : Codex · **Étape roadmap** : 5 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
La run devient un roguelike : DRAFT (1 lot parmi 3, tiré d'une pioche pondérée) → CONSTRUCTION (on ne pose que ce qu'on
possède) → VAGUE → DRAFT… La palette illimitée disparaît. Le plateau et la réserve de départ passent dans `data/`.
Les extensions de terrain viendront en T05b : `Lot.objet` doit donc pouvoir être autre chose qu'une `PieceDef`.

## Fichiers autorisés
- game/core/lot.gd · game/core/depart_def.gd · game/core/reserve.gd · game/draft/draft.gd · data/depart.tres (créer)
- game/ui/reserve_ui.gd · game/ui/reserve_ui.tscn · tests/test_draft.gd (créer)
- game/core/regles.gd · data/regles.tres · game/core/run.gd · game/core/partie.gd · game/board/piece_def.gd (modifier)
- game/board/plateau.gd · game/board/plateau_noeud.gd · game/board/plateau_visuel.gd · game/board/pose_controleur.gd (modifier)
- game/ui/hud.gd · game/ui/hud.tscn · game/main.tscn · data/tuiles/*.tres (modifier : ajouter `description`)
- game/ui/palette_debug.gd · game/ui/palette_debug.tscn (supprimer)

## À lire avant
AGENTS.md · les fichiers autorisés qui existent déjà · game/core/events.gd · game/swarm/champ_flux.gd (`entrees`)

## Contrat
- `Lot` (Resource) : `objet: Resource` (une PieceDef, plus tard une ExtensionDef : les deux ont `id`, `nom`, `description`),
  `quantite: int = 1`, `poids: float = 1.0`, `vague_min: int = 1`. Il sert à la pioche, à la réserve de départ et aux bonus (T05b).
- `PieceDef` : ajoute `@export var description: String`, avec une ligne courte et douce dans chaque `.tres` de tuile.
- `DepartDef` (Resource) : `terrain: Rect2i`, `chemins: Array[Vector2i]`, `horloge: Vector2i`, `reserve: Array[Lot]`, et
  `func creer_plateau() -> Plateau` (herbe partout dans `terrain`, CHEMIN sur `chemins`, horloge posée).
  `data/depart.tres` reproduit **exactement** le plateau actuel de `plateau_noeud.gd`, avec les entrées (4,-4) et (4,4).
  Réserve de départ : atelier_soldats ×1, engrenage_droit ×2, engrenage_coude ×1.
- `Plateau` : ajoute `coords_sols() -> Array[Vector2i]`. `PlateauNoeud` obtient son plateau par `Run.depart.creer_plateau()`
  (la constante `TERRAIN` disparaît). `PlateauVisuel` construit le sol depuis `coords_sols()` et n'ajoute que les cases pas encore construites.
- `Reserve` (RefCounted) : `signal modifiee` · `ajouter(objet: Resource, n: int = 1)` · `ajouter_lots(lots: Array[Lot])` ·
  `retirer(id: StringName) -> bool` (faux si la quantité vaut 0) · `quantite(id) -> int` · `trouver(id) -> Resource` ·
  `ids() -> Array[StringName]` (triés, quantité > 0). La clé est `objet.id`.
- `Draft` (RefCounted, fonctions statiques) : `tirer(lots: Array[Lot], n: int, vague: int, rng: RandomNumberGenerator) -> Array[Lot]`.
  Tirage pondéré **sans remise** parmi les lots où `vague_min <= vague` et `poids > 0`. S'il y a moins de candidats que `n`, il les renvoie tous.
- `Regles` : ajoute `choix_par_draft: int` (3), `pioche: Array[Lot]`, `vagues: Array[VagueDef]` (les 3 vagues actuelles).
  Pioche initiale : atelier ×1 (poids 3) · droit ×3 (3) · coude ×2 (2) · T ×2 (1,5) · croix ×1 (1).
- `Run` : `depart: DepartDef` (data/depart.tres), `reserve: Reserve`, `offre: Array[Lot]`, `rng`. `vagues` et `nb_vagues`
  viennent de `regles.vagues`. `reinitialiser()` est aussi appelé dans `_ready` : vague 0, PV pleins, réserve = `depart.reserve`,
  offre tirée, phase **DRAFT**. `choisir_lot(i: int)` (en DRAFT seulement) : ajoute le lot à la réserve, vide l'offre, passe en CONSTRUCTION.
  `terminer_vague()` (en VAGUE seulement) : émet `vague_terminee`. Après la dernière vague : FIN + `run_terminee(true)`. Sinon :
  nouvelle offre (`vague` = la prochaine) et DRAFT. `Partie` appelle `Run.terminer_vague()` au lieu de gérer la fin elle-même.
- `PoseControleur` : `_choix = Run.reserve.trouver(id)`. Une pose réussie appelle `Run.reserve.retirer(id)`. Quantité 0 ou sortie
  de CONSTRUCTION → `Events.tuile_choisie.emit(&"")`. Tourner une pièce déjà posée reste gratuit.
- `ReserveUI` (barre du bas, remplace la palette) : un bouton « Nom ×n » par id de la réserve, reconstruit sur `modifiee`.
  La sélection passe par `Events.tuile_choisie`. Boutons inactifs hors CONSTRUCTION. Lire `nom` et `description` par `get()`
  (l'infobulle affiche la description).
- `HUD` : en DRAFT, un panneau central « Choisis un lot » avec 3 boutons (« Nom ×n » puis la description) → `Run.choisir_lot(i)`.
  « Vague n / N » affiche la prochaine vague en DRAFT et en CONSTRUCTION. Ton doux, même style bois.

## Hors périmètre
Extensions de terrain (T05b), nouvelles vagues, coûts, défausse ou vente de pièces, nouveau signal dans Events.

## Critère de fin
`./scripts/tests.sh` au vert (les 27 tests actuels + les nouveaux), dont `tests/test_draft.gd` :
1. `tirer` : `n` lots distincts, jamais de `vague_min > vague`, jamais de poids 0, tous les candidats s'il y en a moins que `n`,
   même graine → même tirage ; sur 2 000 tirages d'1 lot entre un poids 3 et un poids 1, le premier sort à 75 % ± 5 %.
2. `Reserve` : ajouter, retirer jusqu'à 0 (puis faux), `ids` triés sans quantité nulle, `modifiee` émis.
3. `data/depart.tres` : horloge en (0,0), entrées [(4,-4), (4,4)], réserve attendue.
4. Machine à états (l'autoload `Run` existe en test) : départ en DRAFT avec 3 lots ; `choisir_lot` → CONSTRUCTION et réserve
   augmentée ; `choisir_lot` hors DRAFT sans effet ; `lancer_vague` → VAGUE ; `terminer_vague` → DRAFT, puis FIN après la
   dernière vague. Terminer par `Run.reinitialiser()`.
Plus : `Godot --headless --path . --quit-after 60` sans erreur, et 5 lignes de test manuel pour Carlos.
