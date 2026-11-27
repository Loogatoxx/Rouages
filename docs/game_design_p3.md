# Game design après playtest 3 — « Tenir la ligne »

Réponse au §1 et au §2 du brief de Carlos (2026-11-27) : *trouver ce qui manque pour en faire un banger, éradiquer le
spam, diagnostiquer la sensation de vide*. Ce document dit **ce qu'on a observé**, **pourquoi le jeu en est là** et
**la solution retenue**, avec des chiffres vérifiables. Les tâches correspondantes sont dans `docs/roadmap.md`
§ « Après playtest 3 » (P3-xx).

## 1. Méthode : jouer, pas calculer
- **Joueur automatique** (`scripts/joueur_auto.gd`) : il joue de vraies parties dans la scène du jeu (tirages,
  boutique, pose, améliorations, vagues), dans deux styles — « spam » (le plus d'ateliers possible) et « tactique »
  (tourelles, améliorations) — et prend des captures pendant les vagues. Sans fenêtre, une partie dure 30 secondes.
- **Captures rapprochées** de scènes construites exprès (tourelles, Pont, Générateur) pour juger les bugs visuels.
- **Banc** (`scripts/banc_equilibrage.gd`) pour comparer deux réglages sur 3 graines.
Pourquoi : un tableau de chiffres ne dit pas si l'écran est lisible. Les images, si.

## 2. Diagnostic du « gros bordel / spam »
Cinq causes, toutes mesurées dans les données ou vues sur les captures.

| # | Cause | Preuve | Effet ressenti |
|---|---|---|---|
| 1 | **Le nombre fait tout.** | 15 jouets par atelier (+3 par niveau), 1,1 jouet/s ; V10 = 229 scarabées, un toutes les 0,21 s. | Deux nuées sans forme se rentrent dedans : on ne lit ni qui gagne ni pourquoi. |
| 2 | **Aucune rareté.** L'horloge alimente un nombre illimité de bâtiments. | La meilleure dépense est toujours « un atelier de plus » : le joueur automatique gagne 6 parties sur 6 avec **150 à 260 jouets vivants** à l'écran. | Une seule stratégie, donc pas de stratégie ; et un écran illisible. |
| 3 | **Le lieu du combat n'est pas choisi.** | Tous les jouets s'arrêtent à 55 % de la route (`garde_ratio`), quel que soit leur atelier. | La place d'un atelier ne change presque rien : poser n'est pas un choix. |
| 4 | **Les tourelles font de la figuration.** | Canon : 6 dégâts/s face à 100-229 ennemis de 14 à 25 PV. | On ne construit jamais une « zone de tir » dont on est fier. |
| 5 | **Rien à faire pendant la vague.** | Aucune action du joueur entre « Lancer » et la fin. | On regarde un écran confus au lieu de vivre un moment de tension. |

En une phrase : **aujourd'hui on gagne en ayant PLUS ; un grand tower defense fait gagner en plaçant MIEUX.**

## 3. Ce que font les jeux de référence
| Jeu | Ce qui le rend satisfaisant | Ce qu'on en tire |
|---|---|---|
| *Kingdom Rush* | Peu d'emplacements ; la **caserne tient un point de ralliement** choisi par le joueur, les tours autour pilonnent les ennemis bloqués ; l'argent va dans les **améliorations**, pas dans le nombre ; 2 sorts pour agir pendant la vague. | Postes de garde, énergie rare, coup de carillon. |
| *Bloons TD 6* | Chaque tour a un **rôle** ; les ennemis spéciaux (camouflés, plombés) cassent la mono-stratégie ; les meilleurs emplacements sont rares. | Rôles nets, ennemis qui testent un rôle. |
| *Plants vs. Zombies* | Peu de cases, **soleil rare**, une nouveauté à la fois ; chaque plante se lit en un coup d'œil. | Rareté de l'énergie, lisibilité avant tout. |
| *Thronefall* | Très peu de bâtiments, chaque amélioration est un vrai choix ; on se bat pendant la nuit. | « Peu mais bien », un geste du joueur pendant la vague. |
| *Legion TD 2* | La vague est annoncée : on compose **contre** elle. | Aperçu de vague déjà là (PT-17) : il doit enfin servir. |
| *Rogue Tower*, *Isle of Arrows* | Le chemin grandit, chaque carte posée ferme d'autres options. | Déjà en place (extensions, tirages) : on garde. |
| *Mindustry*, *Creeper World* | L'**énergie est un budget** : on ne branche pas tout. | Le réseau d'engrenages devient une vraie ressource. |

Point commun : **la rareté** (emplacements, argent ou énergie) force des choix, et **le joueur décide où le combat a
lieu**. Rouages n'a ni l'une ni l'autre. C'est ça, « le truc qui manque ».

## 4. Solution retenue : « Tenir la ligne »
Le plaisir visé : **composer sa propre zone de tir** (une escouade qui bloque ici, un mortier qui couvre ce virage, un
carillon qui ralentit devant) **puis la regarder fonctionner**. Quatre piliers, dans l'ordre de leur importance.

### Pilier 1 — Le Tic-tac : l'énergie de l'Horloge est comptée (anti-spam à la racine)
- L'Horloge fournit un nombre limité de **dents** d'énergie. Départ : **4 dents**. +1 dent après les vagues 2, 4, 6
  et 8 (elle « se remonte »), soit 8 dents en fin de partie ; une amélioration d'Établi pourra en ajouter une.
- Chaque bâtiment consomme : atelier de soldats **2**, atelier de lance-billes **2**, canon **1**, carillon **1**,
  mortier **2**. Les engrenages ne consomment rien (ils sont le chemin, et leurs bonus de voisinage restent).
- Quand l'Horloge est pleine, **le bâtiment qu'on vient de poser reste éteint** (écriteau « Plein », exactement comme
  le Générateur depuis ce lot) : on comprend tout de suite. Jauge « dents utilisées / dents » dans le HUD, coût en
  dents sur chaque carte.
- Le Générateur légendaire devient logique : c'est **+2 dents ailleurs**, pas une seconde horloge.
Pourquoi ça tue le spam : « un atelier de plus » n'est plus possible. Avec 4 à 8 dents, on a 2 à 4 gros bâtiments.
L'argent part alors dans **les améliorations et les engrenages à bonus** : mieux, pas plus.

### Pilier 2 — Les postes de garde : le joueur choisit où l'on se bat
- Chaque atelier a un **drapeau** sur la route (par défaut la case de route la plus proche ; déplaçable par le
  joueur jusqu'à 3 cases de l'atelier, anneau de portée visible). Son escouade marche jusqu'au drapeau **par la
  route**, s'y range et **bloque** : un ennemi au contact s'arrête pour se battre.
- Les escouades sont **petites et solides** : 5 soldats par atelier au niveau 1 (+1 par niveau), remplacés à
  **0,5 jouet/s** (la cible donnée par Carlos). Un soldat vaut à peu près deux soldats d'aujourd'hui.
- Les lance-billes tiennent leur drapeau et tirent : les poser **derrière** des soldats devient un vrai geste.
Pourquoi : c'est la moitié manquante de *Kingdom Rush*. Le combat a lieu là où le joueur l'a décidé, devant ses
tourelles ; l'écran montre des groupes rangés au lieu d'une traînée de jouets.

### Pilier 3 — Des rôles nets, des ennemis qui les testent
| Pièce | Rôle (un mot) | Réglage visé |
|---|---|---|
| Soldats | **Bloquer** | PV 26, dégâts 4 : ils tiennent, ils ne tuent pas vite. |
| Lance-billes | **Percer le ciel** | Seuls à toucher les libellules avec les tourelles ; fragiles. |
| Canon | **Achever** | Tir précis, gros dégâts sur une cible (casse l'armure). |
| Carillon | **Ralentir** | Son onde ralentit de 35 % pendant 1,5 s : il prépare le terrain du mortier. |
| Mortier | **Raser** | Zone lente et lourde ; redoutable sur un groupe bloqué. |
Les vagues passent de « beaucoup de faibles » à « moins, mais chacun compte » : V1 = 8 scarabées, V10 = environ 70
ennemis et le Grand Scarabée (au lieu de 229). Chaque type d'ennemi garde son contre (fourmis → zone, cuirassés →
canon et mortier, libellules → tirs, taupes → soldats, porte-bouclier → à tuer en premier).

### Pilier 4 — Un geste pendant la vague : le Coup de carillon
L'Horloge se charge en 25 s. Un clic sur la route : tous les ennemis à 3 m sont **étourdis 2,5 s** (onde dorée,
son de cloche). Un seul pouvoir, simple, qui crée le moment « j'ai sauvé la ligne ».
Pourquoi : sans geste du joueur, une vague n'est qu'une attente. *Kingdom Rush* et *Thronefall* le montrent.

