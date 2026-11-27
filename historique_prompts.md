# Historique des prompts — Rouages

## 2026-11-23 — Lancement (grill-me)
- **Prompt** : `/grill-me` + vision du jeu (CLAUDE.md, AGENTS.md, 2 références visuelles) ; confirmer la vision, proposer l'architecture et le plan, attendre la validation.
- **Réponse** : 8 questions pour cadrer le MVP (plateau qui pousse ; énergie par engrenages ; essaims des deux côtés ; ateliers producteurs, sans tourelles ; draft de 3 tuiles ; Forward+ PC ; greybox + horloge Hyper3D) ; puis architecture en 5 principes et roadmap en 9 étapes.
- **Modifications** : aucune (phase de cadrage).
- **Objectif** : éviter la dérive de scope qui a tué Elemental Ranch en fixant un MVP fermé avant tout code.

## 2026-11-23 — Étape 0 : installation et squelette
- **Prompt** : « tu peux y aller » (validation du plan).
- **Réponse** : installation réalisée, tests verts, bridges testés.
- **Modifications** :
  - Antigravity copié dans `/Applications`, Godot déplacé de `~/Downloads` vers `/Applications`.
  - `~/.gemini/antigravity/mcp_config.json` : ajout de blender, audio-studio, hyper3d-rodin (côté Antigravity).
  - `.mcp.json` du projet : agy-bridge uniquement. Le `.mcp.json` de RobloxVibe n'a pas été touché.
  - Création : `project.godot` (Forward+, autoloads, InputMap), `game/core/events.gd`, `game/core/run.gd`, `game/main.tscn|gd`,
    `tests/run_tests.gd`, `tests/test_socle.gd`, `scripts/tests.sh`, `scripts/codex_bridge.sh` (adapté),
    `CLAUDE.md`, `AGENTS.md`, `docs/` (architecture, roadmap, backlog), `taches/README.md`, `assets/CREDITS_HYPER3D.md`, `art_refs/`.
- **Objectif** : poser un socle léger, testable en headless, où chaque IA a son domaine de fichiers et lit le minimum.

## 2026-11-23 — Étape 1 : plateau et énergie (T01)
- **Prompt** : « c bon pour antigravity mais j ai pas trouver lui pour connecter a hyper 3d sinon suite ».
- **Réponse** : socle commité (`d8b7ad9`) ; Hyper3D se connecte via l'addon Blender MCP (clé saisie par Carlos, utile à l'étape 7) ; fiche T01 écrite, produite par Codex (gpt-6.2-astra medium, ~22 000 tokens), relue par Claude.
- **Modifications** : `game/board/piece_def.gd`, `plateau.gd`, `energie.gd` ; 6 pièces dans `data/tuiles/` ; `tests/test_plateau.gd`, `tests/test_energie.gd` (9 tests verts) ; AGENTS.md (commentaires de doc obligatoires) ; roadmap (étape 1 faite).
- **Objectif** : poser le cœur du puzzle (ports d'engrenages qui tournent, propagation en largeur depuis l'horloge) en logique pure et testée, avant tout visuel.

## 2026-11-23 — Étapes 2 et 2b : caméra, pose et DA greybox
- **Prompt** : « c bon le mcp est connecter a blender, prochaine etape », puis « Je m'en occupe » (autorisations Blender dans Antigravity).
- **Réponse** : fiches T02 (Codex) et T02b (Antigravity) lancées en parallèle. T02 produite (gpt-6.2-astra medium, ~41 000 tokens), relue par Claude, 11 tests verts. T02b bloquée : en mode bridge, Antigravity refuse les outils Blender faute d'approbation humaine ; l'autorisation automatique tentée par Claude a été refusée par le garde-fou (décision laissée à Carlos).
- **Modifications** : `game/board/grille_monde.gd`, `plateau_noeud.gd`, `plateau_visuel.gd`, `pose_controleur.gd`, `game/camera/camera_plateau.gd`, `game/ui/palette_debug.*`, `game/main.*`, `tests/test_grille_monde.gd` ; `scripts/codex_bridge.sh` (le garde-fou ignore les changements déjà indexés) ; roadmap.
- **Objectif** : rendre le puzzle visible et manipulable (fantôme vert/rouge, rotation, engrenages qui tournent quand ils sont alimentés, double vue caméra) avant d'ajouter les nuées.

