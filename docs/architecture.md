# Architecture — Rouages

## Principes (et pourquoi)
1. **La logique ne connaît pas les visuels.** `board/`, `swarm/`, `waves/`… sont du calcul pur ; les scènes `*_visuel`
   observent l'état et l'affichent. → On remplace le greybox par la vraie 3D sans toucher au gameplay ;
   Codex (`game/`) et Antigravity (`assets/`) ne se marchent pas dessus ; la logique se teste en headless.
2. **Données en Resources `.tres`** (`data/`). → L'équilibrage se fait sans code ; fichiers minuscules = peu de tokens.
3. **Énergie par propagation (BFS) depuis l'horloge**, recalculée **uniquement** sur `Events.plateau_modifie`.
   Chaque tuile a 4 côtés, chacun avec ou sans port d'engrenage ; tourner une tuile fait tourner ses ports.
4. **Nuées orientées données** : `SwarmSim` manipule des tableaux (positions, PV, cibles). Les ennemis suivent un
   **champ de flux** vers l'horloge (recalculé sur changement de plateau). Les combats passent par une **grille spatiale**.
   Le rendu utilise 1 `MultiMeshInstance3D` par type d'unité. Pas de physique Godot. Objectif : 300 contre 300 à 60 FPS.
5. **Bus d'événements minimal** (`Events`) : un signal n'existe que s'il est écouté par un autre système.

## Boucle de run (`Run`, autoload)
`DRAFT` (1 lot parmi 3, tiré d'une pioche pondérée) → `CONSTRUCTION` (poser et orienter ce qu'on possède) → `VAGUE` → … ×10
→ `FIN` (victoire/défaite → rejouer). Toutes les transitions passent par `Run` (`choisir_lot`, `lancer_vague`,
`terminer_vague`, `subir_degats`) : la machine à états tient dans un seul fichier, testable en headless.
- **Réserve** (`Run.reserve`) : on ne pose que ce qu'on a drafté. Le plateau et la réserve de départ sont dans `data/depart.tres`,
  la pioche et la liste des vagues dans `data/regles.tres`.
- **Extensions de terrain** (`data/extensions/`) : un morceau de sol 3×3 accolé au bord. Son chemin doit se raccorder au réseau et
  ajouter **au moins une entrée** (sinon la pose est refusée). Le bonus de pièces arrive à la pose, jamais au draft.
- **Remontage** : en CONSTRUCTION, les ateliers alimentés produisent et les jouets rejoignent leur poste (aucun ennemi).
  → Pas de spirale de défaite (une vague ratée ne vide plus l'armée de la suivante), et un retour visuel immédiat à la pose.
- **Répartition aux embranchements** : chaque jouet tire une branche au hasard à sa naissance. → Chaque front reçoit sa part.

## Économie : les ressorts (`Run.ressorts`)
- **Gains** : prime de fin de vague `recompense_vague + recompense_par_vague × (n − 1)`, + `bonus_sans_degat` si l'horloge
  n'a rien perdu, + la **rente des extensions** posées (`ExtensionDef.revenu`), + le butin des ennemis (`UniteDef.butin` :
  0 pour le scarabée, 2 pour le cuirassé). Pose d'une extension : `ExtensionDef.ressorts` tout de suite.
  → Pourquoi si peu de butin : avec 1 par scarabée, une run rapportait ~1 300 ressorts (≈ 80 ateliers) ; la prime de vague
  garde l'économie lisible (~300 ressorts par run) et récompense le jeu propre.
- **Dépenses** (`regles.tres`) : boutique en CONSTRUCTION (`Run.acheter`, lots avec `prix` et `vague_min`), relance du
  tirage en DRAFT (`Run.relancer_offre`), réparation de l'horloge (`Run.reparer_horloge`).
- **Vitesse** : `Run.vitesse` (×1 / ×2, `Run.basculer_vitesse`) multiplie le pas de `Partie` ; Espace bascule.

## Garde, pose en vague, plateaux, défi du jour (T09a, retours d'un testeur externe)
- **Garde des jouets** (`Regles.garde_ratio` 0,55) : sans cible, un jouet n'avance pas au-delà de 55 % du chemin depuis
  l'horloge. → Avant, ils campaient sur les entrées et cassaient les ennemis à leur apparition : le testeur « voyait à peine
  un ennemi » et la partie semblait trop facile. Le banc applique la même garde.
