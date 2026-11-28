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
## Le stock de ressorts (monnaie de la run) a changé : `total` = nouveau solde.
signal ressorts_changes(total: int)
## Un ennemi vient d'être cassé à `position` (plan du plateau, mètres) : retour visuel et sonore.
signal ennemi_casse(position: Vector2)
## Le joueur demande la pause (Échap sans pièce sélectionnée, ou touche P).
signal pause_demandee
## Un retour court à montrer au joueur (action refusée, astuce) : `texte` est une clé de traduction déjà formatée.
signal message_joueur(texte: String)
## Coup de carillon (playtest 3) : le joueur veut viser (`carillon_vise`), puis l'Horloge sonne à `position`
## (mètres, plan du plateau) et étourdit les ennemis proches (`carillon_sonne`).
signal carillon_vise
## Rail (carte « Le Rail ») : un train vient de partir ; le visuel le fait rouler le long de la voie.
signal train_part
signal carillon_sonne(position: Vector2)
## Le joueur a repris une pièce posée (`def`) depuis la case `case` : elle retourne dans la réserve (PT-31).
signal piece_reprise(case: Vector2i, def: Resource)
