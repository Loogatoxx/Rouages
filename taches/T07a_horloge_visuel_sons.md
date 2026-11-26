# T07a — Visuel de l'horloge (à valider) + sons locaux
**Pour** : Antigravity · **Étape roadmap** : 7 · **Modèle** : gemini-4-neon-xhigh · **Crédits Hyper3D autorisés : 0**

## Objectif
Préparer la pièce maîtresse : une image de l'horloge que Carlos validera avant tout Image-to-3D (1 crédit, plus tard,
sur son feu vert). En parallèle, 5 sons courts générés localement.

## Fichiers autorisés
- art_refs/horloge_v1_a.png, art_refs/horloge_v1_b.png, art_refs/horloge_v1_c.png (créer : 3 propositions)
- assets/audio/{pose, rotation, jouet_sort, scarabee_casse, horloge_touchee}.ogg (créer)
- assets/audio/LISEZMOI.md (créer : origine et réglages de chaque son)

## À lire avant
CLAUDE.md §5 (DA verrouillée) · art_refs/plateau_maquette_v1.jpg · assets/greybox/horloge/ (proportions)

## Contrat
- **Images** : horloge-tour de jouet artisanal, socle d'environ 1 case, ~3 m de haut (silhouette élancée, lisible vue de haut),
  bois poli, laiton doux, cadran crème, touches pastel, petite vapeur légère. Fond neutre uni clair, vue 3/4, objet entier
  centré, pas de texte : ce format sert d'entrée Image-to-3D. Interdits : sci-fi, punk, néon, sombre.
- **Sons** : `.ogg` mono, < 1 s (sauf `horloge_touchee` < 1,5 s), doux et « boîte à musique / bois », jamais agressifs,
  normalisés à environ -14 LUFS. Aucun appel à un service payant.

## Hors périmètre
**Aucun appel `generate_3d` / Hyper3D.** Ne rien modifier dans `game/`, `data/`, `tests/`.

## Critère de fin
Les 3 images et les 5 sons existent ; LISEZMOI.md liste les sons ; compte rendu en 5 lignes.
