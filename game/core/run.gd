extends Node
## Conserve les PV de l'horloge et publie les transitions de la partie.

const Progression = preload("res://game/core/progression.gd")
const Plateau = preload("res://game/board/plateau.gd")
const Regles = preload("res://game/core/regles.gd")
const VagueDef = preload("res://game/waves/vague_def.gd")
const UniteDef = preload("res://game/swarm/unite_def.gd")

const DepartDef = preload("res://game/core/depart_def.gd")
const Reserve = preload("res://game/core/reserve.gd")
const Lot = preload("res://game/core/lot.gd")
const Draft = preload("res://game/draft/draft.gd")

enum Phase { DRAFT, CONSTRUCTION, VAGUE, FIN }

var regles: Regles = preload("res://data/regles.tres")
var depart: DepartDef = regles.departs[0]
var defi_du_jour: bool = false
var _graine_defi: int
var reserve: Reserve = Reserve.new()
var offre: Array[Lot] = []
var offre_coffre: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var vagues: Array[VagueDef]:
	get:
		return regles.vagues
var nb_vagues: int:
	get:
		return vagues.size()
var pv_max: int = regles.pv_horloge
var pv_horloge: int = pv_max
var choix_par_draft: int = regles.choix_par_draft
var bonus_cadence: float = 1.0
var engrenages_gagnes: int = 0
var _rente: int
var _relance_offerte: bool
var _relance_disponible: bool
var prix_relance: int:
	get:
		return 0 if _relance_disponible else regles.prix_relance
var phase: Phase = Phase.DRAFT
var vague_actuelle: int = 0
var ressorts: int = regles.ressorts_depart
var ennemis_casses: int = 0
var ressorts_gagnes: int = 0
var derniere_recompense: int = 0
var vitesse: float = 1.0
## Somme des rentes des extensions posées, versée à chaque fin de vague.
var revenu_extensions: int = 0
var _pv_debut_vague: int


func _ready() -> void:
	reinitialiser()


## Crédite les ressorts reçus et les compte dans les gains de la partie.
func gagner(n: int) -> void:
	if n < 0:
		return
	ressorts += n
	ressorts_gagnes += n
	Events.ressorts_changes.emit(ressorts)


## Prélève le prix si le solde permet de le payer en entier.
func depenser(n: int) -> bool:
	if n < 0 or ressorts < n:
		return false
	ressorts -= n
	Events.ressorts_changes.emit(ressorts)
	return true


## Prix actuel d'une rotation de pièce posée : gratuite pendant la préparation (avant la vague 1), payante ensuite.
## Pourquoi : on démarre à 0 ressort ; une rotation payante dès le départ était refusée sans un mot (playtest 1 :
## « la rotation a disparu »). Avant la vague 1, on peut encore tout réorganiser librement.
var prix_rotation: int:
	get:
		return 0 if vague_actuelle == 0 else regles.prix_rotation


## Tourne une pièce posée (jamais l'horloge) et prélève le prix si la rotation a abouti.
func tourner_piece(plateau: Plateau, case: Vector2i) -> bool:
	var prix: int = prix_rotation
	var piece: Plateau.PieceDef = plateau.piece_de(case)
	if piece == null or piece.type == Plateau.PieceDef.Type.HORLOGE:
		return false
	if prix < 0 or ressorts < prix or not plateau.tourner(case):
		return false
	return depenser(prix)


## Achète un lot disponible pour la prochaine vague et le range dans la réserve.
func acheter(i: int) -> bool:
	if phase != Phase.CONSTRUCTION or i < 0 or i >= regles.boutique.size():
		return false
	var lot: Lot = regles.boutique[i]
	if lot.vague_min > vague_actuelle + 1 or not depenser(lot.prix):
		return false
	reserve.ajouter(lot.objet, lot.quantite)
	return true


func _tirer_offre() -> void:
	offre_coffre = vague_actuelle > 0 and vague_actuelle in regles.vagues_coffre
	if offre_coffre:
		# Chaque carte a son tirage pour que la rareté compte même avec trois modèles.
		offre.clear()
		for i: int in choix_par_draft:
			offre.append_array(Draft.tirer(regles.coffre, 1, vague_actuelle + 1, rng))
	else:
		offre = Draft.tirer(regles.pioche, choix_par_draft, vague_actuelle + 1, rng)


## Paie un nouveau tirage et présente les lots dans la même phase de draft.
func relancer_offre() -> bool:
	if phase != Phase.DRAFT or not depenser(prix_relance):
		return false
	_relance_disponible = false
	_tirer_offre()
	Events.phase_changee.emit(Phase.DRAFT)
	return true


## Répare l'horloge en construction et publie le solde une fois les PV restaurés.
func reparer_horloge() -> bool:
	if phase != Phase.CONSTRUCTION or pv_horloge >= pv_max:
		return false
	var prix: int = regles.prix_reparation
	if prix < 0 or ressorts < prix:
		return false
	pv_horloge = mini(pv_horloge + regles.pv_reparation, pv_max)
	return depenser(prix)


