extends RefCounted
## Vérifie le tirage des lots, le stock de départ et le déroulement d'une partie.

const Lot = preload("res://game/core/lot.gd")
const Draft = preload("res://game/draft/draft.gd")
const Reserve = preload("res://game/core/reserve.gd")
const Plateau = preload("res://game/board/plateau.gd")
const ChampFlux = preload("res://game/swarm/champ_flux.gd")
const DEPART = preload("res://data/depart.tres")
const DROIT = preload("res://data/tuiles/engrenage_droit.tres")
const COUDE = preload("res://data/tuiles/engrenage_coude.tres")


func _lot(poids: float, vague_min: int = 1) -> Lot:
	var lot: Lot = Lot.new()
	lot.poids = poids
	lot.vague_min = vague_min
	return lot


## Les tirages respectent les filtres, la graine et l'absence de remise.
func test_tirage_sans_remise() -> String:
	var bons: Array[Lot] = [_lot(1), _lot(2), _lot(3), _lot(1, 2)]
	var lots: Array[Lot] = bons.duplicate()
	lots.append_array([_lot(0), _lot(-1), _lot(1, 3)])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for graine: int in range(32):
		rng.seed = graine
		var offre: Array[Lot] = Draft.tirer(lots, 3, 2, rng)
		if offre.size() != 3:
			return "Le tirage doit présenter trois lots."
		for lot: Lot in offre:
			if not bons.has(lot) or offre.count(lot) != 1:
				return "Lot indisponible ou présent deux fois."
		rng.seed = graine
		if Draft.tirer(lots, 3, 2, rng) != offre:
			return "La même graine doit reproduire le choix et son ordre."
	var tous: Array[Lot] = Draft.tirer(lots, 8, 2, rng)
	if tous.size() != bons.size():
		return "La petite pioche doit proposer tous ses lots disponibles."
	for lot: Lot in bons:
		if not tous.has(lot):
			return "Un lot disponible manque dans la petite pioche."
	return ""


## Un lot de poids trois sort environ trois fois plus souvent qu'un lot de poids un.
func test_tirage_pondere() -> String:
	var lots: Array[Lot] = [_lot(3), _lot(1)]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 520
	var frequents: int = 0
	for i: int in range(2000):
		if Draft.tirer(lots, 1, 1, rng)[0] == lots[0]:
			frequents += 1
	if frequents < 1400 or frequents > 1600:
		return "Le lot de poids trois est sorti %d fois sur 2 000." % frequents
	return ""


## La réserve trie les objets, compte chaque exemplaire et signale ses changements.
func test_reserve() -> String:
	var reserve: Reserve = Reserve.new()
	var avis: Array[int] = []
	var noter_stock: Callable = func() -> void: avis.append(reserve.quantite(DROIT.id))
	reserve.modifiee.connect(noter_stock)
	var erreur: String = _exercer_reserve(reserve)
	reserve.modifiee.disconnect(noter_stock)
	if erreur.is_empty() and avis != [1, 3, 3, 2, 1, 0]:
		return "Chaque modification effective doit signaler le nouveau stock."
	return erreur


func _exercer_reserve(reserve: Reserve) -> String:
	reserve.ajouter(DROIT)
	reserve.ajouter(DROIT, 2)
	reserve.ajouter(COUDE)
	if reserve.ids() != [COUDE.id, DROIT.id] or reserve.trouver(DROIT.id) != DROIT:
		return "La réserve doit présenter les deux définitions dans l'ordre des identifiants."
	for restant: int in [2, 1, 0]:
		if not reserve.retirer(DROIT.id) or reserve.quantite(DROIT.id) != restant:
			return "Chaque retrait doit consommer un seul exemplaire."
	if reserve.retirer(DROIT.id) or reserve.ids() != [COUDE.id] or reserve.trouver(DROIT.id) != null:
		return "Un objet épuisé doit disparaître du stock."
	return ""


## Le terrain initial conserve ses 81 cases, son horloge, ses entrées et ses pièces.
func test_depart() -> String:
	var plateau: Plateau = DEPART.creer_plateau()
	if plateau.coords_sols().size() != 81 or plateau.coords_pieces() != [Vector2i.ZERO]:
		return "Le plateau doit démarrer avec 81 cases et une pièce au centre."
	if plateau.piece_de(Vector2i.ZERO).id != &"horloge":
		return "La pièce au centre doit être l'horloge."
	for x: int in range(-4, 5):
		for y: int in range(-4, 5):
			var chemin: bool = x == 4 or (y == 0 and x > 0)
			var sol: int = Plateau.Sol.CHEMIN if chemin else Plateau.Sol.HERBE
			if plateau.sol_de(Vector2i(x, y)) != sol:
				return "Le sol de la case (%d, %d) ne correspond pas au terrain initial." % [x, y]
	if ChampFlux.entrees(plateau, ChampFlux.calculer(plateau)) != [Vector2i(4, -4), Vector2i(4, 4)]:
		return "Les deux entrées doivent se trouver aux extrémités du chemin."
	var reserve: Reserve = Reserve.new()
	reserve.ajouter_lots(DEPART.reserve)
	return _verifier_reserve_initiale(reserve)