- **Pose pendant les vagues** (moins de temps morts) ; **rotation d'une pièce posée payante** (`prix_rotation` 2) pour que
  le placement initial compte ; marqueurs bleus des positions valides d'une extension, rotation choisie automatiquement.
- **Plateaux** (`Regles.departs`) : Prairie, Méandres (long S), Fourche (deux chemins en coude). `Run.choisir_depart(i)`.
- **Défi du jour** : `Run.preparer_defi(date)` → plateau et graine déduits de la date (même partie pour tout le monde ce jour-là).
- **Fourmi mécanique** : ennemi rapide et fragile (renfort de la V3).

## Unités et ateliers
| Unité | Camp | Rôle |
|---|---|---|
| Soldat à remontoir | allié | corps à corps, produit par l'atelier de soldats |
| Lance-bille | allié | tir à 2,4 m, fragile ; atelier de lance-billes (pioche dès la V3, boutique) |
| Scarabée | ennemi | nuée de base |
| Fourmi mécanique | ennemi | rapide (3,6 m/s), 5 PV, en nuée ; renfort de la V3 |
| Scarabée cuirassé | ennemi | lent, 45 PV, 5 dégâts à l'horloge ; renforts répartis dans la vague dès la V4 (`VagueDef.renfort`) |

## Audio (`Sons`, autoload)
Sons synthétisés par `scripts/generer_sons.py` (Python + ffmpeg, rien de payant). `Sons` écoute `Events` (horloge touchée,
vague, fin de run, ennemi cassé) ; pose, rotation, clic et sortie de jouet s'appellent par `Sons.jouer(&"nom")`.
Anti-répétition par son, musique en boucle, réglages dans `user://reglages.cfg` (partagé avec le tutoriel).

## Arborescence
| Dossier | Contenu | Qui |
|---|---|---|
| `game/core/` | autoloads `Events`, `Run` | Claude |
| `game/board/` | grille, tuiles, rotation, énergie | Codex |
| `game/swarm/` | SwarmSim, champ de flux, grille spatiale, rendu MultiMesh | Codex (spec Claude) |
| `game/workshops/ waves/ draft/ camera/ ui/` | ateliers, vagues, draft, caméra, interface | Codex |
| `data/tuiles/ unites/ vagues/` | `.tres` d'équilibrage | Claude (valeurs) / Codex (classes) |
| `assets/` | greybox, final, matériaux, audio | Antigravity |
| `tests/` | tests de logique headless (`./scripts/tests.sh`) | Codex + Claude |
| `taches/` | fiches de délégation, `revues/` | Claude |
| `scripts/` | bridges, tests, `banc_equilibrage.gd` (simule une run headless, mesure les fuites) | Claude |

## Contrat d'assets
1 tuile = 2 m × 2 m · origine au centre de la base · Y vers le haut · `.glb` · `assets/final/<nom>/`.

## Signaux (`game/core/events.gd`)
`plateau_modifie` · `energie_recalculee(alimentees)` · `phase_changee(phase)` · `vague_commencee(n)` ·
`vague_terminee(n)` · `horloge_touchee(pv)` · `tuile_choisie(id)` · `run_terminee(victoire)` ·
`ressorts_changes(total)` · `ennemi_casse(position)` · `pause_demandee` (Échap sans pièce sélectionnée) ·
`message_joueur(texte)` (retour court au joueur : action refusée, astuce ; affiché par le HUD) ·
`piece_reprise(case, def)` (pièce posée reprise en réserve ; écouté par `Partie`)

## Entrées (InputMap)
`poser_tuile` (clic gauche) · `tourner_tuile` (R / clic droit) · `annuler` (Échap) · `basculer_camera` (Tab) ·
`camera_gauche/droite/haut/bas` (Q·D·Z·S en AZERTY : touches physiques) · `camera_zoom_avant/arriere` (molette) · `accelerer` (Espace, bascule ×1/×2) · `pause` (P ; Échap aussi, voir
`pause_demandee`) · `plein_ecran` (F11, Alt+Entrée).

