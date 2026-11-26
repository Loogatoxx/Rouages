# T10f — Brancher le kit 3D en volume (DA v2)
**Pour** : Codex · **Étape roadmap** : 10 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Carlos trouve le plateau moche : en vue 3D, **rien ne doit rester plat** (dalles-boîtes, disques bleus, caisses).
Antigravity a livré un kit `.glb` en volume dans `assets/final/kit_v2/` (voir `art_refs/etude_da_v2.md`, section 3).
Remplacer les primitives par ce kit, en gardant les primitives comme **repli** si un fichier manque (tests headless).

## Fichiers autorisés
- game/board/plateau_visuel.gd · game/swarm/nuee_visuel.gd
- assets/ambiance/ambiance.tscn (lumière : soleil ~35°, teinte `#FFF0D4`, ombres douces, SSAO plus marquée)
- game/core/materiaux.gd (ajout des teintes de rareté si utile)

## À lire avant
AGENTS.md · art_refs/etude_da_v2.md · les fichiers ci-dessus · `assets/final/kit_v2/*/` (noms des `.glb`)

## Contrat
- Constante `KIT := "res://assets/final/kit_v2/"` ; fonction `_instancier(nom) -> Node3D` (null si absent, mise en cache des PackedScene).
- Sol : `tuile_herbe` / `tuile_herbe_b` alternées par une graine stable `hash(case)` (pas de damier régulier), `tuile_chemin`
  pour le chemin. Vérifie l'échelle réelle du `.glb` (AABB) et ramène-la à une case (`GrilleMonde.TAILLE_CASE`), dessus du
  sol à y ≈ 0 pour que pièces et unités restent posées dessus.
- `bord_plateau` tout autour des cases de sol (sur chaque côté sans voisin), recalculé quand le plateau s'agrandit.
- Marqueurs d'extension : `marqueur_extension` au lieu du disque bleu ; léger balancement (Tween) du fanion si un sous-nœud s'y prête.
- Pièces : engrenages (4 formes selon les ports de base : droit, coude, T, croix — repère via `PieceDef.id`), le sous-nœud
  `Rotor` tourne quand alimenté ; ateliers et tourelles via leur `.glb` ; matériau nommé `Rarete` des tourelles recoloré
  (commune `#D4A84B`, rare `#8FB3D9`, épique `#E8B04A`). Pièce non alimentée : `material_overlay` gris semi-transparent
  (au lieu de tout remplacer). Les dents de port laiton restent dessinées par le code, posées sur le nouveau socle.
  Fantôme de pose : même modèle avec l'overlay de teinte existant.
- Unités (`nuee_visuel.gd`) : MultiMesh construit depuis le premier `MeshInstance3D` (ou la fusion des meshes) du `.glb`
  de chaque id (`soldat` pour `soldat_remontoir`, `lance_bille`, `scarabee`, `scarabee_cuirasse`, `fourmi`), mis à l'échelle
  du `rayon` du modèle ; flash `touches` et couleur par instance conservés (activer `use_colors` et un matériau qui les lit,
  ou `instance_shader_parameter` — à ton choix, mais le flash crème doit rester visible). Repli : formes actuelles.
- Garder les performances : `test_performance` ne régresse pas de plus de 20 %.

## Hors périmètre
Aucune logique de jeu, aucune donnée, aucune UI.

## Critère de fin
`./scripts/tests.sh` au vert ; `Godot --headless --path . --quit-after 120` sans erreur. Résumé : échelles constatées par modèle.
