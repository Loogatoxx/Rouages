# Hyper3D — demande groupée n°1 à Carlos (PT-52)

**Pourquoi c'est toi** : la génération Hyper3D passe par le site (connexion web, l'API demande le plan supérieur) et chaque
crédit est définitif. Règles : image de référence validée par toi avant toute génération ; 4 modèles maximum par élément,
réservés aux gros paliers (R1, R2) ; comptes dans `assets/CREDITS_HYPER3D.md`.

**État (2026-11-27)** : ✅ lot 1 validé par Carlos, généré par Claude sur le site (0,5 crédit par modèle), allégé
(`scripts/alleger_modele.gd`) et intégré aux nuées (`assets/final/<nom>/<nom>_h3d.res`). Ancien état : prompts prêts. **Images de référence** : à produire par Gemini dès que son quota revient (épuisé le
2026-11-26 vers 23 h 50, deux essais refusés). Dès qu'elles sont dans `art_refs/hyper3d/lot1/`, tu n'as qu'à :
valider (ou refuser) chaque image → lancer Image-to-3D sur le site → déposer le `.glb` dans `assets/final/<nom>/`.

## Lot 1 — palier 1 des unités (7 crédits, il en reste 43)
| # | Nom (dossier) | Prompt Rodin (anglais) | Cible | Crédit |
|---|---|---|---|---|
| 1 | `scarabee` | handcrafted wind-up toy beetle, polished amber and copper domed shell, brass legs, clockwork, soft pastel toy style, clean low-poly | ≤ 6 000 tris, origine au centre du ventre, regard vers −Z | 1 |
| 2 | `libellule` | clockwork toy dragonfly, openwork brass wings with mint stained-glass panes, turquoise body, toy model style | ≤ 6 000 tris, ailes séparées si possible (battement) | 1 |
| 3 | `soldat` | wind-up tin toy soldier, sky-blue uniform, brass winding key on the back, chunky readable silhouette from above | ≤ 6 000 tris | 1 |
| 4 | `scarabee_cuirasse` | big armored clockwork beetle, riveted bronze plates, heavy toy, warm brass details | ≤ 6 000 tris | 1 |
| 5 | `fourmi` | slender clockwork ant toy, copper body, thin brass legs, fast-looking | ≤ 4 000 tris | 1 |
| 6 | `grand_scarabee` | majestic clockwork beetle boss toy, engraved golden shell, large brass winding key on the back | ≤ 12 000 tris | 1 |
| 7 | `lance_bille` | small mint toy artillery figure with a brass marble tube, wind-up toy style | ≤ 6 000 tris | 1 |

**Animations** (PT-53) : demander à Hyper3D le rig et la marche pour 1, 3, 5 et l'envol pour 2 ; si l'animation générée
est inexploitable (pattes qui glissent, rig cassé), repli justifié : cycle de marche par calcul (blocage noté ici).

## Lots suivants (après le retour du lot 1)
- **Lot 2 — bâtiments palier 1** (5 crédits) : atelier de soldats, atelier de lance-billes, 3 tourelles (le kit Blender
  actuel sert de base d'image).
- **Lot 3 — paliers 2 à 4** (15 crédits) : ateliers et tourelles aux niveaux 2, 3 et 5 (les niveaux intermédiaires
  gardent les ornements faits main).
- **Lot 4 — horloge (3) et décor maître (4)** : paliers de l'horloge, boîte à musique, moulin, chantier d'extension.
- Réserve d'essais : 9 crédits. Engrenages : modelés par calcul (dents qui doivent s'engrener : les maths battent la génération).
