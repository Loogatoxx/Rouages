# Kit d'interface « Établi d'horloger » — `assets/ui/`

Direction artistique v2 du projet **Rouages** (cf. `art_refs/etude_da_v2.md`, section 3.C) : bois poli noyer/miel, laiton doux brossé, papier crème vergé, carton à œillet et ruban bordeaux à liseré or. Fond transparent sur tous les PNG, suréchantillonnage 4× (aucun flou), trait d'encre brun foncé `#3B2618`.

---

## 1. Pièces 9-patch (`assets/ui/*.png`)

Valeurs exactes à renseigner dans Godot 4 (`NinePatchRect` → `patch_margin_*` ou `StyleBoxTexture` → `texture_margin_*`, en pixels) :

| Fichier | Taille (px) | `left` | `right` | `top` | `bottom` | Rôle UI recommandé |
|---|---:|---:|---:|---:|---:|---|
| `panneau_bois.png` | 256 × 256 | **44** | **44** | **44** | **44** | Barre principale, fenêtres modales, cadres structurels (coins renforcés laiton + rainure interne) |
| `plaque_laiton.png` | 256 × 256 | **36** | **36** | **36** | **36** | Compteurs HUD, boutons d'action clés (laiton brossé chanfreiné + 4 rivets d'angle) |
| `papier.png` | 256 × 256 | **32** | **32** | **32** | **32** | Infobulles, fiches descriptives, cartes de récompense (papier crème + double filet encre) |
| `etiquette.png` | 320 × 128 | **76** | **24** | **22** | **22** | Badges de vague, raccourcis (carton découpé + œillet laiton perforé) |
| `pastille.png` | 96 × 48 | **22** | **22** | **18** | **22** | Quantités (« ×2 ») et prix (« 15 ») — jeton ovale symétrique crème cerclé laiton, étirable horizontalement |
| `ruban.png` | 384 × 128 | **88** | **88** | **26** | **26** | Titres de vague, bannières victoire / défaite (ruban plié bordeaux/terracotta à liseré or) |

### Conseils d'intégration Godot (`StyleBoxTexture` / `NinePatchRect`)
- **Zones de contenu (`content_margin_*`)** :
  - `panneau_bois.png` : `left=28, right=28, top=26, bottom=28`
  - `plaque_laiton.png` : `left=24, right=24, top=18, bottom=20`
  - `papier.png` : `left=24, right=24, top=22, bottom=24`
  - `etiquette.png` : `left=76, right=20, top=16, bottom=20` *(le texte démarre à droite du filet séparateur de l'œillet)*
  - `pastille.png` : `left=14, right=14, top=6, bottom=10` *(+4 px en bas compensant l'ombre portée ; texte Nunito Bold 18 `#3B2618` centré horizontalement et verticalement)*
  - `ruban.png` : `left=84, right=84, top=24, bottom=36` *(le texte reste centré sur le corps central surélevé)*
- **Étirement de `etiquette.png` et `ruban.png`** : ces deux pièces sont conçues pour s'étirer **horizontalement** (les zones centrales entre `left` et `right` sont parfaitement uniformes). Pour des badges compacts en hauteur (< 80 px), garder une hauteur proche de 64–128 px ou appliquer `texture_margin` avec `axis_stretch_horizontal = STRETCH` et un `scale` uniforme si nécessaire pour garder l'œillet parfaitement circulaire.
- **États de bouton (hover / pressed)** : utiliser `modulate_color` dans `StyleBoxTexture` (ex. normal `#FFFFFF`, survol `#FFF5DE`, pressé `#E2D1B3` + décalage `+2 px` vers le bas).

---

## 2. Icônes 128 × 128 px (`assets/ui/icones/*.png`)

Toutes les icônes sont en **128 × 128 px**, RGBA, fond transparent, dessinées dans la même DA (encre `#3B2618`, volumes biseautés bois/laiton/pastels, zéro emoji) :

| Fichier | Usage |
|---|---|
| `icones/ressort.png` | Ressorts / monnaie d'énergie horlogère |
| `icones/horloge_pv.png` | Points de vie de l'horloge centrale |
| `icones/vitesse_x1.png` | Vitesse normale (×1) |
| `icones/vitesse_x2.png` | Vitesse accélérée (×2) |
| `icones/pause.png` | Pause |
| `icones/coffre.png` | Coffre de récompense / choix de fin de vague |
| `icones/rarete_commune.png` | Rareté **Commune** (médaillon bois & pierre crème) |
| `icones/rarete_rare.png` | Rareté **Rare** (losange laiton & gemme bleu ciel pastel) |
| `icones/rarete_epique.png` | Rareté **Épique** (étoile dorée & gemme lavande pastel) |
| `icones/engrenage_or.png` | Engrenage doré (réseau d'énergie / amélioration / onglet ateliers) |

---

## 3. Polices sous licence SIL OFL 1.1 (`assets/ui/polices/`)

Toutes les polices ont été vérifiées avec les accents français et portugais complets (`é è ê ë à â ç œ æ ù û ü ï î ã õ á í ó ú` et majuscules).

| Fichier | Rôle recommandé | Remarque Godot |
|---|---|---|
| `Fraunces-Bold.ttf` | **Titres, bannières, noms de vagues** | Statique Soft Bold — prêt à l'emploi |
| `Fraunces-SemiBold.ttf` | **Sous-titres, boutons principaux** | Statique Soft SemiBold — prêt à l'emploi |
| `Fraunces-Variable.ttf` | Police variable complète (axes `opsz`, `wght`, `SOFT`, `WONK`) | Optionnel (via `FontVariation`) |
| `Nunito-Regular.ttf` | **Textes courants, descriptions, infobulles** | Statique Regular 400 — prêt à l'emploi |
| `Nunito-SemiBold.ttf` | **Libellés HUD, étiquettes** | Statique SemiBold 600 — prêt à l'emploi |
| `Nunito-Bold.ttf` | **Chiffres HUD, compteurs, coûts** | Statique Bold 700 — prêt à l'emploi |
| `Nunito-Variable.ttf` | Police variable complète (axe `wght` 200–1000) | Optionnel (via `FontVariation`, défaut 200) |
| `OFL_Fraunces.txt` | Licence SIL OFL 1.1 officielle de **Fraunces** | À conserver lors de la distribution |
| `OFL_Nunito.txt` | Licence SIL OFL 1.1 officielle de **Nunito** | À conserver lors de la distribution |

---

## 4. Palette texte recommandée sur ce kit
- Texte sur `papier.png` / `etiquette.png` : encre brun foncé `#3B2618` (secondaire `#6E4B32`)
- Texte sur `plaque_laiton.png` : encre brun profond `#2F1D11` (légère ombre claire `#FBEAB8` à `+1 px` vers le bas pour effet gravé)
- Texte sur `panneau_bois.png` / `ruban.png` : crème lumineux `#FAF2E1` (ombre portée `#3B2618` à `1–2 px`)
