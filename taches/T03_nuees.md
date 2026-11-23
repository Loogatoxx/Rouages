# T03 — Nuées : simulation orientée données, champ de flux, combats, rendu MultiMesh
**Pour** : Codex · **Étape roadmap** : 3 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Faire vivre deux nuées sur le plateau. Les scarabées (ennemis) suivent le chemin jusqu'à l'horloge. Les jouets à
remontoir (alliés) rejoignent le chemin et marchent à leur rencontre. Contact → combat. **300 contre 300 à 60 FPS.**
Pas de physique Godot : des tableaux typés et une grille spatiale. Les ateliers et les vagues viendront à l'étape 4.

## Fichiers autorisés
- game/swarm/unite_def.gd · game/swarm/champ_flux.gd · game/swarm/swarm_sim.gd · game/swarm/nuee_visuel.gd (créer)
- game/swarm/banc_nuees.gd · game/swarm/banc_nuees.tscn (créer : scène de test de performance)
- game/core/materiaux.gd (créer) · game/board/plateau_visuel.gd (modifier : déléguer `materiau()` à `Materiaux`)
- game/board/plateau_noeud.gd (modifier : plateau de départ, voir plus bas)
- data/unites/scarabee.tres · data/unites/soldat_remontoir.tres (créer)
- tests/test_champ_flux.gd · tests/test_swarm_sim.gd (créer)

## À lire avant
AGENTS.md · game/board/plateau.gd · game/board/grille_monde.gd · game/board/plateau_visuel.gd · game/board/plateau_noeud.gd

## Contrat
**Repère** : positions en mètres, `Vector2(x, z)` du monde. Case `c` ↔ centre `Vector2(c.x * 2, c.y * 2)` (cohérent avec GrilleMonde).

`unite_def.gd` — `class_name UniteDef extends Resource` : `enum Camp { ALLIE, ENNEMI }` ; `@export` : `id: StringName`, `camp: Camp`,
`pv: float`, `degats: float`, `cadence: float` (attaques/s), `portee: float` (m), `vitesse: float` (m/s), `rayon: float` (m).
Données : scarabee (ENNEMI, pv 10, degats 2, cadence 1, portee 0,6, vitesse 2, rayon 0,25) ·
soldat_remontoir (ALLIE, pv 14, degats 3, cadence 1,2, portee 0,7, vitesse 2,4, rayon 0,25).

`champ_flux.gd` — `class_name ChampFlux extends RefCounted`, logique pure :
- `static func calculer(plateau: Plateau) -> Dictionary` → `{ Vector2i: distance(int) }`. BFS multi-source depuis les cases
  des HORLOGES (distance 0), à travers les cases praticables : sol CHEMIN uniquement. Une case absente = inaccessible.
- `static func vers_chemin(plateau: Plateau, distances: Dictionary) -> Dictionary` → `{ Vector2i: Vector2i }`. Pour chaque case de
  sol, la case praticable la plus proche (BFS multi-source sur tout le sol). Sert aux alliés nés hors du chemin.

`swarm_sim.gd` — `class_name SwarmSim extends RefCounted`, logique pure, **aucun nœud** :
- `signal ennemi_arrive(degats: float)` (un scarabée atteint l'horloge : il est retiré) · `signal unite_morte(camp: int, position: Vector2)`
- `const CAPACITE := 400` par camp. Stockage **structure de tableaux** par camp (`PackedVector2Array` positions,
  `PackedFloat32Array` pv et recharge, etc.). Retrait par **échange avec le dernier** (swap-remove), jamais `remove_at` au milieu.
- `func configurer(plateau: Plateau) -> void` : (re)calcule le champ de flux et `vers_chemin`. À rappeler quand le plateau change.
- `func ajouter(def: UniteDef, position: Vector2) -> bool` (false si capacité pleine) · `func avancer(dt: float) -> void`
- `func nombre(camp: int) -> int` · `func positions(camp: int) -> PackedVector2Array` · `func caps(camp: int) -> PackedFloat32Array` (angle de marche, en radians).
- **Ennemi** : vise le centre de la case voisine de distance plus petite. Si sa case est hors champ, il vise la case du champ la plus proche.
  À moins de 1 m du centre d'une horloge : émet `ennemi_arrive(degats)` et disparaît.
- **Allié** : si un ennemi est à moins de 6 m, il va vers le plus proche. Sinon, s'il est hors chemin, il va vers `vers_chemin`.
  Sinon, il remonte le flux (case voisine de distance plus grande), donc vers les entrées.
- **Combat** : si un adversaire est à portée, l'unité s'arrête et frappe le plus proche (`degats` toutes les `1 / cadence` s).
  PV ≤ 0 → `unite_morte` puis retrait.
- **Séparation** : une légère répulsion entre unités du même camp à moins de `2 × rayon`, pour éviter les empilements (effet de masse).
- **Grille spatiale** : cellules de 2 m, reconstruite à chaque `avancer`, et seules les 9 cellules voisines sont interrogées.
  Jamais de double boucle sur toutes les unités.

`materiaux.gd` — `class_name Materiaux` : `static func obtenir(nom: String) -> Material`, avec cache. Reprend tel quel le chargement
`assets/materials/<nom>.tres` + couleurs de secours actuellement dans `plateau_visuel.gd`, qui l'appelle désormais.

`nuee_visuel.gd` — `Node3D` qui **lit** une `SwarmSim` (`var sim: SwarmSim`) et met à jour **un `MultiMeshInstance3D` par camp**
dans `_process` (`visible_instance_count` = nombre d'unités, orientation = cap). Greybox : scarabée = sphère aplatie `laiton` ;
jouet = petite boîte, avec une **couleur pastel par instance** (`use_colors`, couleur choisie par index parmi les 4 pastels).

`plateau_noeud.gd` : le chemin doit rejoindre l'horloge. La colonne CHEMIN x = 4 reste, et on ajoute une rangée CHEMIN y = 0
de x = 1 à 3. Les entrées sont (4, -4) et (4, 4).

`banc_nuees.tscn` (scène autonome) : un plateau en serpentin d'environ 20 cases de chemin, horloge au bout. Elle maintient 300 scarabées
et 300 soldats en réapparaissant (ennemis aux entrées, alliés près du chemin). Caméra de dessus, `Label` en haut à gauche avec FPS,
nombres d'unités et temps de `avancer` en ms.

## Hors périmètre
Pas d'ateliers producteurs, pas de vagues, pas de PV de l'horloge, pas de loot, pas d'Events (signaux locaux seulement).
Pas d'intégration de la sim dans `main.tscn` (étape 4). Ne modifie ni `Plateau` ni `Energie`.

## Critère de fin
`./scripts/tests.sh` au vert, avec au minimum :
1. champ de flux sur un chemin en L : distances correctes, une case HERBE est absente, une case CHEMIN isolée est absente.
2. un scarabée seul atteint l'horloge en un temps cohérent avec sa vitesse : `ennemi_arrive` émis une seule fois, nombre(ENNEMI) = 0.
3. duel 1 contre 1 au contact : le perdant meurt au bon nombre de coups ; résultat déterministe.
4. 50 scarabées créés au même point : après 120 pas, la distance minimale entre deux d'entre eux est > 0,15 m.
5. swap-remove : on tue des unités au milieu, les comptes et les PV restants restent cohérents.
6. sans ennemi, un allié né sur l'herbe rejoint le chemin puis s'éloigne de l'horloge.
7. performance : 300 contre 300 répartis sur un chemin, 60 appels `avancer(1 / 60)`, moyenne < 6 ms.
Indique la commande pour lancer `banc_nuees.tscn` et le temps moyen mesuré.
