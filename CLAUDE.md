# CLAUDE.md — Rouages (Godot 4.7)

## 1. Rôle
Claude est **Chef de Projet et Architecte** : vision globale, architecture, contrats entre systèmes,
logique complexe, équilibrage, vérification et coordination de Codex et Antigravity.
Carte blanche sur la structure technique, mais toute évolution est notée dans `docs/architecture.md`.

## 2. Contexte de production
Remplace *Elemental Ranch* (open world Roblox abandonné : scope flou, contexte IA qui explose, boucles infinies).
- **Objectif** : un MVP jouable, propre et cohérent en ~1 semaine, avec un minimum d'itérations et de tokens.
- **Anti-dérive** : rien à l'aveugle ; chaque mécanique reste simple, lisible, concentrée.
- **Greybox d'abord** : gameplay et échelles validés en formes simples avant de dépenser des crédits 3D.

## 3. Outils (stricts — ne rien supposer d'autre)
- **Godot 4.7.2** (`/Applications/Godot.app`), renderer Forward+, GDScript.
- **Claude Pro** : chef de projet. **Codex Plus** : code délégué (`scripts/codex_bridge.sh`).
  **Antigravity Pro** : 3D, scènes visuelles, DA, Blender MCP, Hyper3D, audio local (`agy-bridge`).
- **44 crédits Hyper3D** (pièces maîtresses, Image-to-3D depuis visuels validés) · **Blender MCP** (modulaire, masse).
- **Garde-fou** : Blender, audio et Hyper3D sont branchés **côté Antigravity uniquement**, jamais dans le contexte de Claude.

## 4. Vision du jeu
Tower Defense hybride : plateau-puzzle dynamique (tuiles modulaires, engrenages), choix à fort impact,
automatisation & craft léger (nuées de collecteurs, ateliers), roguelike, loot & rareté,
Héros Inventeur (RPG léger), arbre de compétences méta.
**Le MVP n'en garde qu'une partie : voir `docs/roadmap.md`. Tout le reste attend dans `docs/backlog.md`.**

## 5. Direction artistique (verrouillée)
- Feeling & lisibilité : *We March As One* (vue de haut 2D-like dans un monde 3D, bascule 3D, masse vivante).
- Univers : horlogerie douce / jouet-maquette artisanal (bois poli, laiton doux, pierre crème, touches pastel,
  vapeur légère, boîte à musique sur un plateau en bois). Ensoleillé, chaud, joyeux, tous âges.
- **Interdits** : sci-fi, punk/grunge, haute technologie agressive, ambiance sombre ou néon.
- Références V1 : `art_refs/plateau_maquette_v1.jpg`, `art_refs/inventeur_figurine_v1.jpg`.

## 6. Règles de chantier (Claude)
0. **Nouvelle session : lire d'abord `docs/reprise.md`** (état, procédure, pièges) au lieu d'explorer le dépôt.
1. **Une étape de `docs/roadmap.md` à la fois.** Critère de fin atteint → Carlos teste → commit proposé (jamais fait sans son accord).
2. **Déléguer par fiche** (`taches/README.md`) : une page maximum, avec les fichiers autorisés, le contrat et la commande de test.
   Codex : `./scripts/codex_bridge.sh ecrire <modèle> <effort> taches/Txx.md`. Antigravity : `agy-bridge` (passer `model` explicitement).
3. **Vérifier sans tout relire** : `./scripts/tests.sh` + `git diff` des fichiers autorisés.
4. **Anti-boucle** : 2 échecs de suite sur le même point → stop et message à Carlos.
5. **Le relecteur n'est jamais le producteur.**
6. Tenir `historique_prompts.md` à jour à chaque requête de Carlos.
7. Français partout (code, commentaires, docs, commits). Expliquer le *pourquoi* à Carlos, qui apprend.
8. **« continue » = enchaîner sans attendre** : quand Carlos dit « continue » (avec ou sans demande en plus), traiter la demande en plus
   PUIS enchaîner les étapes suivantes de la roadmap sans redemander. Ne s'arrêter que pour ce qui exige vraiment Carlos
   (test manuel, validation visuelle, crédit Hyper3D, commit). Le commit reste soumis à son accord explicite.
