# AGENTS.md — Consignes pour Codex et Antigravity (projet « Rouages », Godot 4.7)

Rouages : tower defense sur un plateau-maquette en bois. L'horloge centrale alimente des ateliers par des chaînes
d'engrenages ; les ateliers produisent des nuées de jouets à remontoir contre des nuées de scarabées.
**Claude est chef de projet** : il écrit les fiches dans `taches/`, relit et intègre. Tu exécutes **une fiche à la fois**.

## Règles communes
- Lis **seulement** ce fichier, ta fiche et les fichiers qu'elle cite. Pas d'exploration du dépôt « pour voir ».
- **Ne crée ou ne modifie que les fichiers listés** dans « Fichiers autorisés ». Besoin d'un autre fichier ? Arrête-toi et dis-le.
- Ne touche jamais à `project.godot`, `.mcp.json`, `scripts/`, `docs/`, `CLAUDE.md`, `AGENTS.md` (réservés à Claude).
- Pas de commit, pas de push. Français pour les commentaires et les noms métier.
- Termine toujours par : fichiers créés ou modifiés · ce qui reste à brancher · écarts par rapport à la fiche.
- Résumé final ≤ 300 mots.

## Si tu es Codex (code)
- Domaine : `game/`, `data/`, `tests/`. **GDScript typé** (`var x: int`, `-> void`), Godot 4.7.
- **La logique ne connaît pas les visuels** : les scripts de logique (`board/`, `swarm/`…) n'utilisent ni nœuds 3D ni meshes.
  Les visuels lisent l'état et l'affichent. Les tests ne testent que la logique.
- Chaque classe et chaque fonction publique a un commentaire de doc `##` en français (une ligne suffit) :
  Carlos apprend en lisant le code.
- Données de jeu = **Resources `.tres`** dans `data/` (jamais de chiffres d'équilibrage codés en dur).
- Communication entre systèmes = signaux de l'autoload `Events` (`game/core/events.gd`). Tu n'en ajoutes pas : demande à Claude.
- Entrées = actions de l'InputMap (`poser_tuile`, `tourner_tuile`, `annuler`, `basculer_camera`, `camera_*`, `accelerer`),
  jamais de touches codées en dur.
- Tests : `tests/test_*.gd` (étend `RefCounted`, méthodes `test_*()` qui retournent `""` si OK, sinon le message d'erreur).

## Si tu es Antigravity (3D, DA, audio)
- Domaine : `assets/` uniquement, plus les scènes visuelles `*_visuel.tscn` quand la fiche le demande. Jamais de script de logique.
- **Contrat d'assets** : 1 tuile = **2 m × 2 m** ; origine au centre de la base ; Y vers le haut ; export **`.glb`** ;
  dossier `assets/final/<nom>/` (ou `assets/greybox/<nom>/`). Matériaux simples (PBR), textures ≤ 1024 px sauf pièce maîtresse.
- **DA verrouillée** : bois poli, laiton doux, pierre crème, pastels, lumière chaude de fin d'après-midi.
  Interdits : sci-fi, punk, néon, sombre. Références : `art_refs/`.
- **Hyper3D (44 crédits, budget fini)** : jamais de génération sans une image validée par Carlos ET une fiche qui l'autorise
  explicitement avec le nombre de crédits. Note chaque crédit dépensé dans `assets/CREDITS_HYPER3D.md`.
- Outils : Blender MCP (modulaire, masse, retouches, exports), Hyper3D (pièces maîtresses), outil audio local (`assets/audio/`, `.ogg`).
