# T02b — Matériaux de la DA, ambiance lumineuse et kit greybox
**Pour** : Antigravity · **Étape roadmap** : 2b · **Modèle** : gemini-4-neon-xhigh · **Crédits Hyper3D autorisés : 0**

## Objectif
Donner au greybox l'ambiance de `art_refs/plateau_maquette_v1.jpg` : bois poli, laiton doux, pierre crème, herbe
feutrée, touches pastel, lumière chaude de fin d'après-midi. Et produire un kit greybox simple (formes lisibles, sans détail)
pour les étapes suivantes. Le code (dans `game/`) chargera automatiquement tes matériaux par leur nom.

## Fichiers autorisés
- assets/materials/{herbe, pierre_creme, bois_plateau, bois_clair, laiton, pastel_bleu, pastel_rose, pastel_vert, pastel_jaune}.tres (créer)
- assets/ambiance/ambiance.tscn (créer)
- assets/greybox/<nom>/<nom>.glb pour : tuile_herbe, tuile_chemin, horloge, engrenage, dent_port, atelier, scarabee, jouet (créer)
- assets/greybox/apercu.png (créer) · assets/greybox/LISEZMOI.md (créer)

## À lire avant
AGENTS.md (section Antigravity et contrat d'assets) · art_refs/plateau_maquette_v1.jpg

## Contrat
- **Matériaux** : `StandardMaterial3D` en `.tres` texte, **noms exacts** ci-dessus. Pas de textures externes : couleur,
  rugosité, métal, et éventuellement un léger bruit procédural. Couleurs de départ (à affiner selon la référence) :
  herbe #A9C98B · pierre_creme #EFE3C8 · bois_plateau #B9773E · bois_clair #E2BE8C · laiton #D4A84B (métal ~0,8, rugosité ~0,35) ·
  pastel_bleu #9EC3E6 · pastel_rose #F2B5C4 · pastel_vert #B8E0B0 · pastel_jaune #F5DC8A.
- **Ambiance** (`ambiance.tscn`) : racine `Node3D` contenant un `WorldEnvironment` (ciel procédural chaud, tonemap filmique/ACES,
  lumière ambiante douce, léger glow, **pas** de brouillard sombre) et un `DirectionalLight3D` « soleil bas » doré avec ombres douces.
- **Kit greybox** (Blender MCP) : contrat d'assets (1 case = 2 m × 2 m, origine au centre de la base, Y vers le haut, `.glb`).
  Formes simples et arrondies, façon jouet en bois. Tuiles : dalle 2 × 0,2 × 2. Horloge : environ 1 case de base, 3 m de haut.
  Engrenage : disque denté de 1,6 m de diamètre, **sans** dent de port. `dent_port` : petit bloc à placer au bord d'une case,
  orienté vers +Z. Atelier : 1 case, 1,5 m de haut. Scarabée : ~0,4 m. Jouet à remontoir : ~0,4 m, avec sa clé.
  Assigne les matériaux ci-dessus aux objets (même noms). Peu de polygones : moins de 2 000 triangles par objet, et moins de 500 pour le scarabée et le jouet.
- **Aperçu** : un rendu Blender de tout le kit posé sur des tuiles, éclairé chaudement, à comparer avec la référence.

## Hors périmètre
Ne touche à rien hors des fichiers autorisés (surtout pas `game/`, `project.godot`, `data/`). **Aucune génération Hyper3D.**
Pas de son. Pas de pièce maîtresse finale : c'est du greybox.

## Critère de fin
Les fichiers existent ; `LISEZMOI.md` liste chaque asset avec ses dimensions et son nombre de triangles.
Compte rendu ≤ 300 mots : fichiers créés, écarts par rapport à la fiche, points à valider par Carlos.
