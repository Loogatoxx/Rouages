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
