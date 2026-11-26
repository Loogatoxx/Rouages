# T10c — Progression méta : l'Établi de l'inventeur
**Pour** : Codex · **Étape roadmap** : 10 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Donner envie de relancer une run (pilier « arbre de compétences méta »). Chaque run rapporte des **engrenages d'or**,
dépensés entre les runs dans l'**Établi** (menu titre) pour des améliorations permanentes. Le défi du jour **ignore** ces
bonus (même départ pour tous).

## Fichiers autorisés
- game/core/progression.gd (créer : RefCounted, méthodes statiques, sauvegarde `user://progression.cfg`)
- game/core/amelioration_def.gd (créer, Resource) · data/ameliorations/*.tres (créer) · game/core/regles.gd · data/regles.tres
- game/core/run.gd (appliquer les bonus dans `reinitialiser`, créditer les engrenages en fin de run)
- game/ui/etabli.gd et game/ui/etabli.tscn (créer) · game/ui/menu_titre.gd/.tscn (bouton « Établi » + compteur)
- game/ui/hud.gd (ligne « +N engrenages d'or » dans le bilan de fin) · traductions/textes.csv (ajout de lignes)
- game/workshops/production.gd (appliquer `Run.bonus_cadence` à la cadence uniquement)
- tests/test_progression.gd (créer)

## À lire avant
AGENTS.md · les fichiers ci-dessus · game/ui/options.gd (modèle de panneau) · game/ui/theme_rouages.tres

## Contrat
- `AmeliorationDef` : `id`, `nom`, `description`, `niveaux_max: int`, `prix: Array[int]` (par niveau), `effet: StringName`,
  `valeur_par_niveau: float`. Effets : `pv_horloge` (+5/niv, 3 niv), `ressorts_depart` (+8/niv, 3 niv), `choix_draft`
  (+1 carte, 1 niv), `cadence_ateliers` (+8 %/niv, 3 niv), `rente` (+2 ressorts/fin de vague, 2 niv), `relance_offerte`
  (première relance de chaque draft gratuite, 1 niv). Prix croissants (ex. 3, 6, 10).
- `Progression` : `engrenages() -> int`, `niveau(id) -> int`, `acheter(def) -> bool`, `bonus(effet) -> float`,
  `gagner(n)`, `reinitialiser_tout()` (pour les tests), `chemin` surchargeable pour les tests.
- Gains de fin de run : 1 engrenage par vague terminée + 5 si victoire ; `Run.engrenages_gagnes`. Rien en défi du jour.
- `Run.reinitialiser` applique les bonus via des valeurs effectives (`pv_max`, `choix_par_draft` effectif, etc.) **sans
  modifier `regles.tres` en mémoire**. Les ateliers lisent un multiplicateur `Run.bonus_cadence` (1.0 par défaut) dans production.gd.
- Établi : panneau du thème (comme Options), une ligne par amélioration (nom, description, pastilles de niveau, prix,
  bouton Acheter grisé si trop cher), compteur d'engrenages d'or en haut. Textes via `tr()` + CSV FR/EN/PT.

## Hors périmètre
Pas d'arbre graphique, pas de héros, pas de `project.godot`, pas de plateau_visuel ni nuee_visuel (autre tâche en cours).

## Critère de fin
`./scripts/tests.sh` au vert avec test_progression (achat, sauvegarde/relecture, plafond de niveau, bonus appliqués au
départ, défi du jour sans bonus ni gain). `Godot --headless --path . --quit-after 120` sans erreur.
