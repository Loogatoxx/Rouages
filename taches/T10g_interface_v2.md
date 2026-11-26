# T10g — Interface v2 « Établi d'horloger » (fin de l'AI slop)
**Pour** : Codex · **Étape roadmap** : 10 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Carlos trouve l'interface générique (« AI slop » : rectangles arrondis, gros boutons uniformes). Antigravity a livré un kit
dans `assets/ui/` (9-patch bois/laiton/papier/étiquette/ruban, icônes, polices Fraunces + Nunito). Refaire le thème et
les écrans avec ce kit, d'après `art_refs/etude_da_v2.md` §3.C (inspiration : Kingdom Rush, Dorfromantik, Tiny Glade).

## Fichiers autorisés
- game/ui/theme_rouages.tres · tous les `game/ui/*.tscn` et `game/ui/*.gd` (hud, menu_titre, menu_pause, options, etabli,
  reserve_ui, info_survol, tutoriel) — **mise en forme seulement**, aucune règle de jeu
- traductions/textes.csv (ajout de lignes seulement)

## À lire avant
AGENTS.md · art_refs/etude_da_v2.md · assets/ui/LISEZMOI.md (marges 9-patch) · le thème et les scènes ci-dessus

## Contrat
- Thème : `StyleBoxTexture` 9-patch avec les marges du LISEZMOI. `PanelContainer` = `panneau_bois` ; boutons = `plaque_laiton`
  (états hover = modulate plus clair, pressed = contenu décalé de 2 px vers le bas, disabled = désaturé), texte encre `#3B2618` ;
  infobulles, descriptions et cartes de draft = `papier` ; prix et badges = `etiquette` ; titres (vague, « Coffre ! », victoire,
  défaite, titres de menus) = `ruban` avec texte crème `#FFF3D6`.
- Polices : Fraunces SemiBold/Bold pour les titres et les nombres importants, Nunito (Regular/SemiBold/Bold statiques) pour
  le texte. Tailles lisibles en 1080p (texte ≥ 18 px, titres 32-56 px). Contour/ombre douce sur le texte posé sur la 3D.
- HUD : compteurs (ressorts, PV horloge, vague) en **plaques laiton compactes avec icônes** (`assets/ui/icones/`) au lieu de
  texte nu ; boutons vitesse et pause = icônes (`vitesse_x1/x2`, `pause`) ; coffre = icône `coffre` dans le titre ;
  rareté = icône `rarete_*` sur la carte. Engrenages d'or = `engrenage_or`.
- Cartes de draft : fiche papier légèrement inclinée (rotation ±1,5° alternée), apparition en rebond `1,06 → 1,0`, survol
  qui la soulève (−6 px). Pas de dégradé violet, pas d'emoji, pas de gris Godot par défaut, aucun texte en majuscules criardes.
- Le HUD laisse respirer la maquette : barre haute fine, contrôles regroupés en coins, rien au centre pendant une vague.
- Toutes les scènes doivent toujours fonctionner (noms `%Unique` conservés : les scripts s'y réfèrent).

## Hors périmètre
Aucun changement de logique, de données, de 3D, de `project.godot`.

## Critère de fin
`./scripts/tests.sh` au vert ; `Godot --headless --path . --quit-after 120` sans erreur ; liste des scènes retouchées.
