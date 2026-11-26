extends CanvasLayer
## Guide la première partie avec une bulle que le joueur peut fermer à tout moment.

const Interface = preload("res://game/ui/menu_titre.gd")
const PlateauNoeud = preload("res://game/board/plateau_noeud.gd")
const PieceDef = preload("res://game/board/piece_def.gd")

const CONSEILS: Array[String] = [
	"Choisis un lot pour ajouter ses pièces à ta réserve.",
	"Clique sur une pièce de la réserve, puis sur une case pour la poser. R ou le clic droit la fait tourner. Relie un atelier à l’horloge par des engrenages.",
	"Ton atelier remonte des soldats ! Lance la vague.",
	"Les scarabées suivent le chemin. Appuie sur Espace pour passer en x2, ou sur Échap pour faire une pause.",
	"Tu as gagné des ressorts ! Après le tirage, dépense-les à la boutique pour acheter des pièces ou réparer l’horloge."
]

@onready var _source: PlateauNoeud = $"../PlateauNoeud"
var _etape: int = 0
var _atelier_pret: bool = false
var _termine: bool = false


func _ready() -> void:
	var fichier := ConfigFile.new()
	if fichier.load(Interface.REGLAGES) == OK and fichier.get_value("tutoriel", "vu", false) == true:
		return
	Interface.preparer_boutons(self)
	%Compris.pressed.connect(_comprendre)
	%Passer.pressed.connect(_terminer)
	Events.phase_changee.connect(_changer_phase)
	Events.energie_recalculee.connect(_verifier_ateliers)
	Events.vague_terminee.connect(_fin_vague)
	_changer_phase(Run.phase)


func _changer_phase(phase: int) -> void:
	if _termine:
		return
	_placer_conseil(phase == Run.Phase.DRAFT)
	if phase == Run.Phase.FIN:
		%Panneau.hide()
	elif phase == Run.Phase.DRAFT and Run.vague_actuelle == 0:
		_montrer(1)
	elif phase == Run.Phase.CONSTRUCTION and Run.vague_actuelle == 0:
		_montrer(2)
		_atelier_pret = _contient_atelier(_source.alimentees.keys())
	elif phase == Run.Phase.VAGUE and Run.vague_actuelle == 1:
		_montrer(4)


func _placer_conseil(tirage: bool) -> void:
	var panneau: PanelContainer = %Panneau
	var colonne: BoxContainer = $Panneau/Colonne
	colonne.vertical = not tirage
	if tirage:
		panneau.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		panneau.offset_left = 20
		panneau.offset_right = -20
		panneau.offset_bottom = -12
		panneau.grow_vertical = Control.GROW_DIRECTION_BEGIN
	else:
		panneau.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		panneau.offset_left = 20
		panneau.offset_right = 374
		panneau.offset_top = 12
		panneau.grow_vertical = Control.GROW_DIRECTION_END
	panneau.reset_size.call_deferred()


func _verifier_ateliers(alimentees: Array[Vector2i]) -> void:
	if _termine or _etape != 2 or Run.phase != Run.Phase.CONSTRUCTION:
		return
	_atelier_pret = _contient_atelier(alimentees)
	if _atelier_pret:
		_montrer(3)


func _contient_atelier(alimentees: Array) -> bool:
	for case_alimentee: Vector2i in alimentees:
		var piece: PieceDef = _source.plateau.piece_de(case_alimentee)
		if piece != null and piece.type == PieceDef.Type.ATELIER:
			return true
	return false


func _fin_vague(numero: int) -> void:
	if numero == 1:
		_montrer(5)


func _montrer(etape: int) -> void:
	if _termine or etape <= _etape:
		return
	_etape = etape
	_actualiser_textes()
	%Panneau.show()
	Interface.apparaitre(%Panneau)


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and _etape > 0:
		_actualiser_textes()


func _actualiser_textes() -> void:
	%Etape.text = tr("Tutoriel   ·   %d / %d") % [_etape, CONSEILS.size()]
	%Conseil.text = tr(CONSEILS[_etape - 1])
	# Recalcul après la mise en page : sinon le panneau garde la hauteur d'un texte non encore replié.
	%Panneau.reset_size.call_deferred()


func _comprendre() -> void:
	if _etape == CONSEILS.size():
		_terminer()
	elif _etape == 2 and _atelier_pret:
		_montrer(3)
	else:
		%Panneau.hide()


func _terminer() -> void:
	if Interface.regler_tutoriel(true):
		_termine = true
		%Panneau.hide()
