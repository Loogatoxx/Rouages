# Fiches de tâche

Une fiche = une tâche déléguée = **une page maximum**. Nom : `Txx_sujet.md` (ex. `T01_grille_energie.md`).
Les revues de Codex arrivent dans `revues/`.

## Modèle de fiche
```markdown
# Txx — <titre>
**Pour** : Codex | Antigravity · **Étape roadmap** : n · **Modèle/effort** : <modèle> <effort>

## Objectif
<2-3 phrases : ce que ça doit faire et pourquoi.>

## Fichiers autorisés
- game/board/grille.gd (créer)
- tests/test_grille.gd (créer)

## À lire avant
- AGENTS.md
- game/core/events.gd

## Contrat
<Signatures exactes des classes/fonctions attendues, signaux émis, format des données.>

## Hors périmètre
<Ce qu'il ne faut surtout PAS faire.>

## Critère de fin
- `./scripts/tests.sh` au vert, avec les tests : …
```

## Modèles Codex disponibles (vérifiés le 2026-11-23)
`gpt-6.2-astra` (tâches complexes) · `gpt-6.2-sol` (standard) · `gpt-6-luna` (relectures légères).
