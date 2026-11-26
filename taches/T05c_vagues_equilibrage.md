# T05c — 10 vagues, remontage et équilibrage mesuré
**Pour** : Claude (production) · Codex en relecture (`relire gpt-6-luna low`) · **Étape roadmap** : 5

## Objectif
Donner à la run une vraie courbe de difficulté sur 10 vagues (environ 15 min), mesurée au banc plutôt que devinée, et
supprimer la spirale de défaite.

## Fichiers autorisés
- data/vagues/vague_01.tres … vague_10.tres (01 à 03 réécrites, 04 à 10 créées) · data/regles.tres (liste des 10 vagues)
- data/extensions/sentier.tres · carrefour.tres (bonus) · game/core/partie.gd (remontage) · game/core/events.gd (doc de `tuile_choisie`)
- game/swarm/swarm_sim.gd (répartition indépendante d'un embranchement à l'autre)
- tests/test_vagues.gd (10 vagues, débit croissant) · test_draft.gd (10 vagues) · test_extensions.gd (bonus) ·
  test_swarm_sim.gd (embranchements successifs) · scripts/banc_equilibrage.gd (outil, créé)

## Contrat
- **Remontage** : en CONSTRUCTION, `Partie` fait avancer `production` et `sim` (jamais le directeur). Les jouets se fabriquent et
  rejoignent leur poste entre les vagues, dans la limite du plafond. Pourquoi : sans ça, une vague ratée vidait l'armée de la
  suivante, et le banc montrait des runs perdues dès la vague 3 pour un joueur pourtant correct.
- **Courbe** (débit = `10 × multiplicateur / intervalle` PV/s ; durée d'apparition = `nombre × intervalle`) :

| Vague | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| nombre | 14 | 44 | 70 | 97 | 123 | 140 | 150 | 160 | 190 | 229 |
| intervalle (s) | 1,25 | 0,5 | 0,37 | 0,3 | 0,26 | 0,25 | 0,25 | 0,25 | 0,23 | 0,21 |
| × PV | 1,0 | 1,0 | 1,1 | 1,2 | 1,35 | 1,5 | 1,7 | 1,85 | 2,05 | 2,4 |
| débit (PV/s) | 8 | 20 | 30 | 40 | 52 | 60 | 68 | 74 | 89 | 114 |

- Repère : un atelier à plein stock (15 jouets) encaisse environ 30 PV/s. Mesures finales sur le vrai code
  (`scripts/banc_equilibrage.gd`, 3 graines, remontage de 20 s) : « fort » (2→7 ateliers) 0 PV ; « moyen » (1→5) 0 à 4 PV ;
  « faible » (1→4) 0 PV ou chute en vague 8 ; « moyen + sentier en vague 4 avec son bonus » 0, 0 ou chute en vague 10.
  La simulation est chaotique près du point de rupture : comparer des réglages sur plusieurs graines, jamais une seule.
- **Répartition aux embranchements** : la branche d'un jouet = hachage de (`choix`, case de l'embranchement). Avec `choix % n`
  (fiche T05b), deux embranchements successifs étaient corrélés : 16 jouets d'un côté, 57 de l'autre (test ajouté).
- **Bonus des extensions** : sentier = atelier ×1 + engrenage droit ×2 ; carrefour = atelier ×2 + engrenage droit ×2.

## Critère de fin
`./scripts/tests.sh` au vert ; `Godot --headless --path . --quit-after 60` sans erreur ; Carlos joue une run de 10 vagues.