## Applique les gains d'une extension posée : ressorts immédiats et rente de fin de vague.
func poser_extension(ressorts_pose: int, revenu: int) -> void:
	revenu_extensions += maxi(0, revenu)
	gagner(ressorts_pose)


## Comptabilise un ennemi cassé et verse le butin de son modèle.
func casser_ennemi(def: UniteDef, position: Vector2) -> void:
	ennemis_casses += 1
	gagner(def.butin)
	Events.ennemi_casse.emit(position)


## Bascule entre le rythme normal et le rythme accéléré de la simulation.
func basculer_vitesse() -> void:
	vitesse = regles.multiplicateur_acceleration if vitesse == 1.0 else 1.0


## Ajoute le lot choisi à la réserve et ouvre la construction.
func choisir_lot(i: int) -> void:
	if phase != Phase.DRAFT or i < 0 or i >= offre.size():
		return
	var lot: Lot = offre[i]
	offre.clear()
	reserve.ajouter(lot.objet, lot.quantite)
	changer_phase(Phase.CONSTRUCTION)


## Change de phase et prévient les systèmes qui en dépendent.
func changer_phase(nouvelle: Phase) -> void:
	if nouvelle != phase:
		phase = nouvelle
		Events.phase_changee.emit(phase)


## Lance la prochaine vague après la construction.
func lancer_vague() -> void:
	if phase != Phase.CONSTRUCTION or vague_actuelle >= nb_vagues:
		return
	vague_actuelle += 1
	_pv_debut_vague = pv_horloge
	changer_phase(Phase.VAGUE)
	Events.vague_commencee.emit(vague_actuelle)


## Retire les PV dus à une arrivée et annonce la défaite au dernier point perdu.
func subir_degats(d: float) -> void:
	if phase != Phase.VAGUE or d <= 0.0:
		return
	pv_horloge = maxi(0, pv_horloge - ceili(d))
	Events.horloge_touchee.emit(pv_horloge)
	if pv_horloge == 0:
		_terminer_partie(false)


## Clôt la vague, puis propose un nouveau tirage ou annonce la victoire.
func terminer_vague() -> void:
	if phase != Phase.VAGUE:
		return
	derniere_recompense = regles.recompense_vague + regles.recompense_par_vague * (vague_actuelle - 1)
	derniere_recompense += revenu_extensions + _rente
	if pv_horloge == _pv_debut_vague:
		derniere_recompense += regles.bonus_sans_degat
	gagner(derniere_recompense)
	Events.vague_terminee.emit(vague_actuelle)
	if vague_actuelle == nb_vagues:
		_terminer_partie(true)
	else:
		_relance_disponible = _relance_offerte
		_tirer_offre()
		changer_phase(Phase.DRAFT)


func _terminer_partie(victoire: bool) -> void:
	if not defi_du_jour:
		var vagues_tenues: int = vague_actuelle if victoire else maxi(0, vague_actuelle - 1)
		var gain: int = vagues_tenues * regles.engrenages_par_vague
		if victoire:
			gain += regles.engrenages_victoire
		if Progression.gagner(gain):
			engrenages_gagnes = gain
	changer_phase(Phase.FIN)
	Events.run_terminee.emit(victoire)


## Sélectionne le plateau de la prochaine partie libre.
func choisir_depart(i: int) -> void:
	if i >= 0 and i < regles.departs.size():
		depart = regles.departs[i]
		defi_du_jour = false


## Renvoie la graine commune aux parties jouées pour cette date.
func graine_du_jour(date: String) -> int:
	return hash(date)


## Sélectionne le plateau et mémorise la graine du défi pour le prochain départ.
func preparer_defi(date: String) -> void:
	_graine_defi = graine_du_jour(date)
	depart = regles.departs[posmod(_graine_defi, regles.departs.size())]
	defi_du_jour = true


func _bonus(effet: StringName) -> float:
	return 0.0 if defi_du_jour else Progression.bonus(effet)


## Restaure l'horloge et la réserve, puis propose les lots de la première vague.
func reinitialiser() -> void:
	if defi_du_jour:
		rng.seed = _graine_defi
		seed(_graine_defi)
	else:
		rng.randomize()
		randomize()
	vague_actuelle = 0
	pv_max = regles.pv_horloge + int(_bonus(&"pv_horloge"))
	pv_horloge = pv_max
	choix_par_draft = regles.choix_par_draft + int(_bonus(&"choix_draft"))
	bonus_cadence = 1.0 + _bonus(&"cadence_ateliers")
	_rente = int(_bonus(&"rente"))
	_relance_offerte = _bonus(&"relance_offerte") > 0.0
	_relance_disponible = _relance_offerte
	engrenages_gagnes = 0
	_pv_debut_vague = pv_horloge
	ressorts = regles.ressorts_depart + int(_bonus(&"ressorts_depart"))
	ennemis_casses = 0
	ressorts_gagnes = 0
	derniere_recompense = 0
	vitesse = 1.0
	revenu_extensions = 0
	reserve.vider()
	reserve.ajouter_lots(depart.reserve)
	_tirer_offre()
	phase = Phase.DRAFT
	Events.ressorts_changes.emit(ressorts)
	Events.phase_changee.emit(phase)
