# T08b — Menus, boutique, tutoriel, survol, retours visuels (interface)
**Pour** : Codex · **Étape roadmap** : 7b (rush jouabilité) · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Rendre la run agréable du menu titre à l'écran de fin : menus, boutique de ressorts, vitesse x2, tutoriel en bulles à la
première run, infos de survol des tuiles et retours visuels forts (horloge touchée, vague, victoire). DA verrouillée :
bois chaud, laiton doux, crème, pastels ; **jamais** de néon ni d'ambiance sombre (les voiles restent clairs et chauds).

## Fichiers autorisés
- game/ui/theme_rouages.tres (créer : thème commun — panneau bois `#42301F` arrondi, texte crème `#FFE8BA`,
  boutons laiton doux `#C9A24A` / survol `#E0BC63` / désactivé grisé chaud, tailles de police 18-48)
- game/ui/menu_titre.tscn, game/ui/menu_titre.gd (créer)
- game/ui/menu_pause.tscn, game/ui/menu_pause.gd (créer)
- game/ui/tutoriel.tscn, game/ui/tutoriel.gd (créer)
- game/ui/info_survol.gd (créer)
- game/ui/hud.gd, game/ui/hud.tscn, game/ui/reserve_ui.gd, game/ui/reserve_ui.tscn
- game/main.tscn (ajouter les nœuds Tutoriel, MenuPause, InfoSurvol ; ne rien retirer)

## À lire avant
AGENTS.md · game/core/run.gd (API ressorts/boutique/vitesse : `ressorts`, `acheter`, `relancer_offre`, `reparer_horloge`,
`basculer_vitesse`, `vitesse`, `derniere_recompense`, `ennemis_casses`, `ressorts_gagnes`) · game/core/events.gd ·
game/core/sons.gd (`Sons.jouer(&"clic")`, `Sons.regler_musique`, `Sons.regler_effets`, `musique_active`, `effets_actifs`) ·
game/ui/hud.gd · game/board/pose_controleur.gd (projection souris → case, à imiter) · data/regles.tres (boutique)

## Contrat
- **Menu titre** (`menu_titre.tscn`, deviendra la scène principale — Claude modifie `project.godot`) : fond dégradé chaud
  (miel → crème), illustration `res://assets/final/horloge/apercu.png` (TextureRect, si le fichier existe), titre « Rouages »,
  sous-titre « Défends l'horloge avec tes jouets à remontoir ». Boutons : Jouer (`Run.reinitialiser()` puis
  `change_scene_to_file("res://game/main.tscn")`), Revoir le tutoriel (efface le drapeau), Musique oui/non, Effets oui/non,
  Quitter. Chaque bouton joue `Sons.jouer(&"clic")`.
- **Pause** (`menu_pause.tscn`, CanvasLayer couche 20, `process_mode` ALWAYS) : s'ouvre sur `Events.pause_demandee`, l'action
  `pause` (P) ou le bouton pause du HUD ; `get_tree().paused = true`. Boutons : Reprendre, Recommencer la run, Menu titre,
  Musique / Effets. P ou Échap (`annuler`) referment. Toujours remettre `paused = false` avant de changer de scène.
