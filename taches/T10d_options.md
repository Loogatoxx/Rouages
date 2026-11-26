# T10d — Menu d'options (volumes, plein écran, langue)
**Pour** : Codex · **Étape roadmap** : 10 · **Modèle/effort** : gpt-6.2-astra medium

## Objectif
Aujourd'hui, le son ne se règle que par « oui / non ». Un jeu publié a des curseurs de volume et un plein écran.
Créer un panneau d'options commun, ouvert depuis le menu titre et le menu pause.

## Fichiers autorisés
- default_bus_layout.tres (créer à la racine : bus Master, Musique, Effets)
- game/core/sons.gd
- game/ui/options.gd et game/ui/options.tscn (créer)
- game/ui/menu_titre.gd/.tscn et game/ui/menu_pause.gd/.tscn (remplacer les boutons Musique/Effets par un bouton « Options »)
- tests/test_options.gd (créer)
- (Ne touche PAS traductions/textes.csv : une autre tâche l'édite en parallèle. Liste en fin de résumé les textes nouveaux à traduire.)

## À lire avant
AGENTS.md · les fichiers ci-dessus · game/ui/theme_rouages.tres · game/ui/langue.gd

## Contrat
- Bus audio : la musique joue sur `Musique`, les effets sur `Effets` (`AudioStreamPlayer.bus`).
- `Sons` : `regler_volume(bus: StringName, lineaire: float)` (0 à 1 → `linear_to_db` sur le bus, muet à 0), `volume(bus) -> float` ;
  sauvegardés dans `user://reglages.cfg`, section `son`, clés `volume_musique` / `volume_effets` (défaut 0.8).
  Les anciennes `musique_active`/`effets_actifs` restent lisibles (compatibilité) : `false` ⇒ volume 0 au chargement.
- `options.tscn` (CanvasLayer `PROCESS_MODE_ALWAYS`, caché par défaut) : panneau au style Bois du thème, titre « Options »,
  `HSlider` Musique et Effets (0–1, pas 0.05, effet immédiat), `CheckButton` « Plein écran », bouton Langue (`Langue.suivante`),
  bouton « Retour ». Échap ferme. `func ouvrir()`, `signal ferme`.
- `options.gd` : `static func appliquer_affichage()` lit `affichage/plein_ecran` dans reglages.cfg et règle
  `DisplayServer.window_set_mode` (FULLSCREEN ou WINDOWED) ; appelée dans `menu_titre._ready`. Rien en mode headless.
- Menus : un bouton « Options » à la place des boutons Musique/Effets/Langue ; focus clavier rendu au bouton à la fermeture.
- Lisible en 1080p, cohérent avec les panneaux existants (même thème, pas de gris Godot par défaut, aucun emoji).

## Hors périmètre
Pas de remappage des touches, pas de résolution personnalisée, pas de `project.godot` (Claude y déclarera le bus si besoin).

## Critère de fin
`./scripts/tests.sh` au vert avec test_options (volume sauvegardé puis relu, 0 ⇒ bus muet, compat ancien réglage) ;
`Godot --headless --path . --quit-after 120` sans erreur.
