# T14b — Relecture des lots 1 et 2 « après playtest 3 » (sans modifier le code)
**Pour** : Codex · **Mode** : relire · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Claude a codé seul les lots 1 (`3560763`) et 2 (dernier commit de `main`). Relis-les en relecteur exigeant : bugs de
logique, cas limites, régressions, coût en performance. Tu ne modifies **aucun** fichier du jeu.

## Fichiers autorisés
- taches/revues/T14b_relecture_playtest3_lot2.md (créer : ton rapport)

## À lire avant
- AGENTS.md, puis `git show 3560763 -- game` et `git show HEAD -- game` (les deux diffs)
- game/swarm/swarm_sim.gd, game/board/energie.gd, game/board/plateau.gd, game/workshops/production.gd,
  game/waves/directeur_vagues.gd, game/board/plateau_noeud.gd, game/board/pose_controleur.gd

## Points à vérifier
1. `SwarmSim._contenir`, `_voie_libre`, `sortie_atelier` : une unité peut-elle rester coincée (marge, entrée du
   plateau, case de l'horloge, cul-de-sac, Pont) ? Boss (rayon 0,9) et volants bien traités ?
2. Postes de garde : `_tracer_postes`, `_route_proche`, `_compter_passages`, `_vers_poste`, bloc « poste » de
   `_decider`. Jouet dont le poste disparaît (atelier repris en pleine vague, route changée par une extension,
   poste sur une case devenue Pont) ; escouade qui n'attaque jamais un ennemi pourtant à portée ; tireurs immobiles.
3. `Energie.analyser` : ordre de pose après `dupliquer`, reprise puis repose, rotation ; générateur relié à
   l'Horloge par un Pont ; bâtiment à la fois sur l'Horloge pleine et à portée d'un générateur ; `dents` = -1.
4. `PlateauNoeud._actualiser` : messages « Plein » répétés ou manqués ; recalcul quand `Run.dents` change ;
   minuteur qui survit à un changement de scène.
5. `Production.unite_de_niveau` : cache par [modèle, niveau] alors que `DirecteurVagues` duplique les modèles ;
   effet sur `NueeVisuel` (lots par `id`), sur `Partie._piece_reprise` et `SwarmSim.rappeler`.
6. `DirecteurVagues` : rythme par paquets (durée totale, dernier paquet incomplet, plusieurs entrées), boss.
7. `PoseControleur` : mode « choisir un poste » (Échap, changement de phase, clic hors plateau, pièce en main).
8. Coût : `_contenir`, `_voie_libre`, `_vers_poste` par unité et par pas ; `Energie.analyser` appelé par le
   panneau de pièce à chaque affichage. Risque pour « 300 contre 300 à 60 images/s » ?

## Contrat du rapport
Liste numérotée : gravité (bloquant / moyen / mineur), fichier:ligne, scénario concret qui casse, correctif proposé
en une ou deux lignes. Puis « Rien à signaler » pour les points vérifiés sans défaut. 500 mots maximum.

## Hors périmètre
Aucune modification de `game/`, `data/`, `tests/`, `scripts/`, `docs/`. Pas de commit.
