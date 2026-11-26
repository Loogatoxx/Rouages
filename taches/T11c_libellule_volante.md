# T11c — Ennemi volant « libellule mécanique » (playtest 1 : PT-37, benchmark D3)
**Pour** : Codex · **Étape roadmap** : Après playtest 1 · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Le jeu récompense le spam d'ateliers de soldats. Contre-jeu (Kingdom Rush : les volants ignorent les casernes) :
une **libellule volante** que les jouets **au corps à corps** (portée < 1 m, ex. soldat) ne peuvent ni cibler ni bloquer.
Seuls les jouets à distance (lance-bille) et les tourelles l'abattent. Elle arrive en plus des ennemis habituels dès la V6.

## Fichiers autorisés
- `game/swarm/unite_def.gd` (ajouter `@export var volant: bool = false`) · `game/swarm/swarm_sim.gd`
- `game/waves/vague_def.gd` (ajouter `@export var volants: UniteDef` et `@export var nombre_volants: int = 0`)
- `game/waves/directeur_vagues.gd` (intégrer les volants aux apparitions, à `total()` et `restants()`)
- `data/unites/libellule.tres` (créer : camp ennemi, `volant = true`, pv 9, degats 2, cadence 1, portee 0.6,
  vitesse 2.6, rayon 0.3, butin 1, nom « Libellule mécanique »)
- `data/vagues/vague_06.tres` à `vague_10.tres` (volants = libellule ; nombre_volants 6, 8, 10, 12, 16)
- `game/swarm/nuee_visuel.gd` (la libellule vole : même rendu MultiMesh que la fourmi, teinte bleu-vert `#5FA8A0`,
  hauteur +0,9 m, léger battement vertical sinusoïdal)
- `tests/test_volants.gd` (créer)

## À lire avant
`AGENTS.md`, les fichiers autorisés, `docs/architecture.md` § « Unités et ateliers ».

## Contrat
- Un allié dont `portee < 1.0` **ignore** les ennemis `volant` (ni cible, ni blocage, ni poursuite) ; un allié à distance
  (`portee >= 1.0`) les cible normalement. Les volants suivent le même champ de flux et frappent l'horloge à l'arrivée.
- Une libellule n'attaque pas les jouets (elle survole) : elle va droit à l'horloge.
- `SwarmSim.blesser_zone` (tourelles) touche les volants comme les autres.
- Le directeur répartit les volants **régulièrement** dans la vague (comme les renforts), sur les entrées en alternance ;
  `total()` et `restants()` les comptent ; `est_terminee` attend aussi leur mort.

## Hors périmètre
Pas de nouveau signal, ne touche ni `run.gd` ni `hud.gd` ni `regles.tres` ni `traductions/`. Pas de modèle 3D.

## Critère de fin
`./scripts/tests.sh` vert avec `tests/test_volants.gd` : un soldat ne blesse pas une libellule qui passe à côté ; un
lance-bille l'abat ; une tourelle (`blesser_zone`) la touche ; le directeur de la V6 annonce `total()` = scarabées +
renforts + volants ; la libellule ne combat pas les jouets. Godot sans erreur de script (`--headless --quit-after 60`).
