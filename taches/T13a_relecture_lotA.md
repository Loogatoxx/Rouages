# T13a — Relecture du lot A du playtest 2 (sans modifier le code)
**Pour** : Codex · **Étape roadmap** : Après playtest 2, lot A · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Claude a codé seul le lot A (commit `08ca566`). Relis-le comme un relecteur exigeant : bugs de logique, cas limites,
régressions, coût en performance. Tu ne modifies **aucun** fichier du jeu : tu écris seulement ton rapport.

## Fichiers autorisés
- taches/revues/T13a_relecture_lotA.md (créer : ton rapport)

## À lire avant
- AGENTS.md, puis `git show 08ca566 -- game scripts` (le diff complet du lot)
- game/swarm/swarm_sim.gd, game/workshops/production.gd, game/core/partie.gd, game/core/graphismes.gd

## Points à vérifier
1. `SwarmSim` : `origines`/`effectifs` toujours cohérents avec `lieux` (ajout, `_retirer`, `vider`) ; `_tracer_pistes`
   et `_cases_utiles` (carte en S, Fourche à deux entrées, culs-de-sac après une extension, ennemi hors chemin) ;
   la règle « ne pas dépasser le poste sauf pour revenir vers l'horloge » peut-elle faire osciller un jouet ?
2. `Production` : sortie un par un, plafond individuel, progression plafonnée à 1, atelier repris.
3. `Partie` : jouets vidés à la fin de vague, rien ne tourne en construction ; effet sur `Tourelles` et le HUD.
4. `Graphismes` : application aux nœuds ajoutés plus tard, méta d'origine, 15 images/s hors focus, aucune écriture
   de `reglages.cfg` sauf action du joueur.
5. `Plateau.ports_de` (horloge) : effet sur `Energie`, l'aperçu de pose et le visuel.

## Contrat du rapport
Liste numérotée : gravité (bloquant / moyen / mineur), fichier:ligne, scénario concret qui casse, correctif proposé
en une ou deux lignes. Puis « Rien à signaler » pour les points vérifiés sans défaut. 400 mots maximum.

## Hors périmètre
Aucune modification de `game/`, `data/`, `tests/`, `scripts/`, `docs/`. Pas de commit.

## Critère de fin
Le rapport `taches/revues/T13a_relecture_lotA.md` existe.