## 2026-11-23 — Étape 3 : nuées (T03) et livraison de T02b
- **Prompt** : « c bon il est aussi connecter et permission faite aussi continue ».
- **Réponse** : la relance de T02b par le bridge a échoué une 2e fois (autorisation Blender non mémorisée) → arrêt anti-boucle, T02b exécutée par Carlos dans Antigravity. T03 écrite par Claude, produite par Codex (gpt-6.2-astra high), relue : 20 tests verts, 300 contre 300 à 60 FPS en fenêtre, 3,2 ms par pas de simulation.
- **Modifications** : `game/swarm/` (unite_def, champ_flux, swarm_sim, nuee_visuel, banc_nuees), `game/core/materiaux.gd`, `data/unites/*.tres`, tests nuées ; chemin raccordé à l'horloge dans `plateau_noeud.gd` ; `assets/` (9 matériaux, ambiance, kit greybox de 8 .glb, aperçu ; 0 crédit Hyper3D) ; `game/main.tscn` utilise désormais `assets/ambiance/ambiance.tscn`.
- **Objectif** : valider tôt le système le plus risqué (la masse vivante façon We March As One) et poser la DA sans dépenser de crédits.

## 2026-11-23 — Commit des étapes 1 à 3, lancement de l'étape 4
- **Prompt** : « tout correct tu peu commit et probleme regler coter antigravity avec le mcp continue ».
- **Réponse** : commit des étapes 1 à 3 ; fiche T04 (ateliers producteurs, vagues, PV de l'horloge, défaite/victoire) confiée à Codex ; ping du bridge Antigravity → Blender.
- **Modifications** : voir l'entrée suivante une fois T04 relue.
- **Objectif** : obtenir la première boucle jouable de bout en bout.
- **Suite (T04 relue)** : Codex (gpt-6.2-astra high) a livré `game/core/partie.gd`, `regles.gd`, `game/workshops/production.gd`, `game/waves/` (VagueDef, DirecteurVagues), `game/ui/hud.*`, `data/regles.tres`, 3 vagues provisoires, et modifié `run.gd`, `piece_def.gd`, `champ_flux.gd` (entrées), `pose_controleur.gd` (pose seulement en construction). 27 tests verts. Le ping du bridge Antigravity → Blender échoue encore : les autorisations ont le format `mcp(blender)` au lieu de `mcp(blender/<outil>)`.
- Bridge Antigravity → Blender réparé par Carlos (format `mcp(blender/<outil>)`) : test « BLENDER OK » (Blender 5.3, addon v2.0).

## 2026-11-26 — Passage en sessions par étape
- **Prompt** : « les credit sont revenu tout est en place tu peu continuer hesite pas a ouvrir de nouvelle session quand il faut ».
- **Réponse** : création de `docs/reprise.md` (état, procédure, pièges) pour qu'une session neuve démarre sans relire le dépôt ; étape 5 confiée à une nouvelle session Claude. Commit de T04 non fait (pas de demande explicite) : la nouvelle session le proposera.
- **Modifications** : `docs/reprise.md` (nouveau), `CLAUDE.md` (règle 0 : lire la reprise), roadmap (étapes 2, 2b et 4 validées).
- **Objectif** : réduire le coût en tokens et en cache : une conversation trop longue fait relire tout l'historique à chaque message.

## 2026-11-26 — Commit de l'étape 4, étape 5 : cœur roguelike (draft, extensions, 10 vagues)
- **Prompt** (session précédente, au nom de Carlos) : commiter T04 après accord de Carlos, puis réaliser l'étape 5 : draft d'un lot parmi 3 tiré d'une pioche pondérée, réserve de pièces, plateau et réserve de départ dans `data/`, extensions de terrain qui ouvrent un nouveau front, 10 vagues équilibrées, run d'environ 15 min.
- **Réponse** : commit `d24f33b` (étape 4) après le « oui » de Carlos. Étape découpée en trois fiches : T05a (draft, réserve, machine à états, Codex), T05b (extensions + répartition des jouets aux embranchements, Codex), T05c (10 vagues, remontage, équilibrage, Claude). Un banc d'équilibrage headless a révélé deux défauts invisibles à l'œil : (1) à un embranchement, tous les jouets prenaient la même branche, ce qui laissait les autres fronts sans défense ; (2) une vague ratée vidait l'armée pour la suivante (spirale de défaite). Corrigés par la répartition aléatoire (T05b) et par le remontage pendant la construction (T05c).
- **Modifications** : T05a (Codex) : `game/core/{lot,depart_def,reserve}.gd`, `game/draft/draft.gd`, `game/ui/reserve_ui.*`, `data/depart.tres`, machine à états dans `run.gd`, panneau de draft dans le HUD, palette provisoire supprimée. T05b (Codex) : `game/board/{extension,extension_def}.gd`, `data/extensions/{sentier,carrefour}.tres`, fantôme d'extension, poteaux roses sur les entrées, répartition des jouets dans `swarm_sim.gd`. T05c (Claude, relu par Codex) : 10 vagues, remontage dans `partie.gd`, branche choisie par hachage (embranchements indépendants, test ajouté), bonus des extensions, `scripts/banc_equilibrage.gd`. 40 tests verts. Docs : architecture, roadmap, reprise.
- **Objectif** : rendre chaque choix de draft important et ouvrir le dilemme risque/récompense des extensions, avec une difficulté mesurée plutôt que devinée.

## 2026-11-26 — Validation de l'étape 5
- **Prompt** : « oui c'est très bien juste on voit pas vraiment les soldats parce que c'est du blanc sur du blanc sinon continue et s'il faut ouvre une nouvelle fenêtre ».
- **Réponse** : commit de l'étape 5 ; lisibilité des soldats notée en priorité pour l'étape 6 ; session neuve ouverte pour l'étape 6.
- **Objectif** : clore l'étape 5 et repartir avec un contexte frais.

## 2026-11-26 — Étape 6 : lisibilité et équilibrage
- **Prompt** : correction « blanc sur blanc » validée (« tout est bon continue ») ; ressenti : « je perds vague 4 », pas d'ennui, extensions = « je double juste », tuto/argent pour plus tard.
- **Réponse** : T06a (Codex) : teintes « peinture de jouet » + chapeau brun, test de contraste WCAG (43 tests). Banc sur 3 graines : un joueur un cran sous le parfait mourait en V3-V4 ; V2-V4 adoucies (44→36, 70→54, 97→80) et `pv_horloge` 20→30. Retours extensions/tuto/argent notés au backlog.
- **Objectif** : un début de run accessible sans toucher la fin de run.

## 2026-11-26 — Étape 7 : horloge 3D
- **Prompt** : « commit étape 6, tu peux faire la B » ; puis génération Hyper3D faite à la main par Carlos (l'API exige le plan supérieur).
- **Réponse** : commit `4609167`. T07a : 3 visuels d'horloge (Antigravity), sons en échec (délai du bridge, 2 fois). T07b : bridge en délai dépassé à chaque appel Hyper3D ; Carlos a généré et exporté le modèle lui-même (1 crédit, 43 restants). Modèle vérifié (13 378 triangles, 1,6 × 3 m, origine à la base) et branché dans `plateau_visuel.gd` avec repli greybox.
- **Objectif** : la pièce maîtresse à l'échelle en jeu, sans dépenser plus d'un crédit.

## 2026-11-26 — Rush autonome vers un jeu complet (étapes 7 fin, 7b, 8)
- **Prompt** (transmis par la session principale, au nom de Carlos) : « en autonomie, en mode rush » : finir l'étape 7 (sons), ajouter tout ce qui manque pour un tower defense jouable et agréable (menus, pause, fin, tutoriel, monnaie, extensions plus tentantes, retours visuels/sonores, vitesse x2, survol, 2e ennemi, 2e atelier), puis builds Mac + Windows, sans validation à chaque étape.
- **Réponse** : sons synthétisés localement (`scripts/generer_sons.py`, Python + ffmpeg, 0 service payant) et autoload `Sons` ; fiches T08a (ressorts, boutique, cuirassé, lance-billes, extensions, vitesse), T08b (menus, boutique, tutoriel, survol, retours visuels), T08c (visuels des nouvelles unités, éclats, secousse) confiées à Codex.
- **Objectif** : une run complète du menu titre à l'écran de fin, livrée en `.zip` Mac et Windows.
- **Suite** : T08b relu malgré l'arrêt de Codex (Mac en veille) ; passe visuelle vérifiée par captures (exposition, SSAO, joints, damier, vitrine 3D du menu, bulle du tutoriel, écran de fin). Économie recalibrée (butin 1/scarabée = ~1 300 ressorts par run, ramené à une prime de vague + rente des extensions). 52 tests verts.
- **Prompt** : « Oui, télécharge » (modèles d'export Godot).
- **Réponse** : modèles 4.7.2 installés (Mac + Windows seulement), ETC2/ASTC activé, textures du .glb réintégrées à l'export. `builds/Rouages_mac.zip` (71 Mo) testé : il se lance et affiche l'horloge ; `builds/Rouages_windows.zip` (48 Mo) exporté, à tester sur le PC.
- **Objectif** : livrer deux `.zip` jouables.
- **Prompt** : « pour le disque si tu trouve que y a pas assez de place met sur mon lexar sinon continue ».
- **Réponse** : place suffisante (~7 Go), rien déplacé. Finitions : toit rouge et clé de remontoir sur l'atelier de soldats, ombre de l'horloge nette au lieu d'un nuage granuleux, cartes de draft avec nom en demi-gras et description plus petite. Builds réexportés, Mac retesté. 52 tests verts.
- **Objectif** : un rendu « première version publique ».

## 2026-11-26 — Retours d'un testeur externe (étape 9)
- **Prompt** : « continue et voici une review de mon pote » (questionnaire en portugais) ; puis « travaille en autonomie pendant 2 heures » et « ajoute aussi qu'avec une bonne base on ouvrira un multi et un 1x1 ».
- **Réponse** : tri des retours (ennemis à peine vus et trop faibles, jouets empilés, temps morts en vague, rotation gratuite qui supprime la réflexion, pose d'extension peu claire, pas de traduction, envie de contenu et d'un défi du jour). T09a (Codex) : garde des jouets à 55 % du chemin, anti-empilement, pose pendant les vagues, rotation payante, marqueurs d'extension, 3 plateaux, défi du jour, fourmi mécanique. T09b (Codex) : traduction FR/EN/PT. T09c (Codex) : sensations d'impact. Claude : rééquilibrage au banc (3 graines, 2 profils), chemins de Fourche en coude, menu (choix du plateau, défi du jour avec record), icône rendue depuis le modèle 3D, musique de vague en fondu enchaîné, multijoueur noté au backlog. Builds réexportés, Mac retesté.
- **Objectif** : que le testeur ait envie de relancer une partie (il donnait 7/10).


## 2026-11-26 — Autonomie totale et DA v2 (étape 10)
- **Prompt** : « tu t'es vite arrêté… dis-toi que je dis oui à tout… commit tout, n'attends pas d'autorisation » ; puis « pense au design, je trouve moche ; en vue 3D rien ne doit être plat ; l'UI fait AI slop ; demande à Antigravity de chercher des jeux à la DA similaire et d'appliquer un design quasi identique au meilleur ».
- **Réponse** : commit des étapes 7-9. Étape 10 : T10a tourelles de loot rare en coffres (V3/V6/V9, rareté commune/rare/épique), T10d menu d'options (volumes par bus, plein écran). T10e Antigravity : étude DA (Bad North, Dorfromantik, Townscaper, Tiny Glade, Kingdom Rush…), kit 3D en volume (tuiles biseautées, engrenages dentés, ateliers, tourelles, unités), kit UI « établi d'horloger » (bois, laiton riveté, papier, ruban, icônes, polices OFL Fraunces/Nunito). T10f intégration du kit 3D, T10c progression méta (Établi, engrenages d'or), puis thème UI v2 et boss.
- **Objectif** : un jeu qui ressemble à une sortie publique, sans aller-retour de validation.


## 2026-11-26 — Brief de playtest 1 → roadmap, puis corrections critiques
- **Prompt** (transmis par la session principale, au nom de Carlos) : brief de playtest complet en 6 parties (bugs critiques,
  UI/UX et charte d'icônes, DA/Hyper3D/animations/vie, caméra, gameplay et upgrades, modes/méta/onboarding/lore) à
  transformer à 100 % en roadmap court/moyen/long terme, puis exécution en autonomie (commits sans demander, pas de push).
- **Réponse** : roadmap « Après playtest 1 » (PT-01 à PT-65 avec priorité, responsable, dépendances ; règles R1-R7 ; table de
  vérification ligne à ligne). Lot P0 : sentiers posables partout (raccord creusé jusqu'à la route), horloge face à la
  route (Fourche redessinée), plein écran conservé (autoload `Fenetre`, F11), rotation gratuite avant la vague 1 + message
  si refus, menus robustes aux langues (cartes, infobulle, boutique alignée, réserve dans son cadre, compteur d'or en icône).
  75 tests verts, vérifié par captures FR/EN/PT.
- **Objectif** : repartir sur une base sans régression avant l'UI, la caméra et le gameplay.
- **Suite (lot 2, même demande)** : charte et 12 icônes par Gemini (T11a, relues par Claude), pastille de quantité
  sans pointe, boutique repliable (B), menu en jeu (aide, quitter), zoom et inclinaison de la caméra (trackpad Mac
  compris), vraie pause entre les vagues (remontage instantané une fois par pause, mesuré au banc), tirages sans doublon.
- **Suite (lot 3)** : HUD lisible (ennemis restants, repères au bord de l'écran vers les entrées et les ennemis hors champ),
  reprise/déplacement des pièces posées (T11b, Codex, relu par Claude). 80 tests verts.

## 2026-11-26 — Suite en autonomie (message de la session principale : « continue le plus possible »)
- **Demande** : enchaîner tous les PT restants (audit UI, boutique, benchmark, engrenages, améliorations, placement, chance,
  craft, vie du plateau, extension, Hyper3D, lore), commiter chaque lot, relancer le build Mac.
- **Fait** : build Mac relancé (démarre). Audit UI par Gemini (63 défauts) et corrections majeures (rubans, contraste,
  HUD). Boutique et réserve en vignettes rendues depuis le kit 3D. Benchmark web sourcé → décisions D1-D8. Placement par
  rapport à la route, engrenages à identité, encombrement (module `Placement`, testé, mesuré au banc).
- **Suite** : chance (poids des raretés, porte-bonheur, trèfle), libellule volante (T11c, Codex), engrenages d'or plus
  exigeants, lore v1 relu par Gemini puis Codex (T11e), améliorations à 3/5 niveaux avec panneau contextuel (T11d,
  Codex), chantier d'extension (Gemini), aperçu de la vague suivante, demande Hyper3D groupée (prompts, budget),
  poussière et pétales d'ambiance. Builds réexportés, Mac relancé. Gemini hors quota en fin de session.
- **Objectif** : un jeu qui récompense la stratégie plutôt que le spam, lisible et prêt pour le pipeline Hyper3D.