### Ce qu'on ne fait pas (et pourquoi)
- **Pas de labyrinthe libre** : la route imposée reste notre lisibilité.
- **Pas de micro-gestion d'unités** : on déplace un drapeau, jamais un soldat.
- **Pas de nouvelle monnaie** : les dents sont une capacité, pas un compteur de plus à dépenser.

## 5. Chiffres : avant → cible (à confirmer en jouant, puis au banc)
| Réglage | Avant | Cible | Raison |
|---|---|---|---|
| Cadence atelier de soldats | 1,1 jouet/s | **0,5** | demande de Carlos |
| Cadence atelier de lance-billes | 0,45 | **0,3** | même proportion |
| Plafond par atelier | 15 (+3/niveau) | **5 (+1/niveau)** | escouade lisible |
| Soldat : PV / dégâts | 14 / 3 | **26 / 4** | moins nombreux, plus solides |
| Bâtiments alimentés | illimité | **4 dents, 8 en fin de partie** | rareté |
| Ennemis V1 / V5 / V10 | 14 / 100 / 229 | **8 / 30 / 70** (PV relevés d'autant) | lisibilité |
| Jouets vivants au maximum | 150 à 260 (mesuré) | **20 à 35** | fin du « bordel » |
| Durée d'une vague | 22 à 62 s | **35 à 70 s** | le temps de voir sa ligne tenir |

**Critères de réussite** (mesurés par le joueur automatique, 3 graines, 3 cartes) : le style « spam » ne fait pas
mieux que le style « tactique » ; jamais plus de 35 jouets vivants ; un profil moyen perd entre la V6 et la V10, un
profil soigné gagne avec 5 à 20 PV.

## 6. Diagnostic de la sensation de « vide »
Vu sur les captures de vraies parties (`art_refs/playtest3/`), dans l'ordre d'importance :

| # | Cause précise | Ce qu'on voit |
|---|---|---|
| 1 | **Cadrage** : le plateau occupe 35 % de l'écran, les unités font 20 pixels. | Deux tiers de l'image = bois nu. Les jolis modèles Hyper3D sont invisibles à cette distance. |
| 2 | **Plateau uniforme** : 81 cases du même vert, plates, sans rien dessus. | Aucun point d'accroche pour l'œil ; les 5 bâtiments flottent au milieu d'une pelouse. |
| 3 | **Entourage désert** : une table vide autour d'une maquette. | Le décor promis par la DA (« établi d'horloger ») n'existe pas. |
| 4 | **Pause morte** : entre deux vagues, rien ne bouge (choix voulu au playtest 2 pour les jouets). | La moitié du temps de jeu est une image fixe. |
| 5 | **Impacts muets** : un flash blanc, puis l'ennemi disparaît. | Pas de sensation de coup porté, pas de récompense visible. |
| 6 | **Aucune vie ambiante** : ni oiseau, ni fumée, ni lumière qui bouge. | Le monde n'existe pas en dehors du combat. |
| 7 | **Contraste à l'envers** : l'élément le plus clair de l'image est la route… vide la plupart du temps. | L'œil va là où il ne se passe rien. |

