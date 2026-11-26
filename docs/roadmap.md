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
| PT-10 | **Audit UI strict écran par écran** (titre, établi, options, HUD, draft, coffre, boutique, réserve, pause, fin, tutoriel, infobulles) : liste de défauts avec captures, règle « s'il y a un doute, il n'y a pas de doute ». | P1 | Gemini (audit) → Claude (tri) | captures fournies par Claude (Gemini ne lance pas le jeu) | ⬜ |
| PT-11 | Corrections de l'audit : **textes alignés sur leurs fonds**, boutons bien placés, aucune régression visuelle (captures avant/après). | P1 | Codex (scènes) + Claude (relecture) | PT-10, PT-05 | ⬜ |
| PT-12 | **Boutons en bas à gauche contenus dans leur panneau** (marges internes du 9-patch respectées, plus de chevauchement de la bordure). | P1 | Claude | `reserve_ui.tscn`, `theme_rouages.tres` | ✅ |
| PT-13 | **Badge de quantité des choix redessiné** (abandon de l'étiquette à pointe gauche) + revue de chaque asset couplé à du texte. | P1 | Gemini (asset) + Claude (intégration) | PT-10 | ✅ |
| PT-14 | **Boutique repliable** : bouton ouvrir/fermer (fermée par défaut pendant les vagues). | P1 | Claude | `hud.gd` | ✅ |
| PT-15 | **Boutique refondue** : grille d'icônes + prix, détail au survol, **tuile de chemin en T** ajoutée (et croix), tri par catégorie. | P1 | Claude (contrat) → Codex | PT-14, PT-17 (icônes) | ⬜ |
| PT-16 | **Vrai menu en jeu** : bouton ⚙ toujours visible → pause, reprendre, options, aide (revoir le tutoriel), recommencer, retour au menu, quitter. | P1 | Claude | `menu_pause.tscn`, `hud.tscn` | ✅ |
| PT-17 | **HUD clair** : ennemis restants / total de la vague, barre de progression de la vague, flèches au bord de l'écran vers les entrées actives et vers les combats, alerte quand l'horloge est touchée. | P1 | Claude (logique : compteurs dans `DirecteurVagues`/`SwarmSim`) → Codex (affichage) | PT-21 (icônes) | ✅ |
| PT-18 | **« Icônes au premier plan, texte au survol »** : remplacer un maximum de libellés par des icônes, infobulles papier au survol (nom, effet, coût, raccourci). | P1 | Codex (infobulles génériques) + Gemini (icônes) | PT-20, PT-21 | ⬜ |
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
| PT-33 | **Engrenages d'or plus exigeants** : courbe de gain revue (moins par vague tenue, bonus de fin selon la difficulté) et prix des améliorations rehaussés, mesurés sur « parties pour tout débloquer ». | P1 | Claude | `regles.tres`, `data/ameliorations/` | ⬜ |
| PT-34 | **Benchmark game design TD** (recherche web documentée : prise de décision, rythme, gestion de l'espace, synergies, contre-jeu) → `docs/benchmark_td.md` avec une liste d'améliorations concrètes classées. | P1 | Claude (+ Gemini `web_lookup` pour sources) | — ; nourrit PT-35 à PT-39 | ⬜ |
| PT-35 | **Différenciation des engrenages** : supprimer l'incohérence du droit (une case de plus pour rien) et donner à chaque type une identité (ex. droit = démultiplicateur qui accélère l'atelier au bout, T = répartiteur, croix = moyeu qui partage sa force, coude = bon marché). | P1 | Claude (design + logique `Energie`) → Codex | PT-34 | ⬜ |
| PT-36 | **Positionnement tactique par rapport à la route** : bonus selon la place (ex. tourelle en bord de route = +dégâts, atelier en bord de route = jouets plus vite au front, case de carrefour = +portée), affiché en aperçu de pose. | P1 | Claude → Codex | PT-34, PT-17 | ⬜ |
| PT-37 | **Stratégie > spam** : mécaniques anti-spam (rendements décroissants par atelier identique adjacent, synergies de voisinage, ennemis qui contrent la masse : volants, fouisseurs, kamikazes de zone), choisies d'après PT-34. | P1 | Claude (design) → Codex | PT-34, PT-35, PT-36 | ⬜ |
| PT-38 | **Chance** : stat de chance qui augmente la probabilité des raretés supérieures (porte-bonheur en boutique, vague sans dégât, amélioration méta « Trèfle »), affichée en icône. | P1 | Claude → Codex | PT-32, PT-21 (icône) | ⬜ |
| PT-39 | **Craft enrichi** : nouvelles recettes simples (fusionner 3 pièces identiques = pièce de niveau supérieur, démonter pour récupérer des ressorts), sans alourdir l'interface. | P2 | Claude (design) → Codex | PT-50 (niveaux) | ⬜ |

## Moyen terme — améliorations, DA, Hyper3D, vie du plateau (P2)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| PT-50 | **Tout bâtiment et tout engrenage améliorable** : 3 niveaux minimum, jusqu'à 10 si le design le justifie (`PieceDef.niveaux`), coût croissant, effet lisible au survol. | P2 | Claude (contrat, équilibrage au banc) → Codex | PT-35, PT-31 | ⬜ |
| PT-51 | **Évolution visuelle des niveaux** : paliers majeurs (niv. 1 puis 3 gros paliers) = modèle Hyper3D dédié (**4 maximum par élément**) ; niveaux intermédiaires = ajouts faits main sur le modèle du palier (pièces, matériaux, ornements, effets). | P2 | Hyper3D (paliers) + Gemini (ajouts Blender) | PT-50, PT-52 | ⬜ |
| PT-52 | **Pipeline Hyper3D** : images de référence validées par Carlos → génération → nettoyage Blender → intégration. Budget (43 crédits restants) : palier 1 de 11 éléments (2 ateliers, 3 tourelles, 4 ennemis, 2 jouets) = 11 ; paliers 2-4 des 5 bâtiments = 15 ; horloge paliers = 3 ; décor maître (marqueur d'extension, boîte à musique, moulin) = 4 ; réserve d'essais = 10. Engrenages : modelés par calcul (dents qui doivent s'engrener → les maths battent la génération). | P2 | Claude (images, prompts, comptes) → Carlos (connexion web si l'API refuse) → Hyper3D | PT-20 (charte), `assets/CREDITS_HYPER3D.md` | ⬜ |
| PT-53 | **Vraies animations** (en tête du moyen terme : demandé en priorité) : marche des insectes et des jouets, tir des tourelles, ateliers qui travaillent, horloge (balancier, aiguilles). Via Hyper3D (rig + animation) ; repli procédural seulement si l'animation générée est inexploitable (blocage noté). | P2 | Hyper3D + Gemini (Blender) → Claude (intégration) | PT-52 | ⬜ |
| PT-54 | **Plateau vivant, jamais surchargé** : micro-détails d'ambiance (papillons, brins d'herbe au vent, fumée de vapeur, oiseaux-jouets, outils d'horloger sur la table, poussière dans la lumière). Règle pour chaque ajout : « puis-je ajouter un petit détail ici sans en faire trop ? ». | P2 | Gemini (assets) → Claude (intégration, budget de perf) | PT-10 | ⬜ |
| PT-55 | **Extension de territoire plus marquante** : remplacer les fanions par un élément fort (ex. pancarte de chantier en bois + boîte de pièces à déballer, tracé en pointillés du futur chemin). | P2 | Gemini (asset) + Claude (aperçu) | PT-01 | ⬜ |
| PT-56 | Texture de la table autour du plateau à refaire (non prioritaire). | P3 | Gemini | — | ⬜ |

## Long terme — modes, méta, onboarding, lore (P3)
| ID | Tâche | Prio | Qui | Dépendances | État |
|---|---|---|---|---|---|
| PT-60 | **Runs plus ambitieuses** : plus de vagues et plus grosses, cartes qui évoluent en cours de partie (zones qui s'ouvrent, chemins qui se déplacent, événements). | P3 | Claude (design) → Codex | PT-30, perfs `SwarmSim` (500+ unités) | ⬜ |
| PT-61 | **Méta d'extension** : agrandir le terrain vers les zones bloquées (la table) débloque des bonus créatifs (nouveaux bâtiments, décors, règles). | P3 | Claude (design) → Codex + Gemini | PT-55, PT-60 | ⬜ |
| PT-62 | **Campagne** : progression principale guidée par l'histoire ; choix libre de la carte et défi du jour débloqués après N niveaux ; plusieurs difficultés par carte. | P3 | Claude → Codex | PT-63, PT-64 | ⬜ |
| PT-63 | **Déblocage progressif / anti-spoil** : on commence avec les bases ; certains contenus totalement cachés (surprise), d'autres grisés avec cadenas (envie de grinder). | P3 | Claude (plan de déblocage) → Codex | `Progression`, PT-33 | ⬜ |
| PT-64 | **Lore** : bible `docs/lore.md` écrite en même temps que chaque feature (histoire claire mais pas simpliste, easter eggs, foreshadowing). | P3 | Claude | chaque feature ajoutée | ⬜ |
| PT-65 | **Validation croisée multi-IA du lore** (cohérence écrite, cohérence avec le gameplay, originalité, surprise) à chaque jalon. | P3 | Gemini (`adversarial_review`) + Codex (relecture) | PT-64 | ⬜ |

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
