# T10b — Boss : le Grand Scarabée horloger
**Pour** : Codex · **Étape roadmap** : 10 · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Donner un sommet aux vagues 5 et 10 : un **Grand Scarabée** lent et énorme, très résistant, qui fait mal s'il atteint
l'horloge. Une barre de vie dédiée en haut de l'écran le rend mémorable.

## Fichiers autorisés
- game/waves/vague_def.gd · game/waves/directeur_vagues.gd (un boss optionnel par vague, lâché à mi-vague)
- data/unites/grand_scarabee.tres (créer) · data/vagues/vague_05.tres, vague_10.tres
- game/swarm/swarm_sim.gd (accesseur lecture seule `pv_boss() -> Vector2` : (pv restants, pv max) du premier boss vivant, ou ZERO)
- game/swarm/unite_def.gd (`@export var boss: bool = false`)
- game/swarm/nuee_visuel.gd (le boss réutilise le modèle `scarabee_cuirasse` à l'échelle de son rayon, teinte plus sombre bronze `#7A4A2A`)
- game/ui/hud.gd et game/ui/hud.tscn (barre de boss : ruban + nom + barre de vie, visible seulement si un boss vit)
- traductions/textes.csv (ajout) · tests/test_vagues.gd (ajout d'un test)

## Contrat
- `VagueDef` : `@export var boss: UniteDef` (null par défaut). Le directeur l'ajoute une fois quand la moitié des unités
  principales est lâchée ; `est_terminee` attend aussi sa mort. Le multiplicateur de PV de la vague s'applique au boss.
- Grand Scarabée : pv 600, degats 15, cadence 0.6, portee 1.0, vitesse 0.8, rayon 0.9, butin 25, boss = true, nom « Grand Scarabée ».
- V5 : boss avec multiplicateur 1.0 (PV ×0,5 via une constante `pv_boss_facteur` de VagueDef = 0.5) ; V10 : facteur 1.0.
- HUD : barre qui descend en douceur (Tween 0,2 s), apparaît/disparaît en fondu.

## Critère de fin
`./scripts/tests.sh` au vert (+ test : le boss apparaît une seule fois à mi-vague et la vague n'est finie qu'à sa mort) ;
`Godot --headless --path . --quit-after 120` sans erreur.