### Solution : « l'établi habité »
1. **Cadrage serré et vivant** : la caméra cadre le plateau à 60 % de l'écran ; léger zoom automatique vers le
   front pendant la vague (désactivable).
2. **Un plateau qui raconte** : cases de décor non constructibles (bosquet, mare, rocher, barrière, parterre) posées
   par carte ; trois teintes d'herbe par zones ; bordure de maquette plus épaisse. Ces cases deviennent aussi des
   **contraintes de placement** (voir § 7).
3. **L'établi autour** : outils d'horloger, bobines, loupe, plans, tasse — de grands objets flous au bord de
   l'image, qui donnent l'échelle « jouet ».
4. **Une pause qui respire** : clés des ateliers qui tournent lentement, fumée des cheminées, drapeaux qui flottent,
   Horloge dont le balancier bat, un oiseau mécanique qui se pose sur un toit. Aucun jouet dehors (règle du playtest 2
   conservée).
5. **Des impacts qui se sentent** : petit ressort qui saute et roule vers le compteur, poussière sous un obus,
   onde au sol du carillon, léger recul de l'ennemi touché, secousse courte quand l'Horloge est frappée.
6. **Lumière** : tache de soleil de fenêtre qui glisse lentement sur la table, ombres des croisillons.
Budget : tout en `MultiMesh`, particules bridées par l'option « Effets » déjà en place (P2-05).

## 7. Cartes neuves : une palette ET une règle chacune
| Carte | Palette | Mécanique propre | Ce qu'elle demande au joueur |
|---|---|---|---|
| **La Serre** | menthe, rose poudré, verre | **Rigoles d'arrosage** : des cases d'eau coupent l'herbe en îlots ; l'énergie ne les traverse que par le Pont. | Choisir ses îlots, économiser ses dents. |
| **Le Manège** | crème, rouge cerise, or | **Plaque tournante** : un morceau de route pivote d'un quart de tour toutes les 2 vagues (annoncé) ; les entrées changent. | Déplacer ses drapeaux, garder une réserve. |
| **Le Quai** | bleu ardoise, sable, laiton | **Marée** : une des deux routes est sous l'eau une vague sur deux ; l'autre reçoit toute la vague. | Défendre deux fronts avec une seule Horloge. |
| **Le Rail** | ocre, vert bouteille | **Petit train** : il traverse la route à intervalle fixe et repousse tout ce qui s'y trouve, jouets compris. | Poser son poste de garde hors des rails, viser le bon moment. |
Chaque carte arrive avec son décor (§ 6) : la variété se voit avant de se jouer.

