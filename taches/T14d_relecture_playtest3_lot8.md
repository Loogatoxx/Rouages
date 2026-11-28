# T14d — Relecture du lot 8 « après playtest 3 » (sans modifier le code)
**Pour** : Codex · **Mode** : relire · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Claude a codé seul le lot 8 (`ebb2274`, `538bb4b`, `db823e9`, `3dac72f`) pendant l'absence de Carlos. Relis-le en
relecteur exigeant : bugs de logique, cas limites, régressions, coût en performance. Tu ne modifies **aucun** fichier
du jeu.

## Fichiers autorisés
- taches/revues/T14d_relecture_playtest3_lot8.md (créer : ton rapport)

## À lire avant
- AGENTS.md, puis `git show ebb2274 538bb4b db823e9 3dac72f -- game data scripts/joueur_auto.gd` (les diffs)

## Points à vérifier
1. `DecoupeTourelle.extraire` / `_separer` / `_lire_surfaces` : tableaux d'indices, surfaces multiples, zone vide,
   `reference` (extractions enchaînées sur le socle), pivot ; régression possible de `decouper` (refactorisé).
2. `PlateauVisuel._detacher_pieces`, `_animer_mobiles`, `PIECES_MOBILES` : cache statique par modèle, nœuds
   « Mobile* » libérés à `_reconstruire`, `_mobiles` qui garde des nœuds libérés, pièce grisée (non alimentée) ;
   `_separer_tete(modele, id, nom_modele)` : palier `_n3` d'une tourelle.
3. `BdChapitre` (`game/ui/bd_chapitre.gd`) : coroutine statique `montrer_si_nouvelle` appelée depuis
   `ChoixChapitre._lancer` et `MenuTitre._lancer_chapitre` (double clic sur « Jouer », Échap, focus, chapitre sans
   BD, `finie` émis deux fois ?) ; `Progression.bd_vue` / `noter_bd_vue`.
4. `scripts/joueur_auto.gd` : `_poser_pont`, dernier recours `_poser_engrenage` (boucle infinie possible dans
   `_poser_reserve` ?).
5. `AmbiancePlateau._oiseau_mecanique`, `CosmetiquesPlateau.actualiser` (nœuds libérés pendant l'itération,
   `queue_free` puis recréation dans la même image, lumières OmniLight × 4).
6. Sons : `SwarmSim.frappes_melee` (remis à zéro ? jamais lu en headless ?), `PlateauVisuel._sur_tir`.
7. Données : `data/campagne/chapitre_0[1-4].tres` (bd, bulles), `data/extensions/epingle.tres` (le chemin forme bien
   un U sans raccourci), `data/ameliorations/{nappe,guirlande,lanternes}.tres`, `data/departs/rail.tres`.

## Contrat du rapport
Liste numérotée : gravité (bloquant / moyen / mineur), fichier:ligne, scénario concret qui casse, correctif proposé
en une ou deux lignes. Puis « Rien à signaler » pour les points vérifiés sans défaut. 500 mots maximum.

## Hors périmètre
Aucune modification de `game/`, `data/`, `tests/`, `scripts/`, `docs/`. Pas de commit.
