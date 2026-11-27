# Crédits Hyper3D — journal

Budget initial : **44 crédits**. Toute génération exige une image validée par Carlos ET une fiche qui l'autorise.

| Date | Asset | Crédits | Fiche | Restant |
|---|---|---|---|---|
| — | — | 0 | — | **44** |
| 2026-11-26 | horloge | 1 | T07b | **43** |
| 2026-11-27 | lot 2 (3 bâtiments : atelier de soldats, atelier de lance-billes, canon), validé par Carlos | 0,5 par modèle | DEMANDE_LOT2 | voir le compteur du site |
| 2026-11-27 | lot 1 (7 unités), validé par Carlos, généré par Claude sur le site (Gen-2.5, High) | 0,5 par modèle (géométrie + texture + export compris) | DEMANDE_LOT1 | voir le compteur du site |

## Plan (PT-52, 2026-11-26)
Lot 1 unités (7) · lot 2 bâtiments palier 1 (5) · lot 3 paliers 2-4 des 5 bâtiments (15) · lot 4 horloge (3) + décor
maître (4) · réserve d'essais (9) = 43. Détail et prompts : `art_refs/hyper3d/DEMANDE_LOT1.md`. Aucun crédit dépensé
depuis l'horloge.


## Lot 1 — 2026-11-27 (images validées par Carlos)
- **Coût réel** : 0,5 crédit par modèle sur le site (compte Creator : 30 crédits/mois + 24,5 permanents au départ).
  Le budget « 43 crédits » de l'ancien plan compte donc pour ~86 modèles.
- **Allègement** (exception R1 b) : Hyper3D livre ~500 000 triangles et des textures 2K ; `scripts/alleger_modele.gd`
  simplifie à ~4 000 triangles (meshoptimizer) et réduit les textures à 512 px → `assets/final/<nom>/<nom>_h3d.res`.
  Les archives d'origine restent hors dépôt (40-50 Mo chacune).
- **Récupération** : Chrome n'enregistre pas l'archive fabriquée par la page ; elle est envoyée par la page à un récepteur
  local (127.0.0.1) au moment de sa création.
