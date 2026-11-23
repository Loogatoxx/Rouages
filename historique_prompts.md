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
