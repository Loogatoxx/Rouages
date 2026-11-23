extends Node3D
## Réunit le décor, le plateau manipulable, sa caméra et la palette provisoire.


func _ready() -> void:
	$TableGreybox.material_override = $PlateauNoeud/PlateauVisuel.materiau("bois_plateau")
	print("Rouages : scène principale chargée (phase %d)." % Run.phase)