## Journal des décisions
- 2026-11-23 : Godot 4.7.2, Forward+, GDScript, PC d'abord (itch.io puis Steam). Mini-lanceur de tests maison (zéro addon).
- 2026-11-23 : Codex écrit directement dans le dépôt (pas de `drafts/`), limité aux fichiers de la fiche ; git sert de filet.
- 2026-11-26 : étape 5. Draft par **lots** (`Lot` = objet + quantité + poids + vague minimale), réutilisés pour la pioche, la réserve
  de départ et les bonus d'extension. Équilibrage mesuré au banc (`scripts/banc_equilibrage.gd`) plutôt que deviné : un atelier à
  plein stock encaisse environ 30 PV de scarabée par seconde ; le débit d'une vague vaut `10 × multiplicateur / intervalle`.
  Le banc a fait ajouter la répartition aux embranchements et le remontage (voir « Boucle de run »).
- 2026-11-26 : rush jouabilité (T08a-c). Monnaie « ressorts », boutique, 2e ennemi (cuirassé) et 2e atelier (lance-billes),
  rente des extensions (retour « je double juste »), sons procéduraux, menu titre / pause / tutoriel. `Reserve.ids()` trie
  désormais par texte : `sort()` sur des `StringName` suit leur identifiant interne et l'ordre changeait à l'ajout de données.
- 2026-11-26 : étape 8. `export_presets.cfg` (macOS universel signé ad hoc, Windows x86_64 avec pck embarqué = un seul .exe).
  Compression de textures ETC2/ASTC activée (exigée pour le Mac universel). Les textures extraites du .glb restent hors git
  (regénérées à l'import) mais sont incluses dans les builds.
- 2026-11-26 : retours d'un testeur externe (T09a-b) : garde des jouets, pose en vague, rotation payante, 3 plateaux, défi du
  jour, fourmi, traduction FR/EN/PT (clé = texte français, CSV `traductions/textes.csv`). Rééquilibrage au banc : avant,
  aucune fuite de V1 à V7 même pour un joueur moyen puis un mur en V8-V10 ; après, le joueur moyen subit ses premières
  fuites en V3-V5 et perd en V8, le placement parfait gagne de justesse. Icône du jeu et musique de vague (fondu enchaîné).


## Étape 10 — contenu post-MVP (2026-11-26)
- **Tourelles (loot rare)** : `PieceDef.Type.TOURELLE` + `rarete` (commune/rare/épique) et stats de tir. `Tourelles` (RefCounted,
  `game/workshops/`) fait tirer les tourelles alimentées pendant les vagues via `SwarmSim.blesser_zone` (cible la plus proche,
  zone optionnelle) ; les morts passent par le chemin habituel (`unite_morte` → butin). Obtenues seulement dans les **coffres** :
  `Regles.vagues_coffre` (3, 6, 9) remplacent le draft par un tirage dans `Regles.coffre` (`Run.offre_coffre`).
- **Boss** : `UniteDef.boss`, `VagueDef.boss` + `pv_boss_facteur`. Le directeur le lâche une fois à mi-vague ; la vague ne
  finit qu'à sa mort. `SwarmSim.pv_boss()` alimente la barre du HUD. Grand Scarabée en V5 (PV ×0,5) et V10.
- **Progression méta** : `Progression` (statique, `user://progression.cfg`) garde les engrenages d'or et les niveaux des
  `AmeliorationDef` (`data/ameliorations/`). `Run.reinitialiser` calcule des valeurs effectives (`pv_max`, `choix_par_draft`,
  `bonus_cadence`, rente, relance offerte) sans toucher `regles.tres`. Gains : 1/vague tenue + 5 si victoire. Le défi du jour
  ignore bonus et gains (équité). Écran : `game/ui/etabli.tscn`.
- **Options** : bus audio `Musique` / `Effets` (`default_bus_layout.tres`), volumes et plein écran dans `user://reglages.cfg`,
  panneau `game/ui/options.tscn` partagé par le titre et la pause.
- **DA v2** (étude `art_refs/etude_da_v2.md`) : kit `.glb` en volume `assets/final/kit_v2/` chargé par `Materiaux.scene_du_kit`
  (repli sur les primitives si absent, utile en headless) ; vue inclinée en perspective par défaut (la vue de dessus reste sur
  la touche caméra) ; table d'établi en bois sous la maquette ; kit UI `assets/ui/` (9-patch bois/laiton/papier/étiquette/ruban,
  icônes, polices OFL Fraunces + Nunito).

