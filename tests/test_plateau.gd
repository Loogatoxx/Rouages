extends RefCounted

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const COUDE: PieceDef = preload("res://data/tuiles/engrenage_coude.tres")

var _changements: int = 0


func test_rotation_ports() -> String:
	if PieceDef.tourner_ports(3, 1) != 6 or PieceDef.tourner_ports(3, 4) != 3:
		return "rotation du coude incorrecte"
	for r: int in range(4):
		if PieceDef.tourner_ports(15, r) != 15:
			return "la croix doit conserver ses quatre ports"
	return ""


func test_pose_sol_rotation_et_signal() -> String:
	var plateau: Plateau = Plateau.new()
	var case_sol: Vector2i = Vector2i.ZERO
	_changements = 0
	plateau.modifie.connect(func() -> void: _changements += 1)
	if plateau.a_sol(case_sol) or plateau.sol_de(case_sol) != -1 or plateau.ports_de(case_sol) != 0:
		return "état initial de la case incorrect"
	if plateau.poser(case_sol, COUDE) or plateau.tourner(case_sol) or _changements != 0:
		return "modification hors sol"
	plateau.ajouter_sol(case_sol, Plateau.Sol.CHEMIN)
	if plateau.poser(case_sol, COUDE) or _changements != 1:
		return "pose sur le chemin ou signal inattendu"
	plateau.ajouter_sol(case_sol, Plateau.Sol.HERBE)
	if not plateau.poser(case_sol, COUDE, 3) or _changements != 3:
		return "pose sur herbe ou signal manquant"
	if plateau.poser(case_sol, COUDE) or _changements != 3:
		return "seconde pose sur une case occupée"
	if plateau.piece_de(case_sol) != COUDE or plateau.ports_de(case_sol) != 9:
		return "pièce ou orientation initiale incorrecte"
	if not plateau.tourner(case_sol) or plateau.rotation_de(case_sol) != 0 or _changements != 4:
		return "rotation ou signal incorrect"
	return ""


func test_definitions_des_tuiles() -> String:
	var dossier: String = "res://data/tuiles/"
	var attendues: Array[String] = [
		"horloge", "engrenage_droit", "engrenage_coude", "engrenage_t", "engrenage_croix", "atelier_soldats"
	]
	for fichier: String in DirAccess.get_files_at(dossier):
		if fichier.get_extension() != "tres":
			continue
		var piece: PieceDef = load(dossier + fichier) as PieceDef
		if piece == null or piece.id != fichier.get_basename():
			return "définition ou identifiant incorrect pour " + fichier
		attendues.erase(fichier.get_basename())
	return "" if attendues.is_empty() else "tuiles manquantes : " + str(attendues)
