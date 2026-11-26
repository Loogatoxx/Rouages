# T05b — Extensions de terrain : plus de place, un front de plus
**Pour** : Codex · **Étape roadmap** : 5 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Nouveau type de lot dans le draft : un morceau de sol 3×3 à accoler au bord du plateau. Son segment de CHEMIN se raccorde au
réseau existant et **ouvre une entrée de scarabées de plus**. En échange, la pose rapporte un bonus de pièces : c'est le
dilemme risque/récompense de la run. Une extension se prend dans la réserve et se pose et s'oriente comme une pièce, en CONSTRUCTION.

## Fichiers autorisés
- game/board/extension_def.gd · game/board/extension.gd · data/extensions/sentier.tres · data/extensions/carrefour.tres ·
  tests/test_extensions.gd (créer)
- game/board/plateau.gd · game/board/plateau_visuel.gd · game/board/pose_controleur.gd · data/regles.tres ·
  game/camera/camera_plateau.gd · game/main.tscn · game/swarm/swarm_sim.gd · tests/test_swarm_sim.gd (modifier)

## À lire avant
AGENTS.md · taches/T05a_draft_reserve.md (déjà livrée) · les fichiers autorisés qui existent · game/swarm/champ_flux.gd ·
game/core/lot.gd · game/core/reserve.gd · game/core/depart_def.gd

## Contrat
- `ExtensionDef` (Resource) : `id`, `nom`, `description`, `taille: int` (3), `chemins: Array[Vector2i]` (cases locales de 0 à
  taille-1, en rotation 0), `bonus: Array[Lot]`. Le bonus est reçu **à la pose**, pas au draft : sinon on prendrait le bonus sans le risque.
- `Plateau` : ajoute `ajouter_sols(sols: Dictionary) -> void` (Vector2i → Sol, **un seul** `modifie` si quelque chose change)
  et `dupliquer() -> Plateau` (copie indépendante des sols, des pièces et des rotations).
- `Extension` (RefCounted, fonctions statiques, logique pure) :
  - `cases(def, centre: Vector2i, rotation: int) -> Dictionary` : Vector2i monde → Sol. Un quart de tour horaire envoie la case
    locale (x, y) sur (taille-1-y, x). Case monde = `centre + locale - Vector2i(taille/2, taille/2)`.
  - `est_valide(plateau, def, centre, rotation) -> bool` : vrai seulement si (1) aucune case n'a déjà du sol ; (2) sur une copie
    étendue, toutes les nouvelles cases CHEMIN figurent dans `ChampFlux.calculer` (elles sont raccordées) ; (3) `ChampFlux.entrees`
    y compte **strictement plus** d'entrées qu'avant. Une extension qui prolonge une entrée sans en ajouter est donc refusée.
  - `appliquer(plateau, def, centre, rotation) -> bool` : si valide, `ajouter_sols` puis vrai ; sinon rien, et faux.
- Données (ids `extension_sentier` et `extension_carrefour`, pour ne jamais croiser un id de tuile) :
  `sentier` = chemin droit [(1,0),(1,1),(1,2)], bonus atelier_soldats ×1 ; `carrefour` = T [(0,1),(1,1),(2,1),(1,2)],
  bonus atelier_soldats ×1 + engrenage_droit ×2. Descriptions courtes qui annoncent « +1 entrée de scarabées » et le bonus.
  Pioche (`regles.tres`) : sentier ×1 (poids 1,5, vague_min 2) et carrefour ×1 (poids 1, vague_min 3).
- `PoseControleur` : si `_choix is ExtensionDef`, le fantôme montre les 9 cases (herbe et chemin teintés : vert si `est_valide`,
  rouge sinon, recalculé seulement quand la case ou la rotation change). `tourner_tuile` le tourne. `poser_tuile` →
  `Extension.appliquer`, puis `Run.reserve.retirer(id)` et `Run.reserve.ajouter_lots(def.bonus)`.
- `PlateauVisuel` : construit le sol des nouvelles cases ; ajoute `creer_extension(def, rotation, teinte) -> Node3D` pour le fantôme ;
  pose un petit repère pastel (poteau `pastel_rose`) sur chaque case de `ChampFlux.entrees`, mis à jour sur `plateau_modifie`.
- Caméra : bornes de déplacement ±24 m (au lieu de ±9). `main.tscn` : table greybox de 56 × 56 m.
- `SwarmSim` : à un embranchement du chemin (case qui a plusieurs voisines plus loin de l'horloge), les **alliés se répartissent**
  au lieu de tous prendre la première branche (sinon le nouveau front d'une extension reste sans défense : vu au banc d'équilibrage).
  Chaque allié reçoit à sa création un entier aléatoire `choix` (tableau parallèle, conservé par `_retirer`) et prend la branche
  `choix % nb_branches` (branches dans l'ordre de `VOISINS`, précalculées dans `configurer`). Les ennemis ne changent pas.

## Hors périmètre
Extensions d'autres tailles, retrait ou déplacement d'une extension, nouveaux ennemis, nouveau signal dans Events.

## Critère de fin
`./scripts/tests.sh` au vert, dont `tests/test_extensions.gd`, sur le plateau de `data/depart.tres` :
1. `cases` : sentier, centre (6,2), rotation 1 → CHEMIN en (5,2), (6,2), (7,2), plus 6 cases d'herbe.
2. Valide : sentier (6,2) rotation 1 → entrées [(4,-4), (4,4), (7,2)] après `appliquer` ; carrefour (4,-6) rotation 0 →
   entrées [(3,-6), (4,4), (5,-6)].
3. Refusé : chevauchement (sentier centre (3,0)) ; non raccordé (sentier (6,2) rotation 0) ; sans nouvelle entrée
   (sentier (4,-6) rotation 0). Dans ces trois cas, `appliquer` renvoie faux et n'émet pas `modifie`.
4. Un `appliquer` valide émet `modifie` une seule fois ; modifier une copie de `dupliquer` ne change pas l'original.
5. Les deux `.tres` se chargent (taille 3, chemins dans le carré) et figurent dans la pioche.
6. `test_swarm_sim.gd` : 100 alliés posés sur l'embranchement (4,0) du plateau de départ, sans ennemi ; après 3 s simulées,
   entre 35 % et 65 % sont partis vers le nord. Les tests existants (dont la performance) restent verts.
Plus : `Godot --headless --path . --quit-after 60` sans erreur, et 5 lignes de test manuel pour Carlos.
