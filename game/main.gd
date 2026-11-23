extends Node3D
## Scène principale. Pour l'instant : décor de test (sol, lumière chaude, caméra de dessus).
## Les systèmes (plateau, nuées, interface) y seront ajoutés étape par étape.


func _ready() -> void:
	print("Rouages : scène principale chargée (phase %d)." % Run.phase)
