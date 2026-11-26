# Reprise — à lire en premier par toute nouvelle session Claude

Ce fichier remplace la lecture du dépôt. Ensuite : `docs/roadmap.md` (prochaine étape), `docs/architecture.md`
(principes, signaux, contrat d'assets) et `docs/backlog.md` (ne rien coder de ce qui y figure avant la fin de la roadmap).

## État (mis à jour le 2026-11-26)
- Étapes 0 à 4 commitées (`d24f33b`). **Étape 5 testée par Carlos et commitée** (« c'est très bien ») :
  draft d'un lot parmi 3 (`Run.choisir_lot`), réserve (`Run.reserve`), plateau et réserve de départ dans `data/depart.tres`,
  pioche et 10 vagues dans `data/regles.tres`, extensions de terrain (`data/extensions/`, +1 entrée obligatoire, bonus à la pose),
  remontage des jouets en CONSTRUCTION, répartition des jouets aux embranchements. 40 tests verts.
  Fiches : `taches/T05a_draft_reserve.md`, `T05b_extensions.md`, `T05c_vagues_equilibrage.md`.
- **Banc d'équilibrage** (avant de toucher une vague) :
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/banc_equilibrage.gd -- 1,1,2,2,3,3,4,4,5,5 1 0`
  (profil = ateliers avant chaque vague, graine, vague de pose d'un sentier ; 2 s par run). Toujours comparer sur 3 graines ou plus.
- **Retour de Carlos (à traiter en premier à l'étape 6)** : on voit mal les soldats, blanc sur blanc (couleur des jouets vs chemin crème).
- Pistes pour l'étape 6 (playtest) : la difficulté repose sur des profils au placement parfait ; un vrai joueur est plutôt un cran
  en dessous. Les fuites arrivent par paquets (rupture brutale) : si c'est frustrant, jouer sur `pv_horloge` ou adoucir V7-V8.
  Les jouets « campent » sur les entrées ; vérifier que c'est lisible. Les extensions : mesurer si on les prend (bonus assez tentant ?).

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