- **HUD** : ajouter `Ressorts : N` (sur `Events.ressorts_changes`, relit aussi `Run.pv_horloge`), bouton vitesse « x1 »/« x2 »
  (et l'action `accelerer` = Espace **bascule** via `Run.basculer_vitesse`), bouton pause. En CONSTRUCTION : panneau
  **Boutique** listant `Run.regles.boutique` (« Nom ×q — prix »), boutons désactivés si ressorts insuffisants ou
  `vague_min` pas atteint, plus « Réparer l'horloge (+pv) — prix » ; en DRAFT : bouton « Relancer le tirage — prix ».
  Écran de fin : titre (« Victoire ! » / « L'horloge s'est arrêtée… »), stats (vagues tenues, scarabées cassés, ressorts
  gagnés), boutons Rejouer et Menu titre.
- **Retours visuels** (dans le HUD) : bandeau animé « Vague N » (fondu 1,5 s) sur `vague_commencee` ; « Vague tenue !
  +X ressorts » sur `vague_terminee` (X = `Run.derniere_recompense`) ; sur `horloge_touchee` : voile corail clair
  (`#FF9C85`, alpha ≤ 0,25) en fondu 0,35 s et petite secousse du libellé PV ; à la victoire : confettis pastel
  (CPUParticles2D) ; petit « +N » flottant près du compteur quand les ressorts augmentent.
- **Tutoriel** (`tutoriel.tscn`, CanvasLayer) : seulement si `user://reglages.cfg` section `tutoriel` clé `vu` ≠ true (lire
  le fichier existant et **conserver** ses autres sections). Bulles non bloquantes (panneau bois, bouton « Compris »,
  lien « Passer le tutoriel »), déclenchées dans l'ordre : 1) 1er DRAFT : choisir un lot ; 2) 1re CONSTRUCTION : cliquer
  une pièce de la réserve, la poser, R ou clic droit pour tourner, relier un atelier à l'horloge par des engrenages ;
  3) quand un atelier est alimenté (`Events.energie_recalculee` + présence d'un atelier) : « Ton atelier remonte des
  soldats ! Lance la vague » ; 4) 1re VAGUE : les scarabées suivent le chemin, Espace = x2, Échap = pause ;
  5) 1re fin de vague : ressorts et boutique. À la fin (ou « Passer »), écrire `vu = true`.
- **Survol** (`info_survol.gd`, Control dans un CanvasLayer ou enfant du HUD) : quand aucune pièce n'est sélectionnée et que
  la souris est sur une case du plateau (projection rayon → plan y = 0, `GrilleMonde.vers_case`), afficher près du curseur
  une étiquette : nom + description de la pièce ; pour un atelier « Alimenté » ou « Pas alimenté : relie-le à l'horloge » ;
  pour un chemin « Chemin des scarabées » ; rien sur l'herbe vide. Trouver le plateau via `$"../PlateauNoeud"` ou un
  `@export var plateau_noeud: NodePath`.
- **Réserve** : appliquer le thème ; le bouton affiche nom et quantité, l'infobulle la description.
- Appliquer `theme_rouages.tres` à tous les panneaux. Textes en français, sans emoji.

## Qualité visuelle (exigence de Carlos : « comme une première version publique »)
- **Un seul thème** (`theme_rouages.tres`) appliqué à tout : mêmes marges (16-24 px), coins (10 px), bordure laiton 2 px
  sur les panneaux bois, ombre portée douce, boutons avec états normal/survol/appuyé/désactivé tous définis. Aucun panneau
  gris par défaut de Godot ne doit rester visible (Tooltip, PopupPanel et Panel compris).
- Typo : `SystemFont` avec repli `["Avenir Next Rounded", "Nunito", "Segoe UI", "Trebuchet MS"]`, graisse demi-gras pour
  les titres ; hiérarchie claire (titre 48, sous-titre 22, corps 18, petit 15) ; lisible à 1080p.
- Pas d'emoji, pas de dégradé violet, pas de texte marketing : textes courts, précis, en français.
- Animations légères : apparition des panneaux en Tween (fondu + échelle 0,96 → 1, 0,18 s), survol des boutons
  (échelle 1,04, `pivot_offset` centré), retour au clic (son + léger enfoncement).
- Alignements soignés : HUD ancré proprement (ressorts et PV en haut à droite, vitesse/pause groupés, boutique à droite
  sous le tableau, réserve centrée en bas), rien qui chevauche à 1600×900 ni à 1920×1080.

## Hors périmètre
Pas de logique de jeu (rien dans `game/core/`, `board/`, `swarm/`, `waves/`), pas de `project.godot`, pas d'`assets/`.

## Critère de fin
`./scripts/tests.sh` au vert ; `Godot --headless --path . --quit-after 120` sans erreur de script, et de même avec
`res://game/ui/menu_titre.tscn` passé en argument de scène.
