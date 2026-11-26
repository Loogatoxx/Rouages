# Charte d'icônes — « Rouages » (DA Établi d'horloger)

> **Principe fondateur** : **icônes au premier plan, texte au survol**. Chaque icône représente **un seul concept** (cf. `assets/ui/icones/REGISTRE.md`) et doit se lire seule, sans libellé, dès **32 à 40 px** à l'écran.

---

## 1. Gabarit & export
- **Format** : PNG RGBA **128 × 128 px**, fond 100 % transparent (`#00000000`).
- **Zone utile** : **112 × 112 px centrée** (marges de **8 px** sur chaque bord, soit `[8..120]` pour la silhouette pleine ; le bas-droite réserve l'espace de l'ombre portée).
- **Méthode de rendu** : dessin vectoriel / SDF scripté en **suréchantillonnage 4× (`512 × 512 px`)**, puis réduction **Lanczos** vers `128 × 128 px` (bords nets, zéro flou).

## 2. Trait d'encre constant
- **Couleur unique** : encre brun foncé **`#3B2618`** (jamais de noir pur `#000000`), coins et terminaisons arrondis (`round`).
- **Épaisseurs à 128 px** *(×4 à 512 px)* :
  - **Contour extérieur (silhouette)** : **3 px** *(12 px à 512 px)*, continu et fermé.
  - **Séparations internes de pièces** : **2 px** *(8 px à 512 px)*.
  - **Gravures / détails secondaires** : **1 à 1,5 px** ton sur ton foncé (jamais d'encre lourde qui bouche à 32 px).

## 3. Matières & palette (1 matière dominante + 1 accent pastel max)
Chaque icône combine **une seule matière dominante** d'atelier et **au plus un accent pastel** :

| Rôle | Matière / Teinte | Clair (biseau) | Base | Ombre |
|---|---|---:|---:|---:|
| **Dominante mécanique** | Laiton doux brossé | `#E9D18C` *(éclat `#FFF4C8`)* | `#C8A455` | `#8E6C2C` |
| **Dominante coffre / cadre** | Bois poli noyer / miel | `#C98B4C` | `#99602E` | `#663B1A` |
| **Dominante ennemis** | Bronze & carapace ambre-cuivre | `#E6A24E` *(éclat `#FFE6AE`)* | `#BD7331` | `#5B381D` |
| **Accent pastel (1 max)** | Rouge corail *(PV, vague, ×2)* | `#EE917C` | `#D55E4E` | `#963D32` |
| **Accent pastel (1 max)** | Vert menthe *(chance)* | `#9AD6BE` | `#6FB89D` | `#46826C` |
| **Accent pastel (1 max)** | Bleu ciel *(rare)* | `#B8DEF0` | `#74A8C7` | `#43718E` |
| **Accent pastel (1 max)** | Lavande *(épique)* | `#D8CCF0` | `#A68FC2` | `#6F5A8E` |
| **Accent neutre** | Pierre crème / rivets or | `#FDF4DA` | `#EFE4CC` | `#C4B190` |

## 4. Lumière, biseau & ombre portée
- **Source unique** : lumière chaude de fin d'après-midi venant du **haut-gauche (~135° / 10h30)**.
- **Dégradé de matière** : transition douce haut-gauche (clair) → bas-droite (ombre), jamais d'aplat brut ni de contraste criard.
- **Biseau interne constant** : largeur **~3 px à 128 px** *(12–14 px à 512 px)* juste à l'intérieur du contour — arête haut-gauche éclairée (+25 à 35 %), arête bas-droite ombrée (−20 à 25 %). Reflet spéculaire net sur les surfaces bombées (gemmes, cœur, carapaces, spires).
- **Ombre portée** : brun chaud **`#2A180C`**, opacité **33 %**, décalage **`+2 px` en X, `+4 px` en Y**, flou gaussien **2,5 px** *(+8/+16 px, flou 10 px à 512 px)*.

## 5. Validation à 32 px & interdits
- **Test obligatoire avant intégration** : ajouter l'icône sur `art_refs/planche_icones_v2.png` à **128 px** et réduite à **32 px** sur **deux fonds** (parchemin crème `#F0E5CE` et bois noyer `#8C562B`). Question couperet : *« Est-ce reconnaissable seul, sans texte, en un coup d'œil à 32 px ? »*
- **Proportions « jouet »** : formes franches, silhouettes lisibles en ombre chinoise, espaces d'air ≥ 3 px (à 128 px) entre éléments distincts (spires, scarabées, barres).
- **Interdits absolus** : emojis système, texte ou chiffres incrustés dans l'icône, esthétique sci-fi / punk / néon / sombre, noir pur `#000000`, dégradés saturés criards, micro-détails < 2 px à 128 px, clé de remontoir sur un élément ennemi (code réservé aux alliés).
