# Reprise — à lire en premier par toute nouvelle session Claude

Ce fichier remplace la lecture du dépôt. Ensuite : `docs/roadmap.md` (prochaine étape), `docs/architecture.md`
(principes, signaux, contrat d'assets) et `docs/backlog.md` (ne rien coder de ce qui y figure avant la fin de la roadmap).

## État (mis à jour le 2026-11-27, 20 h, après playtest 3, autonomie totale)
- **Après playtest 3** : cap « Tenir la ligne » (`docs/game_design_p3.md`, § 9 pour les réglages retenus et les
  mesures), roadmap § « Après playtest 3 » (P3-xx).
  **Lots 1 et 2 faits et commités** : chemins stricts, Pont, têtes de tourelles, Générateur légendaire ; énergie de
  l'Horloge en dents, postes de garde (fanions, choix à la souris), ateliers à 0,5 jouet/s, vagues par paquets,
  joueur automatique à 4 styles, banc refait. 137 tests.
  **Suite** : lot 3 = P3-26 (carillon qui ralentit, icônes de rôle), P3-27 (coup de carillon), P3-29 (impacts),
  P3-28 (film d'une vague, durée des vagues : 85 s en V4, 130 s en V10) ; lot 4 = P3-30 (menu en liste + aperçu),
  P3-31 (aide traduite) ; lot 5 = cadrage, décor, vie ambiante, cartes à mécaniques.
  **Attend Carlos** : valider `art_refs/hyper3d/lot2/tourelle_carillon.png` et `tourelle_mortier.png` avant la
  génération Hyper3D ; tester les builds (Windows surtout) ; jouer Boîte à musique et Grand atelier (le joueur
  automatique ne sait pas poser de Pont).
- **GitHub** (demande de Carlos, 2026-11-27) : dépôt privé `https://github.com/Loogatoxx/Rouages`, distant `origin`,
  branche `main`. **Pousser après chaque lot commité et testé** (`git push`), jamais de `--force`. Avant un push :
  `git ls-files | grep -iE "\.env|keystore|\.jks|\.apk|\.aab"` doit rester vide. Ses carrés verts comptent (e-mail de
  l'IPT relié au compte) ; pour les voir sur son profil public, c'est à lui d'activer « Private contributions ».
- **Joueur automatique** (le juge de l'équilibrage) : sans fenêtre
  `Godot --headless --path . --script res://scripts/joueur_auto.gd -- --fenetre <dossier> <plateau 0-5> <spam|tactique> <graine> 0`
  (30 s par partie ; styles `spam`, `masse`, `moyen`, `tactique` ; `CARTE=1` pour le plan du plateau) ; avec captures :
  `--windowed --resolution 1600x900` et `1` à la place du `0` final (×4, `VITESSE=1` pour filmer avec `--write-movie`).
  Références : avant refonte, spam 6/6 avec 150 à 260 jouets ; après le lot 2, spam 0/6, masse 0/9, moyen 3/12,
  tactique 9/12. Toujours 3 graines ou plus : le résultat bascule vite (une ligne tient ou cède).
- **Pièges du lot 1** : `Engine.time_scale` multiplie le pas physique (multiplier aussi `physics_ticks_per_second`) ;
  `trait` est un mot réservé en GDScript ; `surface_get_arrays` renvoie des tableaux vides en `--headless` pour les
  maillages `.res` (la découpe des tourelles ne se teste qu'avec une fenêtre) ; le banc a été refait au lot 2 (`parfait` / `moyen`, plan fixe sur Prairie) ;
  Codex : limite d'usage atteinte à 17 h 30 (fiche de relecture prête : `taches/T14a_relecture_playtest3_lot1.md`).

## État précédent (2026-11-27 après-midi)
- **Après playtest 2** : roadmap `docs/roadmap.md` § « Après playtest 2 » (P2-01 à P2-58, règle R8). Faits et commités :
  lots A (bugs, spawn progressif, perf, export), B (UI : ruban, cartes, réserve, titre, panneau en icônes, portée),
  C (armure, Pont, Générateur, craft exclusif, raretés des tirages, tourelles animées), D (bâtiments par chapitre,
  Difficile optionnel, bac à sable, tutoriel), touches réassignables, 3 nouvelles cartes et 2 ennemis-énigmes.
  **Hyper3D lot 1 fait** : 7 unités générées sur le site par Claude (Claude in Chrome, 4 crédits ; reste 25 + 24,5),
  allégées par `scripts/alleger_modele.gd`, en jeu. 122 tests.
  **Reste** : P2-40 (encore plus de contenu), P2-55 (cartes vivantes), P2-56 (chemins par segments), P2-58 (BD),
  P2-22 (chasse au texte continue), P2-11 (vitrine du titre), PT-51 (lot 2 bâtiments : images à faire puis à faire
  valider par Carlos), PT-53 (animations Hyper3D), PT-54 (micro-décors). Test Windows par Carlos.
- **Hyper3D par Chrome** : hyper3d.ai/workspace/rodin, champ image = 1er `file-input` (pas ceux de « 3D Editing ») ;
  bouton GENERATE (0,5 crédit) → Confirm géométrie → Generate matériau → Confirm → `.glb` → Download. Chrome
  n'enregistre pas l'archive (blob) : lancer le récepteur local (`scratchpad/recepteur/serveur.py`, port 8765) et
  poser le crochet `URL.createObjectURL` dans la page (voir `docs/architecture.md` § Hyper3D lot 1).
- **Banc depuis le playtest 2** : pause vide, cadence ateliers ×1,83, 5 s avant le 1er ennemi, tourelles des coffres
  simulées (canon V4, mortier V7). Repères : moyen 0-36 PV, parfait 0-4 PV ; très sensible au seuil.
  Variables d'essai `CADENCE`, `DELAI`, `AVANCE` ; 6e argument `sans_tourelles`.
- **Captures** : `Graphismes` passe à 15 images/s hors focus → `Graphismes._arriere_plan = false` pour mesurer.
  Jamais `prereglage()`/`enregistrer()` ni `Touches.assigner` dans une capture ; progression temporaire via
  `Progression.chemin`.

## État précédent (2026-11-26 tard le soir)
- **Après playtest 1** : la roadmap `docs/roadmap.md` § « Après playtest 1 » liste 100 % du brief de Carlos (PT-01 à PT-65,
  règles R1-R7, table de vérification brief → tâches). **Faits et commités** (2026-11-27, ~0 h 55) : tous les PT sauf
  ceux qui attendent Hyper3D ou Gemini — PT-51 (modèles de paliers), 52 (images du lot 1), 53 (animations générées),
  54 (micro-décors 3D) et 2 icônes (monnaie méta, « assembler »). Campagne (6 chapitres), difficultés, déblocage
  progressif, Longue route avec tiroirs, paliers d'extension, craft, table procédurale faits. 107 tests. Builds
  Mac/Windows réexportés, Mac relancé (OK).
  **Attend Carlos** : valider les images puis générer le lot 1 Hyper3D (`art_refs/hyper3d/DEMANDE_LOT1.md`) ; test Windows.
  **Gemini** : quota épuisé depuis le 2026-11-26 ~23 h 50 (encore épuisé à 0 h 50) → relancer d'abord les images du lot 1.
  **Codex** : limite d'usage atteinte le 2026-11-27 ~0 h 15 (réessai annoncé à 1 h 26).
  Gemini : `agy-bridge` uniquement (le CLI `agy` avec saut de permissions est refusé) ; un `delegate` tient ~12 min,
  un `follow_up` expire à 5 min, `web_lookup` à 2 min → découper finement.
- **Captures** : ajouter `-- --fenetre` après le script (`Godot --path . --windowed --resolution 1600x900 --script res://x.gd
  -- --fenetre`), sinon l'autoload `Fenetre` applique le plein écran enregistré et la fenêtre ne dessine plus pendant la
  transition. Dans un script de capture, `load()` les scripts du jeu après le premier `await` (un `preload` compile avant
  les autoloads et casse `menu_titre.gd`). **La progression de Carlos (`progression.cfg`) est réelle** : la sauvegarder
  avant une capture qui finit une partie et la restaurer après (ne pas la supprimer).
- **Carlos a donné carte blanche** : commiter chaque lot terminé sans demander et enchaîner (pas de push sans demande).
- **Tout est commité jusqu'à l'étape 10.** Étape 10 : tourelles de loot rare via coffres (V3/V6/V9), options (volumes par bus,
  plein écran), progression méta (Établi, engrenages d'or, `user://progression.cfg`), boss Grand Scarabée (V5, V10, barre de vie),
  DA v2 (étude `art_refs/etude_da_v2.md`, kit 3D `assets/final/kit_v2/`, kit UI `assets/ui/`, vue inclinée par défaut, table
  d'établi). 73 tests. Builds Mac + Windows réexportés (Mac testé). Voir `docs/architecture.md` § Étape 10.
- **Banc** : profil moyen `1,1,1,2,2,3,3,3,4,4`, profil parfait `1,1,2,2,3,3,4,4,5,5` (boucle sur 3 graines, lancer en
  `bash`). Depuis le playtest 1 le banc joue **mixte** (étapes 3 et 5 = lance-billes ; 4e argument `soldats` pour l'ancien).
  Repères (2026-11-27) : parfait 0-1 PV ; moyen meurt entre V5 et V10 (V8 en moyenne). 5e argument `longue` = Longue route
  (15 vagues ; profil de 15 étapes, ex. `1,1,2,2,3,3,4,4,5,5,6,7,7,7,7` : parfait 0-9 PV ; les tiroirs ne sont pas simulés).
- **Pièges nouveaux** : la logique (production, sim) ne doit jamais lire un autoload (le banc en `--script` n'en a pas) ;
  les tests isolent la progression (`tests/run_tests.gd`) ; les captures qui finissent une partie écrivent dans la vraie
  progression → supprimer `~/Library/Application Support/Godot/app_userdata/Rouages/progression.cfg` après ; une plaque 9-patch
  plus haute que le bouton s'écrase (d'où `plaque_laiton_petite.png`) ; Codex a un quota (erreur « usage limit » dans le log).

- **Étapes 7 et 7b faites** (commitées) : horloge 3D, sons procéduraux (`scripts/generer_sons.py`, autoload `Sons`),
  ressorts + boutique + relance + réparation, rente des extensions, scarabée cuirassé, atelier de lance-billes, menu titre
  (scène principale, vitrine 3D de l'horloge), pause (Échap/P), fin avec stats, tutoriel en 5 bulles (`user://reglages.cfg`),
  infos de survol, vitesse x2 (Espace bascule), passe visuelle (exposition, SSAO, joints de dalles, damier). 52 tests verts.
  Fiches : `taches/T08a_economie_variete.md`, `T08b_interface_menus.md`, `T08c_visuels_unites_effets.md`.
- **Étape 8** : modèles d'export 4.7.2 installés (Mac + Windows seulement, pour la place disque). Exporter :
  `Godot --headless --path . --export-release "macOS" builds/Rouages_mac.zip` puis `"Windows" builds/Rouages_windows/Rouages.exe`
  et zipper le dossier. Mac testé (Movie Maker : `--write-movie f.png --fixed-fps 30 --quit-after 90`) ; Windows à tester sur le PC.
  Pièges : le Mac exige `import_etc2_astc=true` ; les `horloge_texture_*.png` sont extraits du .glb par l'import et **doivent**
  partir dans les builds (ignorés par git seulement). Le build release refuse un chemin de scène en argument.
- **Captures de vérification** : script jetable `--script capturer.gd` (charger une scène dans `root`, attendre, puis
  `root.get_texture().get_image().save_png()`) en mode fenêtré, pas headless.
- **Banc d'équilibrage** (avant de toucher une vague) :
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/banc_equilibrage.gd -- 1,1,2,2,3,3,4,4,5,5 1 0`
  (profil = ateliers avant chaque vague, graine, vague de pose d'un sentier). Toujours 3 graines ou plus. Le banc ne simule
  ni la boutique ni les lance-billes : un vrai joueur a plus d'outils que lui.
- Finitions faites : toit rouge + clé sur l'atelier de soldats, ombres nettes (`shadow_blur` 0,8), cartes de draft à deux niveaux.
- Place disque faible (~7 Go) : si besoin, Carlos autorise à déplacer les gros fichiers sur son disque externe Lexar.

- **Étape 9 (retours d'un testeur portugais)** : T09a (garde des jouets, pose en vague, rotation payante, marqueurs
  d'extension, plateaux Prairie/Méandres/Fourche, défi du jour, fourmi), T09b (traduction FR/EN/PT : clé = texte français,
  `traductions/textes.csv`, ajouter toute nouvelle chaîne au CSV et l'afficher via `tr()`), T09c (billes en vol, flash des
  ennemis touchés, rebond des ateliers). Claude : rééquilibrage au banc, menu (plateau, défi du jour + record), icône
  (`assets/icone.png`), musique de vague. Idée de Carlos au backlog : multijoueur coop et 1 contre 1.

## Procédure d'une étape (Claude = chef de chantier léger)
1. Lire la fiche de l'étape précédente et les fichiers qu'on va toucher (pas tout le dépôt).
2. Écrire `taches/Txx_sujet.md` (modèle dans `taches/README.md`) : fichiers autorisés, contrat exact, tests exigés.
3. Codex : `./scripts/codex_bridge.sh ecrire gpt-6.2-astra <medium|high> taches/Txx.md` **en arrière-plan** (5 à 25 min).
   Compte rendu dans `.codex-log/*-Txx*.dernier-message.md`.
4. Vérifier : `./scripts/tests.sh` · `git status` (seuls les fichiers autorisés ont bougé ?) · lecture du diff des fichiers clés ·
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 60` (aucune erreur de script).
5. `git add game data tests` (= « relu »), mettre à jour la roadmap et `historique_prompts.md`, lancer le jeu en arrière-plan pour
   Carlos (`/Applications/Godot.app/Contents/MacOS/Godot --path .`), lui donner 5 lignes de test manuel.
6. Commit **seulement** quand Carlos le demande (message en français + ligne Co-Authored-By).

## Pièges connus
- **Garde-fou du bridge Codex** : il refuse de démarrer si `game/`, `data/` ou `tests/` ont des changements **non indexés**.
  Indexer (`git add`) le travail relu avant de relancer Codex.
- **Antigravity par `agy-bridge`** : toujours passer `model` (ex. `gemini-4-neon-xhigh`). Les outils Blender autorisés sans
  confirmation sont au format `mcp(blender/<outil>)` dans `~/.gemini/config/config.json` (fait par Carlos). `generate_3d` (Hyper3D,
  payant) n'est volontairement **pas** autorisé : il demande confirmation à Carlos. Ne jamais modifier soi-même ces autorisations.
  Les générateurs de l'addon Blender sont « off » : Carlos devra activer Hyper3D dans l'addon avant l'étape 7.
- **2 échecs de suite sur le même point** → stop et message à Carlos (règle anti-boucle).
- Le shell est **zsh** : `set -- $var` n'y découpe pas les mots (piège rencontré avec le banc) ; écrire les boucles en `bash`.
- Les références `.gd` utilisent `class_name` + `preload` ; les tests sont des `RefCounted` avec des méthodes `test_*()` qui
  renvoient `""` si OK.

## Fin de session
Quand l'étape est relue et testée par Carlos : proposer le commit, puis proposer d'ouvrir une **session neuve** pour l'étape
suivante (contexte frais = moins de tokens), en mettant à jour la section « État » ci-dessus.

## Incident à connaître (2026-11-27, 16 h 56)
`reglages.cfg` de Carlos a reçu `[astuces] chance=true` pendant une capture fenêtrée : la fenêtre du jeu prend le focus,
et un clic ou une touche de Carlos y a fermé une bulle d'astuce (`Astuces._fermer` écrit dans les réglages). Depuis,
`scripts/joueur_auto.gd` met `root.gui_disable_input = true` : **tout script de capture fenêtré doit faire pareil**.
L'ancien contenu n'a pas pu être reconstitué (md5 différent de toutes les hypothèses) : fichier laissé tel quel.
