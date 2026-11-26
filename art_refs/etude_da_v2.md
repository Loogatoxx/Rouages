# Étude DA v2 — « Rouages » : Maquette en volume & Interface artisanale

> **Objectif** : Passer d'un rendu « prototype plat + UI générique arrondie » à une **maquette-jouet horlogère en bois poli**, lisible comme un grand tower defense et tactile comme un jeu de plateau européen haut de gamme.

---

## 1. Analyse comparative des jeux de référence

| Référence | Tuiles & volumes (biseaux, flancs, épaisseur) | Lumière & ombres portées | Palette | UI (matières, typo, icônes, anims) | Lisibilité des unités |
|---|---|---|---|---|---|
| **Bad North** | Îlots modulaires découpés en blocs épais, falaises nettes, murets de soutènement, zéro plan nu. | Lumière directionnelle douce + **AO de contact très appuyée** sous les maisons, falaises et escouades. | Sols feutrés (verts sourds, pierre grise, mer profonde) faisant claquer les unités vives. | Quasi invisible, semi-diégétique : drapeaux, marqueurs 3D sur la case, zéro barre lourde. | Silhouettes iconiques (boucliers, piques, arcs), contraste chromatique net, PV = taille de l'escouade. |
| **Dorfromantik** | Hexagones épais à **biseaux doux** et jointure visible façon pièces de bois/carton sur table ; micro-reliefs. | Un soleil principal + ombres douces lumineuses (jamais noires) + brume chaude d'atmosphère. | Pastels picturaux désaturés (sauge, terre cuite, crème, bleu poussiéreux) harmonisés par biome. | Plateau bois + **parchemin/carton mat**, typo humaniste chaleureuse, icônes gravées/tamponnées, pile de tuiles physique. | Éléments lisibles par couleur de toit et forme simple ; marqueurs-fanions posés dans le monde. |
| **Townscaper** | Géométrie organique à arêtes chanfreinées, socles maçonnés, toits courbés, détails contextuels. | Soleil rasant + **ombres longues chaudes** + AO douce dans les recoins : effet « maquette sous lampe de bureau ». | Façades pastels mates sur eau calme ; matériaux peu spéculaires (bois peint / argile). | **UI quasi absente** : pastilles-couleurs discrètes, retour tactile immédiat (*pop* rebondissant à la pose). | Lecture immédiate par volumes massifs et variation de hauteur. |
| **Tiny Glade** | Pierres, murets et toits toujours bombés, biseautés et imparfaits ; herbe en volume et pavés incrustés. | Lumière rasante d'heure dorée, rebond lumineux chaud, **ombres de contact denses** au pied de chaque objet. | Crème, terracotta, bois miel, mousse tendre ; aucune teinte néon ou noire pure. | **Boutons bois sculpté** à dépression physique, icônes trait encre/pyrogravure, typo arrondie de conte, retours bois/clics. | Silhouette et échelle miniature accentuées par le contraste entre l'herbe matte et les pierres claires. |
| **Islanders** | Plateaux en gradins chanfreinés, masses architecturales simples empilées avec épaisseur lisible. | Soleil unique franc, ombres nettes à teinte bleutée/chaude, surfaces presque mates. | Terres ocre et verts aquarelle très calmes ; **toits colorés** servant de code fonctionnel. | HUD minimaliste qui s'efface hors action ; pastilles flottantes contextuelles et cartes épurées. | Hiérarchie couleur : décor calme, bâtiments actifs codés par teinte de toiture. |
| **Mini Motorways** | Routes et bâtiments aux angles adoucis, relief subtil mais séparation stricte sol / réseau. | Éclairage uniforme propre, micro-ombres portées pour détacher les jetons du plan. | **Contraste doux** : fond neutre/pastel calme vs réseaux et pions aux teintes franches et distinctes par teinte (pas seulement valeur). | Cartes vectorielles minimalistes dans les coins, compteurs nets, icônes géométriques pures, animations élastiques. | Lisibilité en vision périphérique grâce à la séparation nette des teintes et formes. |
| **Wilmot's Warehouse** | Tuiles carrées graphiques parfaitement découpées, grilles nettes sans bruit visuel. | Plat graphique mais séparation chirurgicale figure/fond. | Blocs de couleurs francs, spectre limité et codifié par catégorie. | Typo utilitaire nette, icônes ultra-distinctives, l'objet de jeu *est* l'interface. | Reconnaissance instantanée à distance par forme unique + couleur dédiée. |
| **Kingdom Rush** *(lisibilité TD)* | Chemins en relief encadrés de bordures nettes, emplacements bâtissables bien détachés de l'herbe. | Lumière ensoleillée, ombres rondes sous chaque unité pour ancrer la position au sol. | Herbe moyenne, chemin clair très lisible, ennemis sombres/chauds, alliés colorés. | **Bois chanfreiné, parchemin, rubans pliés, clous/laiton**, menu radial contextuel sur la case, icônes épaisses à contour net. | **Proportions exagérées** (têtes, armes, casques), silhouettes immédiatement distinctes en vue plongeante. |
| **Tin Hearts / Toy Tactics / Captain Toad / Thronefall** *(jouet & horlogerie)* | Tranches de plateau assumées (boîte-diorama), biseaux marqués sur chaque pièce en bois tourné, mécanismes visibles (engrenages, clés, ressorts). | Éclairage « lampe d'atelier / fin d'après-midi », spéculaire satiné sur le bois verni et doux sur le laiton brossé. | Noyer/miel chaud, laiton doré, pierre ivoire, jouets peints en pastels francs. | Étiquettes cartonnées, cadrans laiton, jetons bois cliquables, zéro fenêtre plastique moderne. | Figurines-jouets reconnaissables de dessus par un accessoire fort (clé de remontoir, dôme, chapeau, canon). |

