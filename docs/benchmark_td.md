# Benchmark tower defense → décisions pour Rouages (PT-34)

Sources et détails : `art_refs/benchmark_td_sources.md` (recherche web par Gemini, 17 sources : GDC *Plants vs. Zombies*,
postmortems *Kingdom Rush* et *Defense Grid*, wikis *Bloons TD 6*, *Rogue Tower*, *Isle of Arrows*, *Legion TD 2*,
*Thronefall*, *Ballionaire*). Ce document garde seulement **ce qu'on en fait**, et pourquoi.

## Constat sur Rouages (playtest 1)
Le jeu récompense le spam : poser le plus d'ateliers de soldats possible gagne, peu importe où et comment.
Les jeux de référence évitent ça avec trois leviers : **des cases qui ne se valent pas** (Kingdom Rush, Rogue Tower),
**des synergies de voisinage** (Isle of Arrows, Bloons TD 6) et **des ennemis qui contrent une stratégie unique**
(Kingdom Rush, Bloons, Legion TD 2).

## Décisions (une ligne = une tâche de la roadmap)
| # | Principe (source) | Décision pour Rouages | Tâche |
|---|---|---|---|
| D1 | Cases différenciées par le terrain (Rogue Tower : altitude) et chemin comme levier (Kingdom Rush : coudes) | **Placement par rapport à la route** : tourelle en bord de route = +25 % dégâts ; atelier en bord de route = ses jouets naissent sur la route (front immédiat) ; atelier à 3 cases ou plus de la route = « arrière-garde » +20 % cadence (à l'abri, mais loin). Un choix front / arrière, affiché en aperçu de pose. | PT-36 |
| D2 | Synergies d'adjacence (Isle of Arrows : taverne qui renforce les archers voisins ; Bloons : village) | **Engrenages à identité** : droit = *démultiplicateur* (+15 % cadence aux ateliers voisins alimentés, cumul 2) ; T = *répartiteur* (+4 jouets au plafond des ateliers voisins) ; croix = *moyeu* (fait tourner les tourelles voisines 20 % plus vite) ; coude = le moins cher, pur routage. Fin de l'incohérence « une case de plus pour rien ». | PT-35 |
| D3 | Le contre-jeu punit la mono-stratégie (Kingdom Rush : volants qui ignorent les casernes ; Bloons : Camo/Lead) | **Libellule mécanique** (volante) : les soldats au corps à corps ne peuvent pas la toucher ; seuls lance-billes et tourelles l'abattent. Arrive en renfort à partir de la V6. Les ateliers identiques collés entre eux s'encombrent (−10 % cadence par voisin identique). | PT-37 |
| D4 | La rareté oriente des combos, la chance est encadrée (Ballionaire, Legion TD 2) | **Chance** : chaque point multiplie le poids des cartes rares ×1,25 et épiques ×1,5 dans les coffres ; +1 chance par vague tenue sans dégât, +2 avec le porte-bonheur de la boutique, +1 par niveau du trèfle de l'Établi. Icône trèfle dans le HUD. | PT-38 |
| D5 | Branches de spécialisation qui engagent la partie (Bloons TD 6) | **Améliorations** : 3 niveaux par pièce (niv. 2 et 3 achetés en ressorts), puis jusqu'à 10 pour les ateliers et tourelles avec des gains plus petits ; panneau contextuel au clic (améliorer · tourner · reprendre), comme les menus radiaux de Kingdom Rush. | PT-50 |
| D6 | Méta horizontale, pas de grind chiffré (Game Developer ; Thronefall : perks et mutators) | **Engrenages d'or plus exigeants** (gain réduit en début de run, coûts rehaussés), et les nouveaux déblocages sont des *options* (trèfle, nouvelles pièces) plutôt que de purs bonus chiffrés. | PT-33, PT-63 |
| D7 | Alterner tension et respiration, une mécanique nouvelle à la fois (GDC Plants vs. Zombies) | Vraie pause entre les vagues (fait, PT-30) ; chaque nouveauté (libellule, chance, améliorations) est introduite par une bulle du tutoriel la première fois. | PT-30, PT-63 |
| D8 | Vagues annoncées pour préparer une composition (Legion TD 2) | Aperçu de la vague suivante pendant la construction : icônes des ennemis (scarabée, fourmi, cuirassé, libellule, boss). | PT-17 (suite) |

## Ce qu'on ne reprend pas (et pourquoi)
- **Mazing libre** : notre route est imposée et posée par extensions ; on garde la lisibilité (Defense Grid montre que le
  mazing total produit une solution unique partout).
- **Matrice de résistances chiffrées (Legion TD 2)** : trop opaque pour un jeu tous âges ; un contre simple et visible
  (volant / blindé) suffit.
