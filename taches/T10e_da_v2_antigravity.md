# T10e — DA v2 : plateau tout en volume et interface originale (recherche + kit)
**Pour** : Antigravity · **Étape roadmap** : 10 · **Modèle** : Gemini Pro (High)

## Pourquoi
Avis de Carlos : « c'est moche ». En vue 3D, **rien ne doit être plat** sur le plateau : disques bleus, dalles-boîtes et
caisses font « prototype ». Et l'interface (panneaux arrondis, gros boutons) fait « AI slop » générique.
Objectif : un rendu de **maquette-jouet artisanale** au niveau des meilleurs jeux de cette DA.

## 1. Recherche (web) — livrable `art_refs/etude_da_v2.md` (≤ 2 pages)
Étudie comment font les jeux de référence de la DA « diorama / jouet / cosy » : *Bad North*, *Dorfromantik*, *Townscaper*,
*Tiny Glade*, *Islanders*, *Mini Motorways*, *Wilmot's Warehouse*, *Kingdom Rush* (lisibilité TD) et tout jeu horlogerie/jouet
en bois pertinent. Pour chacun : tuiles (biseaux, faces latérales, épaisseur, détails), lumière, ombre portée, palette,
**UI** (diégétique ? matières papier/bois/laiton ? typographie ? icônes ? animations ?), lisibilité des unités.
Conclus par **une direction précise et quasi identique au meilleur de ce qui se fait**, adaptée à notre DA verrouillée
(horlogerie douce, bois poli, laiton doux, pierre crème, pastels, ensoleillé ; interdits : sci-fi, néon, sombre, grunge).

## 2. Kit 3D en volume (Blender MCP, 0 crédit Hyper3D) — `assets/final/kit_v2/<nom>/<nom>.glb` + `apercu.png`
Contrat : 1 case = 2 m × 2 m, origine au centre de la base, Y en haut, low-poly propre, biseaux visibles, ≤ 3 000 tris/pièce,
matériaux PBR simples (pas de texture > 1024 px). Pièces :
- `tuile_herbe` (bloc épais à flancs de terre/bois, dessus herbe légèrement bombé, 2-3 touffes/fleurs pastel) et une variante `tuile_herbe_b`
- `tuile_chemin` (pavés de pierre crème en relief, joints creusés)
- `bord_plateau` (tranche de table en bois poli pour le pourtour)
- `marqueur_extension` (petit piquet laiton + fanion pastel, remplace le disque bleu plat)
- `engrenage_droit`, `engrenage_coude`, `engrenage_t`, `engrenage_croix` (vrai rouage denté sur socle ; le rouage = sous-nœud nommé `Rotor`, centré)
- `atelier_soldats` (maisonnette jouet, toit rouge, clé de remontoir) · `atelier_billes` (tour menthe, bille laiton)
- `tourelle_canon`, `tourelle_carillon`, `tourelle_mortier` (le matériau de rareté s'appelle `Rarete` pour être recoloré en jeu)
- `scarabee`, `scarabee_cuirasse`, `fourmi`, `soldat`, `lance_bille` : silhouettes lisibles de dessus, ≤ 400 tris (MultiMesh)
Les ports d'énergie (dents laiton) restent dessinés par le jeu : ne les modélise pas.

## 3. Kit d'interface — `assets/ui/`
- 9-patch PNG (`panneau_bois.png`, `plaque_laiton.png`, `papier.png`, `etiquette.png`, `ruban.png`) + `LISEZMOI.md` (marges du 9-patch).
- Icônes PNG 128 px dessinées dans la DA (ressort, horloge/PV, vitesse x1/x2, pause, coffre, rareté commune/rare/épique) — **aucun emoji**.
- Une police d'affichage et une police de texte sous **licence OFL** (`assets/ui/polices/`, avec le fichier de licence),
  accents français et portugais complets.

## Règles
Domaine `assets/` et `art_refs/` uniquement. Ne touche à aucun script ni à `game/`, `data/`, `project.godot`.
Termine par la liste des fichiers créés et 3 captures (aperçus) du kit.
