# Reprise — à lire en premier par toute nouvelle session Claude

Ce fichier remplace la lecture du dépôt. Ensuite : `docs/roadmap.md` (prochaine étape), `docs/architecture.md`
(principes, signaux, contrat d'assets) et `docs/backlog.md` (ne rien coder de ce qui y figure avant la fin de la roadmap).

## État (mis à jour le 2026-11-26 au soir, autonomie totale)
- **Carlos a donné carte blanche** : commiter chaque lot terminé sans demander et enchaîner (pas de push sans demande).
- **Tout est commité jusqu'à l'étape 10.** Étape 10 : tourelles de loot rare via coffres (V3/V6/V9), options (volumes par bus,
  plein écran), progression méta (Établi, engrenages d'or, `user://progression.cfg`), boss Grand Scarabée (V5, V10, barre de vie),
  DA v2 (étude `art_refs/etude_da_v2.md`, kit 3D `assets/final/kit_v2/`, kit UI `assets/ui/`, vue inclinée par défaut, table
  d'établi). 73 tests. Builds Mac + Windows réexportés (Mac testé). Voir `docs/architecture.md` § Étape 10.
- **Banc** : profil moyen `1,1,1,2,2,3,3,3,4,4`, profil parfait `1,1,2,2,3,3,4,4,5,5` (script prêt à l'emploi : boucle sur
  3 graines, lancer en `bash`). Repères actuels : parfait 0-7 PV perdus ; moyen premières fuites V3-V5, mort vers V7-V8.
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
