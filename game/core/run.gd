extends Node
## État de la run en cours (autoload « Run ») : machine à états minimale.
##
## Pourquoi une machine à états : à tout instant le jeu est dans UNE seule phase,
## et chaque système sait ce qu'il a le droit de faire (ex. : pas de pose de tuile pendant une vague).
## Les transitions détaillées seront codées à l'étape 5 ; ce squelette fixe le contrat.

enum Phase { DRAFT, CONSTRUCTION, VAGUE, FIN }

const NB_VAGUES := 10

var phase: Phase = Phase.DRAFT
var vague_actuelle: int = 0


## Change de phase et prévient tout le monde via le bus d'événements.
func changer_phase(nouvelle: Phase) -> void:
	if nouvelle == phase:
		return
	phase = nouvelle
	Events.phase_changee.emit(phase)


## Remet la run à zéro (bouton « rejouer »).
func reinitialiser() -> void:
	vague_actuelle = 0
	phase = Phase.DRAFT
	Events.phase_changee.emit(phase)