---

## 2. Diagnostic des défauts à éliminer

1. **Rien de plat sur le plateau** : un disque posé au sol ou un cube brut casse instantanément l'illusion maquette. Chaque tuile doit avoir une **épaisseur réelle** (flancs de bois/terre), un **biseau visible** captant la lumière rasante, une **fente d'assemblage** entre cases et un **micro-relief** (dessus légèrement bombé, pavés surélevés, touffes sculptées).
2. **Fin du look « AI slop » en UI** : abandonner les rectangles arrondis translucides génériques, les gros boutons uniformes et les emojis système. L'interface doit appartenir à l'**établi de l'horloger** : tranches de bois poli, plaques de laiton riveté, fiches en papier crème, étiquettes découpées et rubans de tissu.
3. **Équilibre décor / action** : sans hiérarchie de saturation (leçon *Bad North* + *Mini Motorways* + *Kingdom Rush*), les nuées se perdent sur le plateau. Le sol reste **mat et feutré** ; les unités et bâtiments actifs prennent des **silhouettes hautes, lisibles de dessus** et des accents colorés propres.

---

## 3. Direction artistique v2 retenue pour « Rouages »

Synthèse directement inspirée du meilleur de *Dorfromantik* (chaleur plateau), *Tiny Glade* (matières tactiles), *Bad North* (AO et lisibilité topographique), *Kingdom Rush* (clarté TD + bois/parchemin/ruban) et nos références verrouillées (`plateau_maquette_v1.jpg`, `inventeur_figurine_v1.jpg`).

