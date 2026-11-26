# Reprise — à lire en premier par toute nouvelle session Claude

Ce fichier remplace la lecture du dépôt. Ensuite : `docs/roadmap.md` (prochaine étape), `docs/architecture.md`
(principes, signaux, contrat d'assets) et `docs/backlog.md` (ne rien coder de ce qui y figure avant la fin de la roadmap).

## État (mis à jour le 2026-11-26)
- Étapes 0 à 4 faites (T04 relue et indexée, **pas encore commitée** : proposer le commit à Carlos) : plateau et énergie, caméra et pose, DA greybox, nuées (300 contre 300 à 60 FPS), ateliers, vagues,
  PV de l'horloge, victoire, défaite et Rejouer. 27 tests verts. Dernière fiche : `taches/T04_ateliers_vagues.md`.
- Provisoire, à remplacer à l'étape 5 : palette de pièces illimitées (`game/ui/palette_debug.*`), plateau de départ codé dans
  `game/board/plateau_noeud.gd`, phase de départ CONSTRUCTION dans `game/core/run.gd`, 3 vagues seulement.

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
- Les références `.gd` utilisent `class_name` + `preload` ; les tests sont des `RefCounted` avec des méthodes `test_*()` qui
  renvoient `""` si OK.

## Fin de session
Quand l'étape est relue et testée par Carlos : proposer le commit, puis proposer d'ouvrir une **session neuve** pour l'étape
suivante (contexte frais = moins de tokens), en mettant à jour la section « État » ci-dessus.
