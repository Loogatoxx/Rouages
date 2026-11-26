extends Node
## Bus d'événements global (autoload « Events »).
##
## Pourquoi : les systèmes (plateau, nuées, interface…) se parlent par signaux sans se connaître.
## Règle : on n'ajoute un signal ici que s'il est écouté par au moins un AUTRE système.
## Chaque ajout est noté dans docs/architecture.md (section « Signaux »).

## Le plateau a changé (pose, rotation ou extension) : énergie et champ de flux à recalculer.
signal plateau_modifie
## L'énergie a été recalculée : `alimentees` contient les coordonnées (Vector2i) des tuiles alimentées.
signal energie_recalculee(alimentees: Array[Vector2i])
## La phase de la run change (voir Run.Phase).
signal phase_changee(nouvelle_phase: int)
## Une vague commence / se termine.
signal vague_commencee(numero: int)
signal vague_terminee(numero: int)
## L'horloge centrale perd des points de vie.
signal horloge_touchee(pv_restants: int)
## Le joueur sélectionne un objet de sa réserve (`id` = `objet.id` : tuile ou extension ; `&""` = désélection).
signal tuile_choisie(id: StringName)
## Fin de run.
signal run_terminee(victoire: bool)
