extends Node3D
## Réunit le plateau jouable et les visuels qui affichent son état.


func _ready() -> void:
	$NueeVisuel.sim = $Partie.sim
	$TableGreybox.material_override = $PlateauNoeud/PlateauVisuel.materiau("bois_plateau")
	print("Rouages : scène principale chargée (phase %d)." % Run.phase)