## 8. Ordre d'exécution
1. Bugs visibles (chemins, Pont, tourelles) et Générateur — **fait dans ce lot**.
2. Pilier 1 (Tic-tac) + chiffres du § 5, vérifiés au joueur automatique puis au banc.
3. Pilier 2 (postes de garde), puis pilier 3 (carillon qui ralentit), puis pilier 4 (coup de carillon).
4. Interface (§ 5 du brief), puis « l'établi habité », puis les cartes à mécaniques.
Chaque étape : tests, captures avant/après, 3 graines au joueur automatique, commit.

## 9. Lot 2 : ce qui est en jeu, réglé en jouant (2026-11-27, soir)
Piliers 1 (Tic-tac) et 2 (postes de garde) sont dans le jeu. Les chiffres ci-dessous remplacent les cibles du § 5 :
ils viennent de plus de 300 parties jouées par le joueur automatique, pas d'un calcul.

| Réglage | Retenu | Pourquoi (ce que les parties ont montré) |
|---|---|---|
| Énergie de l'Horloge | 4 dents, +1 après V2, V4, V6, V8 (11 et 13 en Longue route) | à 8 dents : 2 escouades et 4 tourelles |
| Coûts | ateliers 2, mortier 2, canon 1, carillon 1 ; Générateur : +3 dents (4 amélioré) | une tourelle doit valoir son dent |
| Ateliers | soldats 0,5 jouet/s, lance-billes 0,3 ; plafond 5 (+1 par niveau) | demande de Carlos ; 14 à 35 jouets vivants au lieu de 150 à 260 |
| Soldat | PV 34, dégâts 2, 1 coup/s ; +15 % PV et dégâts par niveau d'atelier | il **tient**, il ne tue pas : sans tourelles, la ligne finit par céder |
| Lance-bille | PV 10, dégâts 7, portée 2,4 m | seul jouet à toucher les libellules |
| Canon / carillon / mortier | 20 dégâts à 0,6 tir/s · 4 de zone · 24 de zone | le canon perce l'armure (6) des cuirassés |
| Cuirassé | PV 26, armure 6 | un soldat lui fait 0,3 : il **faut** un canon ou un mortier |
| Vagues | V1 8 ennemis → V10 36 + 10 cuirassés + 10 libellules + boss, par paquets de 2 à 7 | un paquet met la ligne à l'épreuve ; un filet d'ennemis isolés, jamais |
| Fuite | scarabée, fourmi, libellule 1 PV ; cuirassé 3 ; boss 12 | une ligne qui cède coûte quelques PV, pas la partie |
| Boutique | canon (16) et carillon (20) achetables | les tourelles sont au cœur du jeu, plus un cadeau de coffre |
| Cartes à plusieurs entrées | Jardin d'hiver +2 dents, Boîte à musique +1, Grand atelier +3 (et un Pont) | une escouade par entrée sans tronc commun |

### Mesures (3 cartes × 4 graines, difficulté normale)
| Style du joueur automatique | Ce qu'il fait | Victoires | Lecture |
|---|---|---|---|
| **spam** (rien que des ateliers de soldats) | l'ancienne stratégie gagnante | 0 sur 6 | les libellules passent toutes |
| **masse** (soldats + lance-billes, aucune tourelle) | la quantité avec le minimum de variété | 0 sur 9 | la ligne cède en V8-V10 : personne ne tue les cuirassés |
| **moyen** (bonne composition, cases au hasard, niveau 2 au plus, fanions par défaut) | un joueur qui ne réfléchit pas à ses placements | 3 sur 12 | perd entre la V7 et la V10 |
| **tactique** (2 escouades au bon endroit, 3 canons, 1 carillon, tout amélioré) | « tenir la ligne » | 9 sur 12, 4 à 28 PV restants | la composition et la place décident |
Jamais plus de 39 jouets vivants, 14 le plus souvent. Avant le lot : 6 victoires sur 6 pour le spam, 150 à 260 jouets.

### Ce qui reste à régler
- **Durée des vagues** : 23 s (V1) à 130 s (V10), au-dessus de la cible (35 à 70 s) à partir de la V4 ; la V10 est
  une vague de boss, mais la V4 (85 s pour 19 ennemis) traîne tant qu'on n'a qu'un canon.
- **Lance-billes** : moins rentables par dent que deux canons ; à revoir avec le pilier 3 (carillon qui ralentit).
- **Boîte à musique et Grand atelier** : le joueur automatique ne sait pas poser de Pont, ces deux cartes ne sont donc
  pas mesurées (jouables à la main, à vérifier par Carlos).
