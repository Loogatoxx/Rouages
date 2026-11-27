# T12a — Campagne, déblocage progressif et difficultés (playtest 1 : PT-62, PT-63)
**Pour** : Codex · **Étape roadmap** : Après playtest 1 · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Carlos : à terme, une progression principale liée à l'histoire ; choix libre de la carte et défi du jour débloqués après
un certain nombre de niveaux ; plusieurs difficultés par carte ; ne pas tout dévoiler au lancement (mélange d'éléments
**masqués** jusqu'au déblocage et d'éléments **grisés avec cadenas** pour donner envie). Le bac à sable reste (R6).
Lore et chapitres : `docs/lore.md` § « Campagne envisagée ».

## Fichiers autorisés
`game/core/chapitre_def.gd` (créer), `data/campagne/chapitre_01.tres` à `chapitre_06.tres` (créer), `game/core/regles.gd`,
`data/regles.tres`, `game/core/progression.gd`, `game/core/run.gd`, `game/core/partie.gd`, `game/waves/directeur_vagues.gd`,
`game/core/amelioration_def.gd`, `data/ameliorations/*.tres`, `game/ui/menu_titre.gd`, `game/ui/menu_titre.tscn`,
`game/ui/etabli.gd`, `game/ui/hud.gd` (écran de fin seulement : « Chapitre terminé ! »), `traductions/textes.csv`,
`tests/test_campagne.gd` (créer).

## Contrat
- `ChapitreDef` : `id`, `titre`, `recit` (2-3 phrases tirées du lore, ton chaleureux), `depart: DepartDef`,
  `difficulte: int` (0 facile, 1 normal, 2 difficile). Chapitres : 1 L'Établi (Prairie, facile) · 2 Les Tiroirs
  (Méandres, facile) · 3 La Fourche du Grenier (Fourche, normal) · 4 Le Jardin d'hiver (Prairie, normal) ·
  5 La Boîte à musique (Méandres, difficile) · 6 Le Retour de Lise (Fourche, difficile). `Regles.chapitres`.
- **Difficultés** (`Regles` : `difficultes_pv_ennemis = [0.8, 1.0, 1.3]`, `difficultes_pv_horloge = [10, 0, -5]`) :
  `Run.difficulte` (0-2, défaut 1) ; `Run.reinitialiser` ajoute le bonus de PV d'horloge ; le directeur multiplie les PV
  des ennemis par le facteur (`DirecteurVagues.facteur_pv`, réglé par `Partie` — la logique ne lit pas d'autoload ; par
  défaut 1.0 pour que le banc reste inchangé).
- **Progression** (`user://progression.cfg`) : `chapitres_finis() -> int`, `finir_chapitre(n)`,
  `record(depart_nom, difficulte) -> int` / `noter_record(...)` (vagues tenues). `libre_debloque() -> bool` = au moins
  3 chapitres finis **ou ancien joueur** (fichier existant avec des engrenages ou des niveaux mais sans section
  « campagne » : on ne retire pas le jeu libre à quelqu'un qui l'avait déjà).
- `Run.chapitre: int` (-1 hors campagne) ; `Run.preparer_chapitre(i)` règle départ et difficulté ; la victoire d'un
  chapitre appelle `Progression.finir_chapitre`. Défi du jour inchangé mais **verrouillé** tant que le libre ne l'est pas.
- **Menu titre** : bouton principal « Campagne — Chapitre N : titre » (récit en infobulle et dans la fiche de description),
  puis « Partie libre » (choix de carte + bouton difficulté Facile/Normal/Difficile) et « Défi du jour » : grisés avec
  « 🔒 après le chapitre 3 » remplacé par le texte « Verrouillé : termine le chapitre 3 » (pas d'emoji).
- **Anti-spoil** : `AmeliorationDef.chapitre_min: int = 0`. Dans l'Établi, une amélioration dont `chapitre_min` dépasse
  `chapitres_finis() + 1` est **masquée** ; celle qui vaut exactement `chapitres_finis() + 1` est **grisée** avec
  « Débloquée au chapitre %d ». Valeurs : trèfle 3, relance offerte 2, choix du tirage 4, les autres 0. Les anciens
  joueurs voient tout.

## Hors périmètre
Pas de nouveau signal, pas de nouvelle carte, ne touche pas `swarm/`, `board/`, `project.godot`.

## Critère de fin
`./scripts/tests.sh` vert avec `tests/test_campagne.gd` (utilise un fichier de progression temporaire comme
`tests/test_progression.gd`) : déblocage après 3 chapitres ; ancien joueur débloqué ; facteur de PV par difficulté appliqué
par le directeur ; PV d'horloge selon la difficulté ; amélioration masquée/grisée selon le chapitre. Godot sans erreur.
