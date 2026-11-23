# T01 — Plateau, pièces, rotation et propagation d'énergie (logique pure)
**Pour** : Codex · **Étape roadmap** : 1 · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Coder le cœur du puzzle : une grille de sol, des pièces posées dessus (horloge, engrenages, ateliers) dont les **ports**
tournent avec la pièce, et le calcul des pièces **alimentées** depuis l'horloge. Logique pure, sans nœud ni visuel.

## Fichiers autorisés
- game/board/piece_def.gd (créer) · game/board/plateau.gd (créer) · game/board/energie.gd (créer)
- data/tuiles/horloge.tres · engrenage_droit.tres · engrenage_coude.tres · engrenage_t.tres · engrenage_croix.tres · atelier_soldats.tres (créer)
- tests/test_plateau.gd · tests/test_energie.gd (créer)

## À lire avant
AGENTS.md · tests/run_tests.gd · tests/test_socle.gd (format des tests)

## Contrat
**Ports** = masque de bits, sens horaire : `N=1, E=2, S=4, O=8`. Rotation `r` ∈ 0..3, par quart de tour horaire :
`((ports << r) | (ports >> (4 - r))) & 15`. Directions : N = `Vector2i(0,-1)`, E = `(1,0)`, S = `(0,1)`, O = `(-1,0)`.

`piece_def.gd` — `class_name PieceDef extends Resource`
- `enum Type { HORLOGE, ENGRENAGE, ATELIER }`
- `@export var id: StringName` · `@export var nom: String` · `@export var type: Type`
- `@export_flags("N", "E", "S", "O") var ports: int` (en rotation 0) · `@export var transmet: bool = true`
- `static func tourner_ports(ports: int, rotation: int) -> int`

`plateau.gd` — `class_name Plateau extends RefCounted`
- `enum Sol { HERBE, CHEMIN }` : HERBE = constructible ; CHEMIN = réservé aux ennemis (non constructible).
- `signal modifie` (émis après chaque changement réussi). **Pas d'accès à l'autoload Events.**
- `func ajouter_sol(coord: Vector2i, sol: Sol) -> void` (écrase si la case existe déjà)
- `func a_sol(coord: Vector2i) -> bool` · `func sol_de(coord: Vector2i) -> int` (-1 si pas de sol)
- `func poser(coord: Vector2i, def: PieceDef, rotation: int = 0) -> bool` : false si pas de sol, sol CHEMIN ou case occupée.
- `func tourner(coord: Vector2i) -> bool` : +1 quart de tour horaire ; false si case vide.
- `func piece_de(coord: Vector2i) -> PieceDef` (null si vide) · `func rotation_de(coord: Vector2i) -> int`
- `func ports_de(coord: Vector2i) -> int` (ports effectifs après rotation ; 0 si vide)
- `func coords_pieces() -> Array[Vector2i]`

`energie.gd` — `class_name Energie extends RefCounted`
- `static func calculer(plateau: Plateau) -> Dictionary` → `{ Vector2i: profondeur(int) }` des pièces alimentées.
  Parcours en largeur (BFS) depuis **chaque** HORLOGE (profondeur 0). A et B voisins sont **connectés** seulement si
  A a un port vers B **et** B a un port vers A. Une pièce avec `transmet = false` (atelier) est alimentée mais ne propage pas.
  Profondeur = distance minimale en pièces. Aucune horloge → dictionnaire vide.

**Données** (`.tres`, `id` = nom du fichier sans extension) : horloge (ports 15) · engrenage_droit (N+S = 5) ·
engrenage_coude (N+E = 3) · engrenage_t (N+E+O = 11) · engrenage_croix (15) · atelier_soldats (ATELIER, ports S = 4, transmet false).

## Hors périmètre
Pas de visuel, de nœud, de souris, d'Events, d'ennemis, de chemin des ennemis, de retrait de pièce, de coût ni de cadence.

## Critère de fin
`./scripts/tests.sh` au vert, avec au minimum ces tests :
1. rotation : coude (3) r=1 → 6 ; r=4 ≡ r=0 ; croix invariante.
2. `poser` refuse : hors sol, sur CHEMIN, case occupée ; accepte sur HERBE ; `modifie` émis seulement en cas de succès.
3. chaîne horloge → droit → atelier (port tourné vers l'engrenage) : atelier alimenté, profondeurs 0/1/2.
4. engrenage mal orienté → non alimenté ; après `tourner` → alimenté.
5. port unilatéral (A vers B, mais pas B vers A) → pas de connexion.
6. l'atelier ne transmet pas : horloge → atelier → engrenage ⇒ l'engrenage n'est pas alimenté.
7. boucle de 4 croix → terminaison et profondeurs minimales ; sans horloge → vide.
8. chaque `.tres` de data/tuiles/ se charge, est un PieceDef et son `id` = nom du fichier.
9. 30×30 croix + 1 horloge : `calculer` < 50 ms (mesure avec `Time.get_ticks_usec`).