## Après playtest 1 (2026-11-26) — corrections P0
- **Raccord des extensions** (`Extension.raccord`) : un sentier posé contre un bord sans route creuse le plus court chemin
  dans l'herbe libre (sans pièce, jamais collé à l'horloge) jusqu'à une route existante ; l'aperçu montre ce raccord.
  → Pourquoi : on ne pouvait étendre le terrain que du côté des routes. Le tracé vise une route et non l'horloge pour
  que tout le réseau arrive par sa porte. Le visuel reconstruit une dalle dont le sol change (herbe → chemin).
- **Porte de l'horloge** : le modèle (porte au nord, −Z) est tourné vers la case de chemin qui la touche. Fourche
  redessinée pour que ses deux routes se rejoignent devant la porte (une seule arrivée).
- **Autoload `Fenetre`** : applique le plein écran une seule fois au lancement, enregistre tout changement de la vraie
  fenêtre (bouton vert macOS, F11) ; `-- --fenetre` en ligne de commande (captures) la laisse telle quelle.
- **Rotation** : `Run.prix_rotation` vaut 0 avant la vague 1 (on démarre à 0 ressort : elle était refusée sans un mot).
  L'horloge ne se tourne pas ; un refus envoie `message_joueur`.
- **Textes à retour à la ligne** : `Interface.caler_hauteur(label, largeur)` (dans `menu_titre.gd`) fixe la largeur et
  mesure la hauteur sur la police. → Un Label à retour automatique calcule sa hauteur sur sa largeur du moment (nulle
  avant la première mise en page) : fiches immenses, texte traduit qui débordait des cartes.

## Après playtest 1 — lot 2 (UI, caméra, vraie pause, tirages)
- **Vraie pause entre les vagues** : en construction, la production est arrêtée ; chaque atelier alimenté reçoit d'un coup
  `Regles.remontage_lancement` (20 s) de production, **une seule fois par pause** (`Production.remonter` /
  `nouvelle_pause`), puis les jouets rejoignent leur poste. → Attendre ne rapporte rien (retour de Carlos), mais une
  vague ratée ne vide pas l'armée suivante. Le banc applique la même règle (20 s de marche simulées) : équilibre proche
  de l'ancien (parfait 0/0/106 PV, moyen chute en V5).
- **Tirages sans doublon** : `Draft.tirer` n'offre jamais deux lots du même objet ; `exclus` sert aux cartes de coffre
  tirées une à une.
- **Caméra** : zoom lissé vers le curseur (molette, +/−, pincement et défilement du trackpad Mac : gestes
  `InputEventMagnifyGesture` / `InputEventPanGesture`, que l'ancienne caméra ignorait), inclinaison 30-80° (A/E,
  clic molette glissé). Actions `camera_redresser` / `camera_coucher`.
- **HUD** : boutique repliable (bouton + touche B, action `boutique`), « Lancer la vague » hors du panneau, bouton menu
  (icône `menu.png`) ; menu en jeu avec aide et commandes, quitter le jeu. Badges = `pastille.png` (charte T11a).
- **Charte d'icônes** (T11a, Gemini) : `art_refs/charte_icones.md`, `assets/ui/icones/REGISTRE.md` (une icône = un concept),
  20 icônes dont ressort, cœur (PV), vague, ennemis restants, entrée, chance, déplacer, améliorer, boutique, menu.

## Après playtest 1 — lot 3 (HUD lisible, déplacement)
- **Ennemis restants** : `DirecteurVagues.total()` / `restants(sim)` (pas encore entrés + boss + vivants) → plaque du HUD
  pendant les vagues.
- **Repères** (`game/ui/reperes.gd`, créé par le HUD) : entrées hors champ = panneau fléché au bord ; pendant une vague,
  ennemis hors champ regroupés en 16 directions (pastilles rouges numérotées). Rien pour ce qui est visible.
- **Reprendre une pièce** (T11b, Codex) : clic gauche main vide → `Run.reprendre_piece` (retour en réserve, pièce
  sélectionnée). Gratuit avant la vague 1, puis `prix_deplacement + prix_deplacement_pas × deplacements_pause` (3, 5, 7…,
  remis à zéro au lancement). Signal `piece_reprise` → `Production.atelier_repris` : un atelier déjà remonté puis déplacé
  ne l'est pas une 2e fois dans la même pause. → Le placement compte, une erreur se rattrape, et déplacer n'est pas une
  astuce pour gagner des jouets.

