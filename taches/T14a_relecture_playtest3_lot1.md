# T14a — Relecture du lot 1 « après playtest 3 » (chemins, tourelles, Pont, Générateur)

**Mode : relire** (aucune modification). Tu es le relecteur ; le producteur est Claude (règle : le relecteur n'est
jamais le producteur). Réponds en français, 400 mots maximum, par ordre de gravité : **bug certain** → **risque** →
**remarque**. Pour chaque point : fichier:ligne, scénario concret qui casse, correctif proposé en une phrase.

## Ce qui a changé (lis `git diff HEAD -- game data tests` et seulement ces fichiers)
- `game/swarm/swarm_sim.gd` : `_tracer_couloirs`, `_contenir`, `_voie_libre`, `sortie_atelier`, `relief` — les unités
  au sol restent sur la route (marge), ne poursuivent en ligne droite que si le segment reste sur la route, les jouets
  nés dans l'herbe rejoignent la route de case libre en case libre, et montent sur le tablier d'un Pont.
- `game/workshops/production.gd` : `_sortie` utilise `sim.sortie_atelier`.
- `game/swarm/nuee_visuel.gd` : hauteur des unités = `sim.relief`.
- `game/board/decoupe_tourelle.gd` (nouveau) + `game/board/plateau_visuel.gd` : la tête d'une tourelle pivote seule
  (`_separer_tete`, `_sur_tir`), le Pont est tourné dans le sens de la route (`_amenager_pont`), écriteau « Plein ».
- `game/board/energie.gd` (réécrit), `game/board/plateau.gd` (ordre de pose, pièce unique),
  `game/board/piece_def.gd` (Légendaire, `portee_generateur`, `cout_energie`, `unique`),
  `game/workshops/placement.gd` (`_donne_bonus`), `game/board/plateau_noeud.gd` (surcharge), `data/tuiles/generateur.tres`.

## Questions précises
1. `_contenir` : une unité peut-elle rester coincée (aller-retour sans fin contre une marge, entrée du plateau,
   case de l'horloge, cul-de-sac) ? Les ennemis volants et le boss (rayon 0,9) sont-ils bien traités ?
2. `_voie_libre` + pistes : un jouet au corps à corps peut-il ne plus jamais atteindre un ennemi à portée de vue ?
3. `Energie.analyser` : cas de deux réseaux qui se touchent (générateur relié à l'horloge par un Pont, générateur posé
   après ses bâtiments, bâtiment à la fois à portée de l'horloge et du générateur). L'ordre de pose survit-il à
   `Plateau.dupliquer`, à une reprise puis repose, à une rotation ?
4. Coût : `Energie.analyser` est appelé par le panneau de pièce à chaque affichage ; `_contenir` et `_voie_libre`
   tournent à chaque pas pour chaque unité. Vois-tu un coût qui casserait « 300 contre 300 à 60 images/s » ?
5. Tests manquants les plus utiles (3 au maximum).

## Fichiers autorisés
Aucun (lecture seule). Sortie : `taches/revues/T14a_relecture_playtest3_lot1.md`.