func _verifier_reserve_initiale(reserve: Reserve) -> String:
	if reserve.ids() != [&"atelier_soldats", COUDE.id, DROIT.id]:
		return "Objets de départ inattendus."
	if reserve.quantite(&"atelier_soldats") != 1 or reserve.quantite(DROIT.id) != 2 or reserve.quantite(COUDE.id) != 1:
		return "Quantités initiales incorrectes."
	return ""


## Chaque vague exige un choix et une construction avant la victoire finale.
func test_cycle_de_la_run() -> String:
	Run.reinitialiser()
	var fins_vagues: Array[int] = []
	var fins_run: Array[bool] = []
	var noter_vague: Callable = func(n: int) -> void: fins_vagues.append(n)
	var noter_fin: Callable = func(victoire: bool) -> void: fins_run.append(victoire)
	Events.vague_terminee.connect(noter_vague)
	Events.run_terminee.connect(noter_fin)
	var erreur: String = _parcourir_run()
	Events.vague_terminee.disconnect(noter_vague)
	Events.run_terminee.disconnect(noter_fin)
	if erreur.is_empty() and (fins_vagues != range(1, 11) or fins_run != [true]):
		erreur = "Chaque vague doit annoncer sa fin, puis la victoire doit être émise une fois."
	Run.reinitialiser()
	return erreur


func _parcourir_run() -> String:
	if Run.vague_actuelle != 0 or Run.nb_vagues != 10 or Run.pv_horloge != Run.regles.pv_horloge:
		return "La run doit démarrer avec dix vagues et une horloge intacte."
	var erreur: String = _verifier_reserve_initiale(Run.reserve)
	if not erreur.is_empty():
		return erreur
	for numero: int in range(1, Run.nb_vagues + 1):
		Run.terminer_vague()
		Run.lancer_vague()
		Run.choisir_lot(-1)
		Run.choisir_lot(Run.offre.size())
		if Run.phase != Run.Phase.DRAFT or Run.offre.size() != 3:
			return "Trois lots doivent être proposés avant la vague %d." % numero
		var lot: Lot = Run.offre[1]
		var id: StringName = lot.objet.get("id")
		var attendu: int = Run.reserve.quantite(id) + lot.quantite
		Run.choisir_lot(1)
		Run.choisir_lot(0)
		Run.terminer_vague()
		if Run.phase != Run.Phase.CONSTRUCTION or not Run.offre.is_empty() or Run.reserve.quantite(id) != attendu:
			return "Le choix doit créditer exactement un lot et ouvrir la construction."
		Run.lancer_vague()
		if Run.phase != Run.Phase.VAGUE or Run.vague_actuelle != numero:
			return "La construction doit lancer la vague %d." % numero
		Run.terminer_vague()
	Run.terminer_vague()
	if Run.phase != Run.Phase.FIN or not Run.offre.is_empty():
		return "La dernière vague doit clore la run."
	return ""


## Playtest 1 : un même objet n'apparaît jamais deux fois dans une offre, ni dans un coffre.
func test_pas_de_doublon_par_objet() -> String:
	var lots: Array[Lot] = []
	for objet: Resource in [DROIT, DROIT, COUDE, DROIT]:
		var lot: Lot = _lot(1)
		lot.objet = objet
		lots.append(lot)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for graine: int in range(32):
		rng.seed = graine
		var offre: Array[Lot] = Draft.tirer(lots, 3, 1, rng)
		if offre.size() != 2:
			return "Deux objets distincts seulement : l'offre doit en montrer deux."
		if offre[0].objet == offre[1].objet:
			return "Le même objet est proposé deux fois."
	var regles: Resource = load("res://data/regles.tres")
	for graine: int in range(64):
		rng.seed = graine
		var vus: Array = []
		for i: int in 3:
			for lot: Lot in Draft.tirer(regles.coffre, 1, 9, rng, vus):
				if vus.has(lot.objet):
					return "Le coffre a proposé deux fois le même objet."
				vus.append(lot.objet)
	return ""