## Après playtest 1 — lot 4 (boutique et réserve en icônes)
- **Vignettes** : `scripts/generer_vignettes.gd` rend chaque pièce et extension du kit 3D en 128 px (vue 3/4, fond
  transparent, dents de laiton des ports ajoutées) dans `assets/ui/vignettes/<id>.png` ; `Interface.vignette_de(objet)`.
  À relancer après tout changement du kit. → Cohérent avec le plateau, sans dessin ni crédit.
- **Boutique** : grille de tuiles (vignette, ×quantité, prix + icône ressort), tuile inabordable grisée, nom et effet au
  survol ; réparer = cœur + gain. **Réserve** : vignette + ×N (vignette en enfant de taille fixe : l'icône native d'un
  `Button` rétrécit avec les marges du thème). Cartes de tirage : vignette à côté de l'insigne.

## Après playtest 1 — lot 5 (benchmark, placement, engrenages à identité)
- **Benchmark** : `docs/benchmark_td.md` (décisions D1-D8) tiré de `art_refs/benchmark_td_sources.md` (17 sources).
- **`Placement`** (`game/workshops/placement.gd`, logique pure) : bord de route (tourelle +25 % dégâts ; atelier qui
  lâche ses jouets sur la route), arrière-garde (atelier à ≥ 3 cases de la route : +20 % cadence), engrenages à identité
  via `PieceDef.bonus_voisins_*` (droit = démultiplicateur +15 % aux ateliers voisins, cumul 2 ; T = répartiteur +4 au
  plafond ; croix = moyeu +20 % de tir aux tourelles voisines ; coude = le moins cher), encombrement (−10 % par atelier
  identique collé, plancher ×0,4). Réglages dans `Regles` (groupe « Placement »). Lu par `Production`, `Tourelles`,
  l'infobulle (effets + aperçu de pose) et donc le banc. → Les cases ne se valent plus : la stratégie bat le spam.
- Banc : la disposition en grappe du banc perd un peu (parfait 37/83/0 PV, moyen chute en V5) : c'est voulu.

## Après playtest 1 — lot 6 (contre-jeu, chance, méta, lore)
- **Libellule mécanique** (T11c, Codex) : `UniteDef.volant` ; les jouets au corps à corps (portée < 1 m) l'ignorent,
  lance-billes et tourelles la touchent ; elle ne combat pas, file à l'horloge (1 dégât). `VagueDef.volants` /
  `nombre_volants` (4 à 12, V6-V10), comptée par le directeur. → Un build « tout soldats » ne gagne plus (le banc, qui
  ne pose que des soldats, perd exactement ces 40 PV) : il faut mêler tir à distance et corps à corps.
- **Chance** : `Run.chance` (0-10) multiplie le poids des cartes rares (×(1 + 0,25 × chance)) et épiques
  (×(1 + 0,5 × chance)) dans les coffres (`Draft.tirer(..., chance, facteurs)`). Sources : vague sans dégât (+1),
  porte-bonheur de la boutique (+2, 8 ressorts, une fois par pause), amélioration « Trèfle » de l'Établi (+1/niveau).
  Ignorée au défi du jour. Plaque trèfle dans le HUD dès 1 point.
- **Engrenages d'or** : prix de l'Établi rehaussés d'environ 40 % (~9 victoires pour tout débloquer au lieu de 5).
- **Lore** : `docs/lore.md` (bible vivante, relue par Gemini, 6 corrections intégrées).

## Après playtest 1 — lot 7 (améliorations, chantier d'extension)
- **Améliorations** (T11d, Codex) : `PieceDef.niveau_max` / `prix_amelioration`, niveaux par case dans `Plateau`
  (perdus à la reprise), `Run.ameliorer_piece` (prix = base × niveau). Gains dans `Placement` (`Regles` groupe
  « Améliorations ») : atelier +20 % cadence et +3 au plafond par niveau, tourelle +25 % dégâts, engrenage ×1,5 sur ses
  bonus aux voisins. **Panneau contextuel** (`game/ui/panneau_piece.gd`) au clic gauche sur une pièce : améliorer ·
  tourner · reprendre, avec prix. Ornements faits main (PT-51) : billes de laiton par niveau, anneau au niveau 3, fanion
  doré au niveau 5.
- **Chantier d'extension** (Gemini, `kit_v2/chantier_extension`) remplace les fanions : flèche vers l'extérieur,
  panneau qui se balance, un repère tous les 3 cases au plus.
