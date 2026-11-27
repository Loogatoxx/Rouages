# Roadmap — MVP (semaine 1)

**Périmètre du MVP** : le plateau qui pousse (draft de 3 tuiles entre les vagues) · chaîne d'engrenages qui transporte
l'énergie depuis l'horloge · défense uniquement par des ateliers producteurs de jouets alliés · nuées des deux côtés ·
run de ~15 min / 10 vagues · greybox aux couleurs de la DA + **horloge en vraie 3D (1 crédit Hyper3D)**.

**Critère de réussite** : Carlos joue une run complète sur son Mac ; ses choix de tuiles et de chaînes changent visiblement
l'issue ; les deux nuées sont lisibles en vue de dessus ; l'horloge 3D est à la bonne échelle ; 1 seul crédit dépensé.

| # | Étape | Qui | Critère de fin | État |
|---|---|---|---|---|
| 0 | Installation, MCP, bridges, squelette, docs, git | Claude | Le projet s'ouvre, les tests passent, les deux bridges répondent | ✅ |
| 1 | Grille, tuiles, rotation, propagation d'énergie (logique pure) | Codex (contrat Claude) | Tests headless au vert | ✅ (T01, 9 tests) |
| 2 | Caméra dessus/3D, pose et rotation à la souris, tuiles greybox, engrenages animés si alimentés | Codex | Carlos construit une chaîne et voit l’énergie passer | ✅ (T02) |
| 2b | Matériaux DA, lumière fin d'après-midi, kit greybox Blender (tuile, engrenage, atelier, scarabée, jouet) | Antigravity | Capture comparée à `art_refs/plateau_maquette_v1.jpg` | ✅ (T02b : 9 matériaux, ambiance, 8 assets, 0 crédit) |
| 3 | SwarmSim : champ de flux, grille spatiale, combats, rendu MultiMesh | Codex (spec Claude) | 300 contre 300 à 60 FPS | ✅ (T03 : 60 FPS en fenêtre, 3,2 ms/pas, 20 tests) |
| 4 | Ateliers alimentés → jouets ; vagues de scarabées ; PV horloge ; défaite | Codex | Une vague jouable de bout en bout | ✅ (T04 : 27 tests, 3 vagues provisoires) |
| 5 | Draft 1 parmi 3, machine à états de la run, UI minimale, victoire/défaite/rejouer, données de 10 vagues | Codex + Claude (équilibrage) | Run complète de 15 min | ✅ (T05a draft/réserve, T05b extensions, T05c 10 vagues + remontage ; 40 tests) |
| 6 | 🚦 Playtest Carlos + équilibrage. **Aucun crédit Hyper3D avant ce feu vert.** | Carlos + Claude | « C'est fun » | ✅ (T06a contraste des jouets, V2-V4 adoucies, horloge 30 PV, aperçu de pose bleu ; 43 tests) |
| 7 | Horloge : image → validation Carlos → Image-to-3D (1 crédit) → Blender → intégration ; 4-5 sons locaux | Antigravity | Horloge à l'échelle en jeu | ✅ (modèle Hyper3D, 1 crédit ; 11 sons synthétisés + musique, `scripts/generer_sons.py`) |
| 7b | Rush jouabilité : menus titre/pause/fin, ressorts + boutique, tutoriel, survol, vitesse x2, cuirassé, lance-billes, rente des extensions, passe visuelle (lumière, grille, vitrine 3D) | Codex (T08a-c) + Claude | Run complète du menu à l'écran de fin | ✅ (52 tests) |
| 9 | Retours d'un testeur externe : ennemis visibles (garde), pose en vague, rotation payante, aide à la pose d'extension, 3 plateaux, défi du jour, fourmi, traduction FR/EN/PT, rééquilibrage, icône, musique de vague, sensations d'impact | Codex (T09a-c) + Claude | Le testeur rejoue avec plaisir | 🟡 fait, à rejouer par le testeur |
| 8 | Builds Mac + Windows, test sur le PC Windows | Claude + Carlos | Deux `.zip` qui se lancent | 🟡 `builds/Rouages_mac.zip` testé (se lance, horloge 3D OK) ; `builds/Rouages_windows.zip` exporté sans erreur, à tester sur le PC |
| 10 | Post-MVP « one shot » (Carlos : autonomie totale) : tourelles en loot rare via coffres (V3/V6/V9), options (volumes, plein écran), progression méta (Établi, engrenages d'or), DA v2 (étude Antigravity, kit 3D en volume, kit UI bois/laiton/papier, polices OFL), boss | Codex (T10a-g) + Antigravity (T10e) + Claude | Le jeu ressemble à une sortie publique | ✅ (T10a-g ; 73 tests ; builds réexportés, Mac testé) — à valider en jeu par Carlos |

---

# Après playtest 1 (brief de Carlos du 2026-11-26)

**Lecture** : chaque ligne porte un identifiant `PT-xx` (repris dans les fiches et les commits), une priorité
(**P0** bloquant, **P1** court terme, **P2** moyen terme, **P3** long terme), un responsable et ses dépendances.
Responsables : **Claude** (architecture, logique, game design, équilibrage, relecture) · **Codex** (code délégué par fiche) ·
**Gemini** (= Antigravity, modèle Gemini 4 Neon : UI, icônes, DA, Blender, décor, borné à `assets/` et `art_refs/`) ·
**Hyper3D** (génération 3D, via Antigravity/Blender MCP ou le site avec Carlos) · **Carlos** (test, validation, connexion web).
Le relecteur n'est jamais le producteur (Claude relit Codex et Gemini ; Codex ou Gemini relit ce que Claude code seul).

## Court terme — 1. Bugs critiques et régressions (P0, à corriger avant tout le reste)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| PT-01 | **Sentiers posables partout** : une extension posée contre un bord sans route se raccorde seule (le chemin le plus court est creusé dans l'herbe libre jusqu'à la route existante, aperçu inclus). Cause : `Extension.est_valide` exigeait que le chemin de l'extension touche déjà une route. | P0 | Claude | `extension.gd`, `pose_controleur.gd`, `plateau_visuel.gd` ; tests de logique | ✅ |
| PT-02 | **Horloge face à la route** : le modèle 3D tourne sa porte vers la case de chemin qui la touche (au lieu d'une orientation fixe). | P0 | Claude | `plateau_visuel.gd` ; repérer l'axe de la porte dans `horloge.glb` | ✅ |
| PT-03 | **Plein écran conservé** au retour au menu : le mode n'est appliqué qu'au lancement, et le réglage suit le vrai mode de la fenêtre (bouton vert macOS, F11, Alt+Entrée). | P0 | Claude | `options.gd`, `menu_titre.gd`, nouvelle action `plein_ecran` | ✅ |
| PT-04 | **Rotation des pièces posées restaurée** : cause = rotation payante (2 ressorts) alors qu'on démarre à 0 ressort → refus silencieux. Rotation gratuite avant la vague 1, payante ensuite, avec un message clair si on ne peut pas payer. | P0 | Claude | `run.gd`, `pose_controleur.gd`, HUD (message) ; prépare PT-31 | ✅ |
| PT-05 | **Menus robustes à toutes les langues** : panneaux et boutons qui s'agrandissent avec le texte (pas de taille figée), textes qui passent à la ligne, vérification par captures FR/EN/PT de chaque écran. | P0 | Claude | `theme_rouages.tres`, scènes `game/ui/*.tscn`, `traductions/textes.csv` | ✅ |

## Court terme — 2. UI / UX, lisibilité, charte d'icônes (P1)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| PT-10 | **Audit UI strict écran par écran** (titre, établi, options, HUD, draft, coffre, boutique, réserve, pause, fin, tutoriel, infobulles) : liste de défauts avec captures, règle « s'il y a un doute, il n'y a pas de doute ». | P1 | Gemini (audit) → Claude (tri) | captures fournies par Claude (Gemini ne lance pas le jeu) | ✅ (`art_refs/audit_ui_v1/AUDIT.md`, 63 défauts) |
| PT-11 | Corrections de l'audit : **textes alignés sur leurs fonds**, boutons bien placés, aucune régression visuelle (captures avant/après). | P1 | Codex (scènes) + Claude (relecture) | PT-10, PT-05 | ✅ (reste 2 icônes pour Gemini, voir AUDIT.md) |
| PT-12 | **Boutons en bas à gauche contenus dans leur panneau** (marges internes du 9-patch respectées, plus de chevauchement de la bordure). | P1 | Claude | `reserve_ui.tscn`, `theme_rouages.tres` | ✅ |
| PT-13 | **Badge de quantité des choix redessiné** (abandon de l'étiquette à pointe gauche) + revue de chaque asset couplé à du texte. | P1 | Gemini (asset) + Claude (intégration) | PT-10 | ✅ |
| PT-14 | **Boutique repliable** : bouton ouvrir/fermer (fermée par défaut pendant les vagues). | P1 | Claude | `hud.gd` | ✅ |
| PT-15 | **Boutique refondue** : grille d'icônes + prix, détail au survol, **tuile de chemin en T** ajoutée (et croix), tri par catégorie. | P1 | Claude (contrat) → Codex | PT-14, PT-17 (icônes) | ✅ |
| PT-16 | **Vrai menu en jeu** : bouton ⚙ toujours visible → pause, reprendre, options, aide (revoir le tutoriel), recommencer, retour au menu, quitter. | P1 | Claude | `menu_pause.tscn`, `hud.tscn` | ✅ |
| PT-17 | **HUD clair** : ennemis restants / total de la vague, barre de progression de la vague, flèches au bord de l'écran vers les entrées actives et vers les combats, alerte quand l'horloge est touchée. | P1 | Claude (logique : compteurs dans `DirecteurVagues`/`SwarmSim`) → Codex (affichage) | PT-21 (icônes) | ✅ + aperçu de la vague suivante (D8) |
| PT-18 | **« Icônes au premier plan, texte au survol »** : remplacer un maximum de libellés par des icônes, infobulles papier au survol (nom, effet, coût, raccourci). | P1 | Codex (infobulles génériques) + Gemini (icônes) | PT-20, PT-21 | 🟡 boutique, réserve, cartes et HUD faits |
| PT-20 | **Charte d'icônes** : document `art_refs/charte_icones.md` (trait, palette, cadre, taille 128 px) + **registre « une icône = un concept »** (`assets/ui/icones/REGISTRE.md`), aucune icône réutilisée pour deux idées. | P1 | Gemini | `art_refs/etude_da_v2.md` | ✅ |
| PT-21 | **Icônes refaites en priorité** : ressort (vrai ressort hélicoïdal), vie de l'horloge (cœur), vague (silhouette d'insectes + numéro), puis toutes les icônes manquantes du HUD et de la boutique (ennemis restants, chance, déplacement, amélioration…). | P1 | Gemini | PT-20 | ✅ |

## Court terme — 4. Caméra et ergonomie (P1)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| PT-40 | **Zoom / dézoom** fluide à la molette, au trackpad (pincement) et au clavier (+/−), centré sur le curseur, bornes élargies. (La molette existait mais est mangée quand la souris survole l'interface.) | P1 | Claude | `camera_plateau.gd`, InputMap | ✅ |
| PT-41 | **Inclinaison de la caméra** : angle réglable en continu (clic molette glissé, touches A/E), de la vue de dessus à une vue rasante « maquette » ; Tab garde la bascule rapide. | P1 | Claude | PT-40 | ✅ |

## Court terme — 5. Gameplay court terme (P1)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| PT-30 | **Vraie pause entre les vagues** : en construction, plus aucune production ni mouvement ; au lancement, chaque atelier alimenté sort d'un coup son plein de jouets (le « remontage » devient instantané). → Attendre ne rapporte plus rien, mais une vague ratée ne vide pas l'armée suivante. | P1 | Claude | `partie.gd`, `production.gd`, banc d'équilibrage | ✅ |
| PT-31 | **Déplacer / reprendre une pièce posée** : gratuit avant la vague 1 ; ensuite « déménagement » payant et croissant (prix qui augmente à chaque déplacement entre deux vagues) et l'atelier déplacé repart sans stock. → Le placement compte, mais une erreur se rattrape. | P1 | Claude (règle, `Run`) → Codex (interaction) | PT-04 | ✅ |
| PT-32 | **Pas de doublon dans un tirage** : un même objet ne peut apparaître qu'une fois par offre (draft ET coffre, aujourd'hui tiré carte par carte). | P1 | Claude | `draft.gd`, `run.gd`, test | ✅ |
| PT-33 | **Engrenages d'or plus exigeants** : courbe de gain revue (moins par vague tenue, bonus de fin selon la difficulté) et prix des améliorations rehaussés, mesurés sur « parties pour tout débloquer ». | P1 | Claude | `regles.tres`, `data/ameliorations/` | ✅ prix +40 % |
| PT-34 | **Benchmark game design TD** (recherche web documentée : prise de décision, rythme, gestion de l'espace, synergies, contre-jeu) → `docs/benchmark_td.md` avec une liste d'améliorations concrètes classées. | P1 | Claude (+ Gemini `web_lookup` pour sources) | — ; nourrit PT-35 à PT-39 | ✅ `docs/benchmark_td.md` |
| PT-35 | **Différenciation des engrenages** : supprimer l'incohérence du droit (une case de plus pour rien) et donner à chaque type une identité (ex. droit = démultiplicateur qui accélère l'atelier au bout, T = répartiteur, croix = moyeu qui partage sa force, coude = bon marché). | P1 | Claude (design + logique `Energie`) → Codex | PT-34 | ✅ |
| PT-36 | **Positionnement tactique par rapport à la route** : bonus selon la place (ex. tourelle en bord de route = +dégâts, atelier en bord de route = jouets plus vite au front, case de carrefour = +portée), affiché en aperçu de pose. | P1 | Claude → Codex | PT-34, PT-17 | ✅ |
| PT-37 | **Stratégie > spam** : mécaniques anti-spam (rendements décroissants par atelier identique adjacent, synergies de voisinage, ennemis qui contrent la masse : volants, fouisseurs, kamikazes de zone), choisies d'après PT-34. | P1 | Claude (design) → Codex | PT-34, PT-35, PT-36 | ✅ encombrement + libellule volante (T11c) |
| PT-38 | **Chance** : stat de chance qui augmente la probabilité des raretés supérieures (porte-bonheur en boutique, vague sans dégât, amélioration méta « Trèfle »), affichée en icône. | P1 | Claude → Codex | PT-32, PT-21 (icône) | ✅ |
| PT-39 | **Craft enrichi** : nouvelles recettes simples (fusionner 3 pièces identiques = pièce de niveau supérieur, démonter pour récupérer des ressorts), sans alourdir l'interface. | P2 | Claude (design) → Codex | PT-50 (niveaux) | ✅ T11f (démonter, 3 recettes) |

## Moyen terme — améliorations, DA, Hyper3D, vie du plateau (P2)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| PT-50 | **Tout bâtiment et tout engrenage améliorable** : 3 niveaux minimum, jusqu'à 10 si le design le justifie (`PieceDef.niveaux`), coût croissant, effet lisible au survol. | P2 | Claude (contrat, équilibrage au banc) → Codex | PT-35, PT-31 | ✅ T11d (engrenages 3 niv., ateliers/tourelles 5) |
| PT-51 | **Évolution visuelle des niveaux** : paliers majeurs (niv. 1 puis 3 gros paliers) = modèle Hyper3D dédié (**4 maximum par élément**) ; niveaux intermédiaires = ajouts faits main sur le modèle du palier (pièces, matériaux, ornements, effets). | P2 | Hyper3D (paliers) + Gemini (ajouts Blender) | PT-50, PT-52 | 🟡 ajouts faits main faits (billes, anneau, fanion) ; modèles de paliers Hyper3D à venir |
| PT-52 | **Pipeline Hyper3D** : images de référence validées par Carlos → génération → nettoyage Blender → intégration. Budget (43 crédits restants) : palier 1 de 11 éléments (2 ateliers, 3 tourelles, 4 ennemis, 2 jouets) = 11 ; paliers 2-4 des 5 bâtiments = 15 ; horloge paliers = 3 ; décor maître (marqueur d'extension, boîte à musique, moulin) = 4 ; réserve d'essais = 10. Engrenages : modelés par calcul (dents qui doivent s'engrener → les maths battent la génération). | P2 | Claude (images, prompts, comptes) → Carlos (connexion web si l'API refuse) → Hyper3D | PT-20 (charte), `assets/CREDITS_HYPER3D.md` | 🟡 prompts et budget prêts (`art_refs/hyper3d/DEMANDE_LOT1.md`) ; images en attente du quota Gemini, puis Carlos |
| PT-53 | **Vraies animations** (en tête du moyen terme : demandé en priorité) : marche des insectes et des jouets, tir des tourelles, ateliers qui travaillent, horloge (balancier, aiguilles). Via Hyper3D (rig + animation) ; repli procédural seulement si l'animation générée est inexploitable (blocage noté). | P2 | Hyper3D + Gemini (Blender) → Claude (intégration) | PT-52 | 🟡 démarche procédurale des nuées + lecture auto des AnimationPlayer des bâtiments ; animations Hyper3D à venir |
| PT-54 | **Plateau vivant, jamais surchargé** : micro-détails d'ambiance (papillons, brins d'herbe au vent, fumée de vapeur, oiseaux-jouets, outils d'horloger sur la table, poussière dans la lumière). Règle pour chaque ajout : « puis-je ajouter un petit détail ici sans en faire trop ? ». | P2 | Gemini (assets) → Claude (intégration, budget de perf) | PT-10 | 🟡 poussière dorée et pétales (particules) ; micro-décors 3D en attente du quota Gemini |
| PT-55 | **Extension de territoire plus marquante** : remplacer les fanions par un élément fort (ex. pancarte de chantier en bois + boîte de pièces à déballer, tracé en pointillés du futur chemin). | P2 | Gemini (asset) + Claude (aperçu) | PT-01 | ✅ chantier de maquette (Gemini) |
| PT-56 | Texture de la table autour du plateau à refaire (non prioritaire). | P3 | Gemini | — | ✅ bois procédural (shader) |

## Long terme — modes, méta, onboarding, lore (P3)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| PT-60 | **Runs plus ambitieuses** : plus de vagues et plus grosses, cartes qui évoluent en cours de partie (zones qui s'ouvrent, chemins qui se déplacent, événements). | P3 | Claude (design) → Codex | PT-30, perfs `SwarmSim` (500+ unités) | ✅ Longue route (15 vagues) et tiroirs qui s'ouvrent ; chapitres 4 et 6 |
| PT-61 | **Méta d'extension** : agrandir le terrain vers les zones bloquées (la table) débloque des bonus créatifs (nouveaux bâtiments, décors, règles). | P3 | Claude (design) → Codex + Gemini | PT-55, PT-60 | ✅ 4 paliers créatifs par extensions posées |
| PT-62 | **Campagne** : progression principale guidée par l'histoire ; choix libre de la carte et défi du jour débloqués après N niveaux ; plusieurs difficultés par carte. | P3 | Claude → Codex | PT-63, PT-64 | ✅ T12a : 6 chapitres, libre et défi après le chapitre 3, 3 difficultés |
| PT-63 | **Déblocage progressif / anti-spoil** : on commence avec les bases ; certains contenus totalement cachés (surprise), d'autres grisés avec cadenas (envie de grinder). | P3 | Claude (plan de déblocage) → Codex | `Progression`, PT-33 | ✅ T12a : améliorations masquées ou cadenassées selon le chapitre ; anciens joueurs épargnés |
| PT-64 | **Lore** : bible `docs/lore.md` écrite en même temps que chaque feature (histoire claire mais pas simpliste, easter eggs, foreshadowing). | P3 | Claude | chaque feature ajoutée | ✅ v1 `docs/lore.md` |
| PT-65 | **Validation croisée multi-IA du lore** (cohérence écrite, cohérence avec le gameplay, originalité, surprise) à chaque jalon. | P3 | Gemini (`adversarial_review`) + Codex (relecture) | PT-64 | ✅ relectures Gemini + Codex intégrées (à refaire à chaque jalon) |

## Règles transverses (s'appliquent à toutes les lignes)
- **R1 — Hyper3D d'abord** : modèles et animations passent par Hyper3D ; rien n'est modélisé ou animé à la main ou par calcul,
  sauf (a) les ajouts des niveaux intermédiaires, (b) quand nos maths donnent objectivement mieux (ex. engrenages qui s'engrènent),
  (c) blocage technique concret (ex. animation générée inexploitable). Chaque exception est notée dans `assets/CREDITS_HYPER3D.md`.
- **R2 — 4 modèles Hyper3D maximum par élément**, réservés aux gros paliers (niv. 1 + 3 paliers d'évolution).
- **R3 — Détail sans surcharge** (Gemini) : avant chaque ajout, « puis-je ajouter un petit détail ici sans en faire trop ? ».
- **R4 — Audit UI** : s'il y a un doute, il n'y a pas de doute → corriger, sans créer de bug visuel (captures avant/après).
- **R5 — Une icône = un seul concept**, même thème et même DA pour toutes.
- **R6 — Mode bac à sable conservé** pour le prototype actuel ; la campagne (PT-62) viendra par-dessus, pas à la place.
- **R7 — Lore en continu** : chaque feature livrée ajoute ou ajuste une entrée de `docs/lore.md` (à partir de PT-64).

## Vérification ligne à ligne (brief → tâches)
| Brief | Point | Tâche(s) |
|---|---|---|
| §1 | Sentiers sans bord de route · horloge dos à la route · plein écran perdu · rotation disparue · proportions selon la langue | PT-01 · PT-02 · PT-03 · PT-04 · PT-05 |
| §2 | Audit UI au cas par cas (règle du doute) · textes désalignés / boutons mal placés · boutons bas gauche · assets couplés au texte + badge de quantité pointu | PT-10, R4 · PT-11 · PT-12 · PT-13 |
| §2 | Boutique repliable · boutique refondue + tuile en T · menu en jeu · HUD (ennemis restants, où regarder) · icônes d'abord, texte au survol | PT-14 · PT-15 · PT-16 · PT-17 · PT-18 |
| §2 | Charte d'icônes (même DA, unicité) · ressort, vie de l'horloge, vague à refaire | PT-20, R5 · PT-21 |
| §3 | Pipeline Hyper3D non fait · modèles ET animations · 4 modèles max / gros paliers / intermédiaires à la main · règle de fallback | PT-52 · PT-52, PT-53 · PT-51, R2 · R1 |
| §3 | Animations en priorité · effet « vide », micro-détails, règle d'équilibre · drapeaux d'extension trop faibles · table moche (non prioritaire) | PT-53 · PT-54, R3 · PT-55 · PT-56 |
| §4 | Zoom / dézoom · inclinaison | PT-40 · PT-41 |
| §5 | Benchmark web · stratégie > spam · déplacement (V0 gratuit, punition ensuite) · vraie pause entre vagues | PT-34 · PT-37 · PT-31 · PT-30 |
| §5 | Engrenages : incohérence du droit + identité par type · upgrades 3 à 10 niveaux · évolution visuelle 4 modèles · placement par rapport à la route | PT-35 · PT-50 · PT-51 · PT-36 |
| §5 | Pas de doublon par tirage · chance · craft enrichi · engrenages d'or plus exigeants | PT-32 · PT-38 · PT-39 · PT-33 |
| §6 | Runs plus grandes, maps qui évoluent · méta d'extension et bonus créatifs · bac à sable OK pour le proto · campagne, choix libre et Daily après N niveaux, difficultés | PT-60 · PT-61 · R6 · PT-62 |
| §6 | Déblocage progressif (caché + cadenas) · lore pensé avec chaque feature, pas simpliste, easter eggs, foreshadowing · validation croisée multi-IA | PT-63 · PT-64, R7 · PT-65 |

## Ordre d'exécution (autonomie)
PT-01→05 (commit) · PT-04/31 · PT-14/16/12 · PT-40/41 · PT-30/32 · PT-17 · PT-10 (Gemini, en parallèle) → PT-11/13 ·
PT-20/21 (Gemini, en parallèle) → PT-15/18 · PT-34 → PT-35/36/37/38 · PT-33 · puis moyen terme (PT-50 → 51/52/53, 54, 55).
Ce qui exige Carlos : validation des images avant toute génération Hyper3D (une seule demande groupée), test Windows, ressenti.

---

# Après playtest 2 (brief de Carlos du 2026-11-27)

**Cap game design (règle R8, prioritaire sur toutes les autres)** : *Rouages devient un vrai puzzle / casse-tête
tactique où chaque placement et chaque synergie comptent. Fini le spam sans réfléchir.* Chaque tâche ci-dessous est
jugée à cette aune : une mécanique qui récompense le nombre plutôt que la réflexion est à revoir.

**Lecture** : identifiant `P2-xx` (repris dans les fiches et les commits), priorité (**P0** bloquant, **P1** court terme,
**P2** moyen terme, **P3** long terme), responsable, dépendances, état. Responsables : **Claude** (architecture, logique,
game design, équilibrage, relecture) · **Codex** (code délégué par fiche) · **Gemini** (= Antigravity, Gemini 4 Neon :
icônes, DA, Blender, décor, borné à `assets/` et `art_refs/`) · **Hyper3D** (modèles et animations, via Carlos sur le
site) · **Carlos** (test Windows, validation d'images, ressenti). Le relecteur n'est jamais le producteur.
Les 3 captures citées par Carlos ne sont pas arrivées : Claude reproduit ces écrans (`art_refs/playtest2/`).

## Court terme — §1. Bugs critiques, perf Windows, mécaniques (P0)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| P2-01 | **Jouets « plots » dans les virages des cartes en S** : des jouets restent immobiles loin de la sortie. Causes : la garde (`garde_ratio` 0,55) gèle tout jouet posé au-delà, même quand les ennemis l'ont dépassé ; les culs-de-sac du chemin (anciennes entrées fermées par une extension) attirent des jouets qui n'y croisent jamais personne ; les jouets au corps à corps ignorent les volants sans bouger. Correctif : pendant une vague, un jouet sans cible marche **par la route** vers l'ennemi qu'il peut frapper le plus proche (il ne dépasse sa garde que pour revenir vers l'horloge) ; les embranchements ne mènent qu'aux routes qui ont une entrée. | P0 | Claude | `swarm_sim.gd`, `champ_flux.gd`, tests || ✅ pistes vers l'ennemi + culs-de-sac (tests garde) |
| P2-02 | **Spawn progressif** : rejet du « remontage » en rafale. Pause = zéro jouet, zéro production ; au lancement, chaque atelier repart de zéro et sort ses jouets **un par un** (les survivants rentrent à l'atelier à la fin de la vague). Rééquilibrage au banc. | P0 | Claude | `partie.gd`, `production.gd`, `banc_equilibrage.gd`, `regles.tres` || ✅ cadence ×1,83, 5 s avant le 1er ennemi ; banc moyen V5-V8, parfait 0-2 PV |
| P2-03 | **Connexion morte devant l'horloge** : le port de l'horloge qui donne sur la route est fermé (la porte n'est pas une prise d'engrenage) ; la traversée d'une route devient le rôle du Pont (P2-47). | P0 | Claude | `plateau.gd` (ports de l'horloge), visuel des dents || ✅ port fermé (test plateau) |
| P2-04 | **Surchauffe Windows** : profil CPU/GPU (FPS non bridés, VSync, ombres temps réel, SSAO, draw calls, boucles lourdes) ; correctifs par défaut (cap à 60 FPS, VSync active, pas de rendu inutile dans les menus). | P0 | Claude | `project.godot`, `ambiance_plateau.gd`, `nuee_visuel.gd` || ✅ 60 images/s par défaut, 15 en arrière-plan ; mesuré : goulot processeur (~8 ms/image) |
| P2-05 | **Options graphiques / performance** : cap de FPS (30 / 60 / 120 / illimité), VSync, qualité des ombres, effets (SSAO, lueur, particules), échelle de rendu ; appliqués au lancement et en direct, enregistrés dans `reglages.cfg`. | P0 | Claude | P2-04, `options.gd/.tscn`, autoload `Fenetre` || ✅ onglet Graphismes + 3 préréglages |
| P2-06 | **Faux positifs antivirus Windows** : `.pck` séparé de l'`.exe` (pas embarqué), métadonnées d'export (éditeur, version, description, copyright), icône `.ico`, pas de console ; note de test pour Carlos (SmartScreen sans signature de code reste possible : expliquer pourquoi). | P0 | Claude → Carlos (test PC) | `export_presets.cfg`, `assets/icone.ico` || ✅ export prêt ; **test PC Carlos** |
| P2-07 | **Coffre qui plantait** dès qu'une carte rare sortait (style lu hors de l'arbre de scène → seule 1 carte sur 3 affichée), découvert en reproduisant les captures. | P0 | Claude | `hud.gd` | ✅ |

## Court terme — §2. UI / UX et retours visuels précis (P1)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| P2-10 | **Ruban des titres** : police plus petite, centrage vertical calculé sur la bande rouge (pas sur l'image entière), vérifié par capture sur chaque écran et chaque langue. | P1 | Claude | `theme_rouages.tres`, `ruban_petit.png` || ✅ |
| P2-11 | **Écran titre refait** : composition nettement plus aboutie (colonne de boutons homogène, hiérarchie Jouer > reste, liens du bas en boutons icône, vitrine de l'horloge mieux posée). | P1 | Claude (+ Gemini si un asset manque) | P2-10, P2-12 || ✅ (vitrine à revoir) |
| P2-12 | **Bouton Établi** de la même largeur que les autres, compteur d'engrenages d'or **dans** le bouton. | P1 | Claude | icône monnaie méta (PT ouvert) || ✅ |
| P2-13 | **Réassignation des touches** dans les Options (liste des actions, clic puis touche, réinitialiser), enregistrée dans `reglages.cfg`. | P1 | Claude → Codex | InputMap, `options.gd` || ✅ autoload `Touches`, onglet Touches |
| P2-14 | **Réserve (bas gauche) plus fine** : bordures lourdes remplacées par un cadre fin (liseré laiton ou fond papier léger), cases plus petites. | P1 | Claude | `reserve_ui.gd/.tscn`, thème || ✅ |
| P2-15 | **Vignettes alignées et non rognées** dans la réserve (l'atelier était plus bas et coupé) : même cadre, même centrage pour toutes. | P1 | Claude | P2-14, `assets/ui/vignettes/` || ✅ vignettes recadrées |
| P2-16 | **Pastille de quantité** = simple rectangle aux bords arrondis (bois/laiton, sans double bordure), dessinée en `StyleBoxFlat` : nette à toute taille, zéro rendu générique. | P1 | Claude | thème || ✅ |
| P2-17 | **Choix d'items (tirages, coffres)** : seulement le nom (et la rareté par la couleur du cadre) ; tout le détail en infobulle au survol. | P1 | Claude | `hud.gd` (cartes) || ✅ |
| P2-18 | **Images des cartes non rognées** : l'image occupe tout le cadre en gardant ses proportions (`KEEP_ASPECT_CENTERED`). | P1 | Claude | P2-17 || ✅ |
| P2-19 | **Zéro défilement** : quand il y a beaucoup de choix, la grille se recalcule (colonnes et taille des cartes) pour tout faire tenir dans la fenêtre. | P1 | Claude | P2-17 || ✅ |
| P2-20 | **Panneau contextuel en icônes** : cap d'unités, dégâts, vitesse, prix de revente en icône + valeur ; détails au survol des icônes. | P1 | Claude | icônes existantes (`REGISTRE.md`), P2-33 || ✅ |
| P2-21 | **Portée visible** des tourelles (et des jouets à distance) : anneau au sol à la pose, à la sélection et au survol. | P1 | Claude | `pose_controleur.gd`, `plateau_visuel.gd` || ✅ tourelles |
| P2-22 | **Chasse au texte continue** + distinction des éléments du plateau (silhouettes, couleurs de toit par famille, socles). | P1 | Claude + Gemini (icônes) | P2-17, P2-20 | |

## Moyen terme — §3. Gameplay puzzle, anti-spam, craft, nouvelles pièces (P1-P2)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| P2-30 | **Lance-billes rééquilibrés** (fin du « tout lance-billes ») : moins de PV et de cadence, plus chers, et contrés par la carapace (P2-31). | P1 | Claude (banc) | P2-02, P2-31 || ✅ PV 6, dégâts 5, cadence 0,45, prix 26 |
| P2-31 | **Armure fixe** : `UniteDef.armure` retire un montant fixe à chaque coup (plancher 1) ; le cuirassé devient « à carapace » (moins de PV, grosse armure) : il punit les tirs faibles et nombreux, et récompense mortier, canon et corps à corps améliorés. Affiché en icône (bouclier) dans l'aperçu de vague. | P1 | Claude | `unite_def.gd`, `swarm_sim.gd`, `tourelles.gd`, banc || ✅ armure 4 (corps à corps : moitié), cuirassé 32 PV ; icône `armure.png` prête |
| P2-32 | **Variété d'ennemis** : au moins 2 ennemis-énigmes de plus (ex. fouisseur qui passe sous les jouets ; porte-bouclier qui protège ses voisins des tirs ; kamikaze qui éclate sur les groupes serrés), chacun avec un contre lisible. | P2 | Claude (design) → Codex | P2-31 | |
| P2-33 | **Plafond par bâtiment** : vérifier puis rendre le plafond vraiment individuel (aujourd'hui 15 × ateliers, partagé) ; affiché dans le panneau (P2-20). | P1 | Claude | `production.gd`, `swarm_sim.gd` (origine des jouets) || ✅ plafond individuel (`SwarmSim.effectif`) |
| P2-34 | **Animations des tourelles** : visée qui pivote vers la cible, recul au tir, ressort qui se comprime (procédural en attendant Hyper3D, R1 exception (c) notée). | P1 | Claude | `plateau_visuel.gd`, PT-53 || ✅ visée + recul procéduraux |
| P2-35 | **Revente depuis la réserve** : bouton/icône « revendre » visible sur chaque pièce de la réserve (prix affiché), plus seulement le clic droit caché. | P1 | Claude | `reserve_ui.gd`, `Run.demonter` || ✅ bouton au survol |
| P2-36 | **Rareté dans les tirages** (pas seulement les coffres) + **la chance agit sur ces tirages** ; cadre coloré par rareté. | P1 | Claude | `draft.gd`, `regles.tres` (pioche) || ✅ pioche avec raretés + chance |
| P2-37 | **Craft utile** : boutique moins rentable, recettes plus rentables et **objets exclusifs au craft** (introuvables en boutique), dont le Pont et le Générateur. | P1 | Claude | P2-38, P2-39, `data/recettes/` || ✅ boutique +20-50 %, croix en 2 droits, 3 recettes exclusives |
| P2-38 | **Le Pont** (Épique, exclusif tirage/coffre/craft) : posé sur une case de route, il fait passer l'énergie par-dessus, vers l'herbe d'en face (ex. îlot vert isolé de la carte 3). | P1 | Claude (logique) + Gemini (modèle) | `plateau.gd`, `energie.gd`, `pose_controleur.gd` || ✅ Épique, pose sur route (modèle Gemini) |
| P2-39 | **Le Générateur autonome** (Rare) : alimente une zone sans lien avec l'horloge, mais limité à N pièces (2 au niveau 1, +1 par amélioration). | P1 | Claude (logique) + Gemini (modèle) | `energie.gd`, P2-50 améliorations || ✅ capacité 2 (+1/niveau), modèle Gemini |
| P2-40 | **Beaucoup plus de contenu à débloquer** : nouvelles pièces (Pont, Générateur, + 3 à 5 pièces de synergie), nouvelles améliorations d'Établi, cosmétiques de plateau ; plan de déblocage par chapitre. | P2 | Claude (design) → Codex + Gemini (vignettes) | P2-50 | |

## Moyen / long terme — §4. Campagne, modes, maps, tutoriel, lore BD (P2-P3)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| P2-50 | **Bâtiments débloqués par chapitre** : pool de départ réduit (soldats + engrenages simples), chaque chapitre ajoute un bâtiment, annoncé clairement au début du chapitre (« Nouveau : … » avec vignette). | P1 | Claude | `ChapitreDef`, `Progression`, `draft.gd`, boutique || ✅ `ChapitreDef.debloque`, fiche « Nouveau ! » |
| P2-51 | **Difficile optionnel par chapitre** : finir un chapitre en Normal débloque son mode Difficile (plus de loot : engrenages d'or ×1,5, coffre en plus) ; aucun blocage pour passer au chapitre suivant. | P1 | Claude | `Progression`, menu de campagne || ✅ ligne « Chapitre N en Difficile » (★ si fait) |
| P2-52 | **Mode libre conservé** avec tous les bâtiments (test libre). | P1 | Claude | P2-50 || ✅ |
| P2-53 | **Bac à sable / test infini** : tout débloqué, ressources infinies, vagues à la demande, aucun effet sur la progression. | P1 | Claude | `Run`, menu || ✅ « Mode : Bac à sable » |
| P2-54 | **Pas de carte répétée après le chapitre 3** : nouvelles cartes (au moins 3) et nouveaux ennemis par chapitre. | P2 | Claude (dessin des cartes) | P2-32, P2-55 || 🟡 3 cartes neuves (Jardin d'hiver, Boîte à musique, Grand atelier) ; nouveaux ennemis : P2-32 |
| P2-55 | **Cartes plus grandes, détaillées et vivantes** (décor par chapitre, animations d'ambiance, budget de perf respecté). | P2 | Gemini (décor) + Claude (intégration) + Hyper3D | PT-54, P2-04 | |
| P2-56 | **Chemins qui évoluent par segments** : extensions de formes variées (segments longs, L, boucles), au-delà du bloc 3×3 posé un par un. | P3 | Claude (design + `Extension`) | P2-54 | |
| P2-57 | **Tutoriel réintégré au bon moment** : il était masqué chez Carlos (`tutoriel.vu`), il démarre désormais au chapitre 1 de la campagne (et reste accessible depuis l'aide). | P1 | Claude | `tutoriel.gd`, campagne || ✅ revient au chapitre 1 tant qu'il n'est pas fini |
| P2-58 | **Lore en BD** (façon Plants vs. Zombies) : 3 à 4 cases illustrées au début de chaque chapitre, très peu de texte (bulles courtes). | P3 | Claude (scénario, cases) → Gemini (images) | `docs/lore.md`, quota Gemini | |

## Restes du playtest 1 (toujours ouverts)
| ID | Tâche | Qui | Bloqué par |
|---|---|---|---|
| PT-51 | Modèles Hyper3D des paliers d'évolution (lot 2 : bâtiments) | Hyper3D + Gemini | images du lot 2 à faire |
| PT-52 | 7 images de référence du lot 1 → validation Carlos → génération | Gemini → Carlos → Hyper3D | ✅ validées par Carlos, générées par Claude sur le site (4 crédits), allégées et en jeu |
| PT-53 | Animations générées (marche, tir, ateliers, horloge) | Hyper3D + Gemini | PT-52 |
| PT-54 | Micro-décors 3D | Gemini | quota Gemini |
| PT-11b | 2 icônes : monnaie méta, « assembler » | Gemini | ✅ livrées (+ 6 icônes de stats) |

## Vérification ligne à ligne (brief 2 → tâches)
| Brief | Point | Tâche(s) |
|---|---|---|
| Directive | Lire 2-3 fois, 100 % des points, Court/Moyen/Long, priorités, responsables, captures | cette section, `art_refs/playtest2/` |
| Cap | Vrai puzzle / casse-tête, chaque placement et synergie comptent, fin du spam | R8, P2-30 à P2-40 |
| §1 | Pathfinding / IA bloquée sur cartes en S, jouets « plots » dans les virages éloignés | P2-01 |
| §1 | Spawn : pas de rafale au lancement · temps mort sans spawn · départ de zéro, un par un | P2-02 |
| §1 | Connexion morte devant l'horloge : supprimer ou mécanique utile | P2-03 (+ P2-38) |
| §1 | Surchauffe Windows : profiler CPU/GPU (FPS, VSync, ombres, draw calls, boucles) | P2-04 |
| §1 | Options : cap FPS 30/60/120/illimité, VSync, ombres, effets | P2-05 |
| §1 | Antivirus : `.pck` séparé, métadonnées, icône d'export | P2-06 |
| §2 | Ruban : texte trop grand, mal centré | P2-10 |
| §2 | Écran titre plus abouti et pro · Établi même taille + compteur dans le bouton | P2-11 · P2-12 |
| §2 | Remapping des touches | P2-13 |
| §2 | Réserve : bordures trop massives · vignettes alignées, atelier coupé | P2-14 · P2-15 |
| §2 | Pastille : rectangle arrondi simple, DA artisanale, pas d'« AI slop » | P2-16 |
| §2 | Choix d'items : nom seul + infobulle · images non rognées · zéro scroll | P2-17 · P2-18 · P2-19 |
| §2 | Panneau d'amélioration : icônes + valeurs (cap, dégâts, vitesse, revente), détail au survol | P2-20 |
| §2 | Portée visible (pose, sélection, survol) | P2-21 |
| §2 | Chasse au texte, distinction visuelle du plateau | P2-22 |
| §3 | Trop de spam, répétitif (manque de maps et d'ennemis) | R8, P2-32, P2-54 |
| §3 | Lance-billes trop forts · ennemi à carapace (réduction fixe par coup) | P2-30 · P2-31 |
| §3 | Cap d'unités par bâtiment · animations des tours | P2-33 · P2-34 |
| §3 | Revente depuis l'inventaire | P2-35 |
| §3 | Rareté sur les choix de tirage · chance qui agit dessus | P2-36 |
| §3 | Craft : boutique trop rentable, recettes rentables et exclusives | P2-37 |
| §3 | Pont (Épique/Légendaire, non achetable) · Générateur autonome (limite stricte, améliorable) | P2-38 · P2-39 |
| §3 | Beaucoup plus de contenu / loot | P2-40 |
| §4 | Bâtiments débloqués par chapitre, annoncés · pool de départ réduit | P2-50 |
| §4 | Difficile débloqué par le Normal, plus de loot, 100 % optionnel | P2-51 |
| §4 | Mode libre conservé · bac à sable infini | P2-52 · P2-53 |
| §4 | Pas de carte répétée après ch. 3, plus d'ennemis · cartes plus grandes et vivantes · chemins par segments | P2-54 · P2-55 · P2-56 |
| §4 | Tutoriel réintégré · lore en BD, très peu de texte | P2-57 · P2-58 |
| Restes | PT-51 à 54, 2 icônes | tableau « Restes du playtest 1 » |

## Ordre d'exécution (autonomie)
Lot A (§1) : P2-01, 02, 03, 33 → banc → P2-04, 05, 06 → commit · Lot B (§2) : P2-10, 14, 15, 16, 17, 18, 19 → P2-12, 11,
20, 21, 35 → P2-13 · Lot C (§3) : P2-31, 30, 36, 37, 38, 39, 34 → banc · Lot D (§4) : P2-50, 51, 53, 52, 57 → P2-54, 32,
40 → P2-56, 55, 58 · PT ouverts dès que le quota Gemini revient. Builds Mac/Windows à la fin des lots A, B et C.
