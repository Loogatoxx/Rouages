# T11a — Charte d'icônes, icônes prioritaires et badge de quantité (playtest 1 : PT-13, PT-20, PT-21)
**Pour** : Antigravity · **Étape roadmap** : Après playtest 1 · **Modèle** : Gemini 4 Neon (XHigh)

## Objectif
Carlos : « Ressort ne ressemble pas à un ressort ; la vie de l'horloge doit évoquer un cœur ; l'icône de vague est illisible
sans texte ; le badge de quantité à pointe gauche est incohérent. » Règles : **toutes les icônes dans le même thème et la
même DA**, **une icône = un seul concept** (jamais réutilisée pour deux idées). Principe du jeu : icônes au premier plan,
texte au survol — les icônes doivent donc se lire seules, à 32-40 px à l'écran.

## Fichiers autorisés (rien d'autre)
- `art_refs/charte_icones.md` (créer, ≤ 1 page) · `assets/ui/icones/*.png` (créer / remplacer) ·
  `assets/ui/icones/REGISTRE.md` (créer) · `assets/ui/pastille.png` (créer) · `assets/ui/LISEZMOI.md` (compléter)

## À lire avant
`AGENTS.md`, `art_refs/etude_da_v2.md` (§ 3.C), `assets/ui/LISEZMOI.md`, les icônes existantes de `assets/ui/icones/`.

## Livrables
1. **Charte** `art_refs/charte_icones.md` : gabarit 128 × 128 px, fond transparent, zone utile 112 px centrée, trait d'encre
   `#3B2618` d'épaisseur constante (préciser en px), 1 matière dominante + 1 accent pastel, éclairage haut-gauche, même
   biseau ; silhouette lisible à 32 px (tester une réduction) ; interdits (emoji, sci-fi, néon, sombre, dégradés criards).
2. **Registre** `assets/ui/icones/REGISTRE.md` : tableau `fichier → concept unique → où il sert`. Vérifie qu'aucune icône
   ne sert deux concepts (signale tout doublon actuel).
3. **Icônes refaites** (mêmes noms de fichier pour remplacer) : `ressort.png` (vrai ressort hélicoïdal de laiton, spires
   visibles de 3/4), `horloge_pv.png` (cœur rouge corail serti de laiton, petite aiguille ou rivet : « PV de l'horloge »),
   et nouvelle `vague.png` (trois silhouettes de scarabées en file + fanion : « vague d'ennemis », sans chiffre).
4. **Icônes nouvelles** (un concept chacune) : `ennemis_restants.png` (un scarabée + sablier), `entree.png` (flèche/panneau
   « par ici arrivent les ennemis »), `chance.png` (trèfle à 4 feuilles émaillé menthe), `deplacer.png` (main/pince qui
   soulève une tuile), `ameliorer.png` (chevron laiton vers le haut sur une clé), `boutique.png` (petite échoppe / tiroir à
   pièces), `menu.png` (engrenage de réglages simple, différent de `engrenage_or.png`), `tourner.png` (flèche circulaire),
   `relancer.png` (deux flèches en boucle sur une carte).
5. **Pastille de quantité** `assets/ui/pastille.png` : remplace l'étiquette à pointe gauche pour « ×2 » et les prix. Forme
   ronde/ovale symétrique (jeton de laiton ou de carton rond à liseré), 9-patch étirable horizontalement : donne les marges
   exactes (texture et contenu) dans `LISEZMOI.md`. Le texte (Nunito Bold 18, `#3B2618`) doit être centré dedans.

## Méthode
Produis les PNG avec ton outil d'image ou en dessin vectoriel scripté (suréchantillonnage 4×, puis réduction), comme le kit
UI v2. Planche de contrôle obligatoire : `art_refs/planche_icones_v2.png` (toutes les icônes côte à côte à 128 px et à 32 px)
pour juger la cohérence d'un coup d'œil. Avant chaque icône : « est-ce lisible seul, sans texte, à 32 px ? ».

## Hors périmètre
Aucun fichier hors liste (pas de `game/`, pas de `.tscn`). Pas de Hyper3D. Ne supprime aucune icône existante.

## Critère de fin
Planche de contrôle + charte + registre écrits ; compte rendu ≤ 300 mots (fichiers, écarts, marges de la pastille).
