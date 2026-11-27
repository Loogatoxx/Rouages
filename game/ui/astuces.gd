extends PanelContainer
## Astuces contextuelles : chaque nouveauté est expliquée une seule fois, au moment où elle sert (benchmark D7).
##
## Pourquoi (GDC Plants vs. Zombies, `docs/benchmark_td.md` D7) : introduire une mécanique à la fois, au bon moment,
## plutôt qu'un long tutoriel. Les astuces vues sont mémorisées dans `user://reglages.cfg` (section « astuces »).

const Interface = preload("res://game/ui/menu_titre.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const TEXTES := {
	&"placement": "La place compte : survole une case avec une pièce en main pour voir ses bonus (bord de route, arrière-garde, engrenages voisins).",
	&"panneau": "Clique sur une pièce posée pour l’améliorer, la tourner ou la reprendre.",
	&"libellule": "Des libellules volent ! Les soldats ne peuvent pas les toucher : pose des lance-billes ou des tourelles.",
	&"chance": "Le trèfle montre ta chance : plus elle est haute, plus les coffres proposent de raretés.",
	&"craft": "Tu peux assembler des pièces en trop (bouton « Assembler ») ou en démonter une d’un clic droit contre des ressorts.",
	&"dents": "L’Horloge n’a qu’un nombre limité de dents d’énergie (la roue dentée en haut). Un atelier en prend 2, une petite tourelle 1 : choisis bien, puis améliore.",
	&"poste": "Chaque escouade tient la route devant son atelier, là où flotte son fanion. Clique sur l’atelier puis sur le fanion du panneau pour choisir une autre case.",
}

var plateau_noeud: Node
var _texte := Label.new()
var _file: Array[StringName] = []
var _cle: StringName = &""


func _ready() -> void:
	theme = preload("res://game/ui/theme_rouages.tres")
	theme_type_variation = &"Fiche"
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()
	var colonne := VBoxContainer.new()
	add_child(colonne)
	_texte.theme_type_variation = &"CarteTexte"
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(_texte)
	var compris := Button.new()
	compris.text = tr("Compris")
	compris.size_flags_horizontal = Control.SIZE_SHRINK_END
	Interface.preparer_bouton(compris)
	compris.pressed.connect(_fermer)
	colonne.add_child(compris)
	Events.phase_changee.connect(_sur_phase)
	Events.vague_commencee.connect(_sur_vague)
	Events.ressorts_changes.connect(func(_total: int) -> void: _verifier_chance())
	Events.tuile_choisie.connect(_sur_choix)


## Met l'astuce en file si elle n'a jamais été vue ; une seule fiche à la fois.
func proposer(cle: StringName) -> void:
	if deja_vue(cle) or cle == _cle or cle in _file:
		return
	_file.append(cle)
	if not visible:
		_suivante()


static func deja_vue(cle: StringName) -> bool:
	var fichier := ConfigFile.new()
	fichier.load(Interface.REGLAGES)
	return fichier.get_value("astuces", String(cle), false)


func _suivante() -> void:
	if _file.is_empty():
		_cle = &""
		hide()
		return
	_cle = _file.pop_front()
	_texte.text = tr(TEXTES[_cle])
	Interface.caler_hauteur(_texte, 440.0)
	reset_size()
	var cadre: Rect2 = get_viewport().get_visible_rect()
	position = Vector2((cadre.size.x - size.x) / 2.0, cadre.size.y - size.y - 130.0)
	show()
	Interface.apparaitre(self)


func _fermer() -> void:
	var fichier := ConfigFile.new()
	fichier.load(Interface.REGLAGES)
	fichier.set_value("astuces", String(_cle), true)
	fichier.save(Interface.REGLAGES)
	_suivante()


func _sur_phase(phase: int) -> void:
	# Playtest 3 : les deux règles de « Tenir la ligne » s'expliquent dès la première construction.
	if phase == Run.Phase.CONSTRUCTION and Run.dents >= 0:
		proposer(&"dents")
		if Run.vague_actuelle >= 1:
			proposer(&"poste")
	if phase != Run.Phase.CONSTRUCTION or Run.vague_actuelle < 1:
		return
	if plateau_noeud != null and plateau_noeud.plateau.coords_pieces().size() > 1:
		proposer(&"panneau")
	for recette: Resource in Run.regles.get("recettes"):
		if Run.has_method("peut_assembler") and Run.peut_assembler(recette):
			proposer(&"craft")
			break


func _sur_vague(numero: int) -> void:
	var vague: Resource = Run.vagues[numero - 1]
	if int(vague.get("nombre_volants")) > 0:
		proposer(&"libellule")


func _verifier_chance() -> void:
	if Run.chance > 0:
		proposer(&"chance")


func _sur_choix(id: StringName) -> void:
	var piece: PieceDef = Run.reserve.trouver(id) as PieceDef
	if piece != null and piece.type != PieceDef.Type.ENGRENAGE and Run.vague_actuelle >= 1:
		proposer(&"placement")