### A. Géométrie & proportions du plateau (1 case = 2 m × 2 m)
- **Tuiles de terrain épaisses** : hauteur totale `0,24 m`, empreinte `1,96 m × 1,96 m` (jeu de `4 cm` créant le joint sombre de plateau-maquette entre cases). Flancs en bois/terre chanfreinés, arête supérieure à **biseau de 4 à 6 cm** très lisible en vue 3/4.
- **Herbe (`tuile_herbe`, `tuile_herbe_b`)** : socle bois chaud + terre douce, coussin d'herbe feutrée légèrement bombé (`+2 cm` au centre), 2 à 4 touffes coniques et micro-fleurs pastel (crème, pêche, bleu ciel) excentrées pour laisser le centre constructible propre.
- **Chemin (`tuile_chemin`)** : socle bois/mortier crème encaissé + **pavés de pierre ivoire en relief** (`+2 à 3,5 cm`) à bords arrondis et joints creusés profonds qui attrapent l'ombre rasante.
- **Pourtour (`bord_plateau`)** : moulure-tranche d'établi en bois poli miel/noyer avec chanfrein supérieur et congé latéral qui encadre la maquette comme un vrai jeu de plateau.
- **Marqueur d'extension (`marqueur_extension`)** : remplace tout disque plat par un **piquet en laiton tourné** planté sur un petit socle bois + **fanion pastel en tissu/bois peint** qui ondule légèrement — visible de loin comme un repère de *Dorfromantik*.
- **Engrenages (`engrenage_droit/coude/t/croix`)** : socle bois chanfreiné avec **rigoles directionnelles incrustées de laiton** indiquant la connectivité, surmonté d'un vrai **rouage denté en volume** (`Rotor`, centré sur l'axe vertical, dents biseautées + bague centrale laiton).
- **Ateliers & Tourelles** : esthétique « jouet en bois tourné + pièces de laiton ». Toits à pans francs (`atelier_soldats` rouge terracotta/corail + clé de remontoir géante ; `atelier_billes` tour vert menthe + réservoir/bille laiton). Les tourelles gardent un socle bois/laiton unifié et un **corps/anneau de rareté** dédié (`Rarete`) afin de lire d'un coup d'œil commune / rare / épique.
- **Unités (≤ 400 tris, lecture de dessus)** : silhouettes chunkys et exagérées (*Kingdom Rush* × *plateau_maquette_v1.jpg*).
  - **Alliés** : jouets pastels (bleu ciel, menthe, corail) coiffés d'une **clé de remontoir en laiton** sur le dos/sommet (code visuel immédiat « allié »).
  - **Ennemis** : insectes mécaniques en **bronze/laiton foncé + carapace ambre/cuivre** bombée et pattes recourbées (code visuel immédiat « nuée ennemie »).

### B. Lumière, ombres et matériaux PBR
- **Lumière chaude de fin d'après-midi** : soleil principal bas (élévation ~32–38°), teinte dorée (`#FFF0D4`), ombres portées longues et douces teintées d'indigo/brun chaud (jamais noires), lumière de remplissage ciel pastel (`#DCE8F5`) + **SSAO / AO de contact marquée** dans Godot.
- **Matières simples et tactiles** (PBR sans bruit réaliste) :
  - **Bois poli miel / noyer** : `#C88A4B` / `#8C562B`, *Roughness* `0,42–0,52`, *Metallic* `0,0`.
  - **Laiton doux brossé** : `#D9AE54`, *Metallic* `0,85`, *Roughness* `0,28–0,34`.
  - **Pierre crème / mortier** : `#EFE4CC` / `#D6C7AA`, *Roughness* `0,78–0,85`.
  - **Herbe feutrée** : `#8EB35B` / `#7DA34E`, *Roughness* `0,88` (mat, zéro brillance plastique).
  - **Pastels jouets** : rouge corail `#D66355`, menthe `#6FB89D`, bleu ciel `#74A8C7`, lavande `#A68FC2`, beurre `#ECD079` (*Roughness* `0,48–0,58`).

### C. Interface originale « Établi d'horloger » (`assets/ui/`)
- **Hiérarchie de matières (5 pièces 9-patch)** :
  1. `panneau_bois.png` : cadre structurel en noyer/miel chanfreiné avec rainure interne et coins renforcés (barre principale, modales).
  2. `plaque_laiton.png` : cartouche en laiton brossé avec **4 rivets d'angle** et biseau lumineux haut/gauche (compteurs HUD, boutons d'action clés).
  3. `papier.png` : fiche en **papier crème texturé** bordée d'un filet encre brune (infobulles, descriptions, récompenses).
  4. `etiquette.png` : **étiquette carton découpée** à œillet laiton (coûts, badges de vague, raccourcis).
  5. `ruban.png` : **ruban plié bordeaux/terracotta** à liseré or (titres de vague, bannières victoire/défaite).
- **Iconographie** : 100 % illustrée sur mesure en 128 px (trait encre brun foncé `#3B2618`, volumes biseautés bois/laiton/pastel, **aucun emoji**).
- **Typographie OFL** (accents français & portugais complets : `é è ê à ç œ ã õ á í ó ú`) :
  - **Affichage** : **Fraunces** (serif doux artisanal aux courbes chaleureuses, évoquant une boîte de jeu de société européenne).
  - **Texte & chiffres HUD** : **Nunito** (humaniste arrondie ultra-lisible à petite taille, harmonieuse avec le bois tourné).
- **Animations UI recommandées** : micro-enfoncement physique (`+2 px` vers le bas) au clic, léger rebond élastique (*overshoot* `1,06 → 1,0`) à l'apparition des cartes/étiquettes, apparition contextuelle épurée pour laisser respirer la maquette.
