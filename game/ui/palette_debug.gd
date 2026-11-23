extends HBoxContainer
## Présente les tuiles disponibles et transmet la sélection au contrôleur.

const PieceDef = preload("res://game/board/piece_def.gd")
const DOSSIER := "res://data/tuiles/"
var _boutons: Dictionary[StringName, Button] = {}


func _ready() -> void:
	var fichiers: PackedStringArray = ResourceLoader.list_directory(DOSSIER)
	fichiers.sort()
	for fichier: String in fichiers:
		if fichier.get_extension() != "tres":
			continue
		var piece: PieceDef = load(DOSSIER + fichier) as PieceDef
		if piece == null or piece.type == PieceDef.Type.HORLOGE:
			continue
		var id := StringName(fichier.get_basename())
		var bouton := Button.new()
		bouton.text = piece.nom
		bouton.toggle_mode = true
		bouton.focus_mode = Control.FOCUS_NONE
		bouton.pressed.connect(Events.tuile_choisie.emit.bind(id))
		add_child(bouton)
		_boutons[id] = bouton
	Events.tuile_choisie.connect(_afficher_selection)


func _afficher_selection(id: StringName) -> void:
	for cle: StringName in _boutons:
		_boutons[cle].set_pressed_no_signal(cle == id)
