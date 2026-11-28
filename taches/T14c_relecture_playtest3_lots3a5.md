# T14c — Relecture des lots 3 à 5 « après playtest 3 » (sans modifier le code)
**Pour** : Codex · **Mode** : relire · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Claude a codé seul les lots 3 (`04f8a07`), 4 (`b0a32bf`) et 5 (`850b3fe`, `e79c0c0`). Relis-les en relecteur exigeant :
bugs de logique, cas limites, régressions, coût en performance. Tu ne modifies **aucun** fichier du jeu.

## Fichiers autorisés
- taches/revues/T14c_relecture_playtest3_lots3a5.md (créer : ton rapport)

## À lire avant
- AGENTS.md, puis `git show 04f8a07 b0a32bf 850b3fe e79c0c0 -- game data` (les diffs)

## Points à vérifier
1. Ralentissement : `SwarmSim._freiner`, `ralentir_zone`, `Nuee.ralentis/freins` (cohérence des tableaux parallèles
   dans `_retirer`, `_vider`, `ajouter`) ; unité étourdie qui ne frappe plus ; boss ; teinte du shader.
2. Coup de carillon : `Partie.sonner_carillon`, `PoseControleur._viser_carillon` (mode visée, Échap, changement de
   phase, clic sur l'interface), bouton du HUD, touche `coup_carillon` dans `Touches.ACTIONS` et `project.godot`.
3. Écrans `game/ui/choix_partie.gd` et `game/ui/choix_chapitre.gd` : focus au clavier, Échap, traduction en direct,
   lancement (`Run.preparer_chapitre`, `Run.preparer_bac_a_sable`), carte verrouillée.
4. `MenuPause.texte_aide` : actions absentes de l'InputMap, `%s` mal comptés.
5. Eau et décors : `Plateau.peut_poser` (Pont sur l'eau, rien sur un décor), `SwarmSim._tracer_couloirs` (cases
   occupées), `Extension` (raccord), `DepartDef.creer_plateau`. Marée : `Partie.entrees_de_la_vague`,
   `PlateauVisuel._montrer_maree` (vague 1, carte à une seule entrée, défi du jour).
6. `PlateauVisuel._teinter` (cache par [matériau, teinte] : fuite ? matériaux partagés modifiés par erreur ?),
   `_poser_objets_etabli`, `_onde` (un nœud et un tween par tir : coût à 4 tourelles × 1,5 tir/s ?).
7. `CameraPlateau._cadrer_plateau` : carte agrandie par des extensions, vue de dessus.

## Contrat du rapport
Liste numérotée : gravité (bloquant / moyen / mineur), fichier:ligne, scénario concret qui casse, correctif proposé
en une ou deux lignes. Puis « Rien à signaler » pour les points vérifiés sans défaut. 500 mots maximum.

## Hors périmètre
Aucune modification de `game/`, `data/`, `tests/`, `scripts/`, `docs/`. Pas de commit.
