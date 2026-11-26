class_name Placement extends RefCounted
## Bonus et malus qui dépendent de la place d'une pièce : route, engrenages voisins, ateliers identiques collés.
##
## Pourquoi (playtest 1, benchmark `docs/benchmark_td.md` D1-D3) : le jeu récompensait le spam d'ateliers. Les cases ne
## se valent plus : bord de route ou arrière-garde, voisinage d'engrenages à identité, encombrement des ateliers collés.
## Logique pure (aucun autoload) : utilisée par la production, les tourelles, le banc d'équilibrage et l'infobulle.

const Plateau = preload("res://game/board/plateau.gd")
const PieceDef = preload("res://game/board/piece_def.gd")
const Regles = preload("res://game/core/regles.gd")
const VOISINS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## Au-delà de deux démultiplicateurs, plus aucun gain : on ne remplace pas un spam par un autre.
const CUMUL_DEMULTIPLICATEURS := 2


## Distance (en cases, de Manhattan) jusqu'à la case de chemin la plus proche ; -1 s'il n'y a pas de chemin.
static func distance_route(plateau: Plateau, case: Vector2i) -> int:
	var meilleure: int = -1
	for sol: Vector2i in plateau.coords_sols():
		if plateau.sol_de(sol) == Plateau.Sol.CHEMIN:
			var d: int = absi(sol.x - case.x) + absi(sol.y - case.y)
			if meilleure < 0 or d < meilleure:
				meilleure = d
	return meilleure


## Direction d'une case de chemin voisine (pour faire naître les jouets sur la route), ou Vector2i.ZERO.
static func cote_route(plateau: Plateau, case: Vector2i) -> Vector2i:
	for direction: Vector2i in VOISINS:
		if plateau.sol_de(case + direction) == Plateau.Sol.CHEMIN:
			return direction
	return Vector2i.ZERO


## Multiplicateur de cadence d'un atelier : démultiplicateurs voisins, arrière-garde, encombrement (jamais sous 0,4).
static func cadence_atelier(plateau: Plateau, alimentees: Dictionary, case: Vector2i, regles: Regles) -> float:
	var atelier: PieceDef = plateau.piece_de(case)
	var bonus: float = 0.0
	var demultiplicateurs: int = 0
	for direction: Vector2i in VOISINS:
		var voisin: PieceDef = plateau.piece_de(case + direction)
		if voisin == null:
			continue
		if voisin.bonus_voisins_cadence > 0.0 and alimentees.has(case + direction) \
				and demultiplicateurs < CUMUL_DEMULTIPLICATEURS:
			bonus += voisin.bonus_voisins_cadence
			demultiplicateurs += 1
		if atelier != null and voisin == atelier:
			bonus -= regles.malus_encombrement
	var distance: int = distance_route(plateau, case)
	if distance >= regles.distance_arriere:
		bonus += regles.bonus_arriere_cadence
	return maxf(0.4, 1.0 + bonus)


## Jouets en plus au plafond d'un atelier grâce aux répartiteurs voisins alimentés.
static func plafond_atelier(plateau: Plateau, alimentees: Dictionary, case: Vector2i) -> int:
	var bonus: int = 0
	for direction: Vector2i in VOISINS:
		var voisin: PieceDef = plateau.piece_de(case + direction)
		if voisin != null and voisin.bonus_voisins_plafond > 0 and alimentees.has(case + direction):
			bonus += voisin.bonus_voisins_plafond
	return bonus


## Multiplicateur de dégâts d'une tourelle : bonus si elle borde la route.
static func degats_tourelle(plateau: Plateau, case: Vector2i, regles: Regles) -> float:
	return 1.0 + (regles.bonus_route_degats if cote_route(plateau, case) != Vector2i.ZERO else 0.0)


## Multiplicateur de cadence de tir d'une tourelle grâce aux moyeux voisins alimentés.
static func cadence_tourelle(plateau: Plateau, alimentees: Dictionary, case: Vector2i) -> float:
	var bonus: float = 0.0
	for direction: Vector2i in VOISINS:
		var voisin: PieceDef = plateau.piece_de(case + direction)
		if voisin != null and voisin.bonus_voisins_tourelle > 0.0 and alimentees.has(case + direction):
			bonus += voisin.bonus_voisins_tourelle
	return 1.0 + bonus


## Lignes lisibles (clés de traduction déjà formatées) décrivant les effets de place d'une pièce posée ou à poser.
static func effets(plateau: Plateau, alimentees: Dictionary, case: Vector2i, piece: PieceDef, regles: Regles) -> PackedStringArray:
	var lignes := PackedStringArray()
	if piece == null:
		return lignes
	if piece.type == PieceDef.Type.ATELIER:
		var cadence: float = cadence_atelier(plateau, alimentees, case, regles)
		if not is_equal_approx(cadence, 1.0):
			lignes.append(TranslationServer.translate("Cadence %+d %%") % roundi((cadence - 1.0) * 100.0))
		if cote_route(plateau, case) != Vector2i.ZERO:
			lignes.append(TranslationServer.translate("Bord de route : jouets lâchés sur la route"))
		elif distance_route(plateau, case) >= regles.distance_arriere:
			lignes.append(TranslationServer.translate("Arrière-garde : production plus rapide"))
		var plafond: int = plafond_atelier(plateau, alimentees, case)
		if plafond > 0:
			lignes.append(TranslationServer.translate("Plafond +%d jouets") % plafond)
	elif piece.type == PieceDef.Type.TOURELLE:
		if cote_route(plateau, case) != Vector2i.ZERO:
			lignes.append(TranslationServer.translate("Bord de route : dégâts +%d %%") % roundi(regles.bonus_route_degats * 100.0))
		var tir: float = cadence_tourelle(plateau, alimentees, case)
		if tir > 1.0:
			lignes.append(TranslationServer.translate("Tir +%d %% (moyeu voisin)") % roundi((tir - 1.0) * 100.0))
	return lignes
