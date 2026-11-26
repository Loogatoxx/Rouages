# T09b — Traduction français / anglais / portugais
**Pour** : Codex · **Étape roadmap** : 9 (retours playtest externe) · **Modèle/effort** : gpt-6.2-astra high

## Objectif
Un testeur portugais a demandé une traduction. Le jeu doit se jouer entièrement en **français (source), anglais et
portugais (Portugal)**, avec un choix de langue dans le menu titre et la pause, mémorisé.

## Fichiers autorisés
- traductions/textes.csv (créer) — format CSV Godot : `keys,fr,en,pt` ; **la clé est le texte français exact**
  (Godot traduit automatiquement le `text` des Control dont le texte correspond à une clé).
- game/ui/*.gd, game/ui/*.tscn (ajouter `tr()` partout où un texte est **composé** en code : `"%s ×%d" % …`, stats,
  annonces, tutoriel, boutique, survol ; un texte fixe dans une scène est traduit automatiquement)
- game/ui/langue.gd (créer : petit utilitaire statique — `appliquer(code)`, `lire() -> String`, `LANGUES = ["fr","en","pt"]`,
  mémorise `langue/code` dans `user://reglages.cfg` en **conservant** les autres sections ; défaut = langue du système si
  elle est fr/en/pt, sinon en)

## À lire avant
AGENTS.md · game/ui/hud.gd, menu_titre.gd, menu_pause.gd, tutoriel.gd, info_survol.gd, reserve_ui.gd ·
data/tuiles/*.tres, data/extensions/*.tres, data/unites/*.tres (champs `nom`, `description`) ·
data/departs/ si présent (`nom`, `description` des plateaux)

## Contrat
- Le CSV couvre **tous** les textes visibles : scènes UI, textes composés, tutoriel, noms et descriptions des pièces,
  extensions, unités et plateaux (Prairie, Méandres, Fourche). Les noms venant des données s'affichent via `tr(nom)`.
  Les formats gardent leurs `%s`/`%d` dans les trois langues.
- Anglais naturel et court ; portugais **européen** (« ecrã », « tu »), même ton chaleureux. Termes : ressorts → springs /
  molas ; atelier → workshop / oficina ; engrenage → gear / engrenagem ; scarabée → beetle / escaravelho ; vague → wave / vaga ;
  horloge → clock / relógio ; lance-bille → marble shooter / lança-berlindes ; défi du jour → daily challenge / desafio diário.
- Menu titre et pause : un bouton « Langue : Français » qui fait défiler fr → en → pt ; `TranslationServer.set_locale` puis
  rafraîchir les textes composés (signal `NOTIFICATION_TRANSLATION_CHANGED` ou réaffichage).
- Au démarrage, la langue mémorisée est appliquée dans `menu_titre.gd` (`Langue.appliquer(Langue.lire())`).
- Dans `reserve_ui.gd`, les boutons de la réserve restent actifs en CONSTRUCTION **et** en VAGUE (on peut poser pendant
  une vague) ; masqués en DRAFT et FIN.

## Hors périmètre
Ne touche ni `project.godot` (Claude y déclarera le CSV), ni `game/core|board|swarm|waves`, ni `data/`, ni `assets/`.
Ne change pas le texte français existant (les clés en dépendent).

## Critère de fin
`./scripts/tests.sh` au vert ; `Godot --headless --path . --quit-after 120` et avec `res://game/ui/menu_titre.tscn` sans
erreur de script ; liste dans le compte rendu des textes éventuellement non couverts.
