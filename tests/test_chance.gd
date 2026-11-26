extends RefCounted
## Vérifie la chance (benchmark D4) : poids des raretés, gain par vague propre, porte-bonheur.

const Lot = preload("res://game/core/lot.gd")
const Draft = preload("res://game/draft/draft.gd")
const CANON = preload("res://data/tuiles/tourelle_canon.tres")
const CARILLON = preload("res://data/tuiles/tourelle_carillon.tres")
const MORTIER = preload("res://data/tuiles/tourelle_mortier.tres")


func _lot(objet: Resource) -> Lot:
	var lot := Lot.new()
	lot.objet = objet
	lot.poids = 1.0
	return lot


## Avec beaucoup de chance, l'épique sort nettement plus souvent qu'à chance nulle.
func test_poids_des_raretes() -> String:
	var lots: Array[Lot] = [_lot(CANON), _lot(CARILLON), _lot(MORTIER)]
	var epique: Object = null
	for objet: Resource in [CANON, CARILLON, MORTIER]:
		if int(objet.get("rarete")) == 2:
			epique = objet
	if epique == null:
		return "Il faut une tourelle épique dans les données."
	var rng := RandomNumberGenerator.new()
	var compte := [0, 0]
	for i: int in 2:
		rng.seed = 7
		for essai: int in 600:
			if Draft.tirer(lots, 1, 9, rng, [], 0 if i == 0 else 8)[0].objet == epique:
				compte[i] += 1
	if compte[1] <= compte[0] * 1.5:
		return "La chance doit faire sortir l'épique bien plus souvent (%d contre %d)." % [compte[1], compte[0]]
	return ""


## Une vague tenue sans dégât donne de la chance ; le porte-bonheur s'achète une fois par pause et se paie.
func test_gains_de_chance() -> String:
	var run: Node = Engine.get_main_loop().root.get_node_or_null("Run")
	if run == null:
		return ""
	run.reinitialiser()
	var depart: int = run.chance
	run.choisir_lot(0)
	run.gagner(20)
	if not run.acheter_porte_bonheur() or run.chance != depart + run.regles.chance_porte_bonheur:
		return "Le porte-bonheur doit ajouter de la chance."
	if run.acheter_porte_bonheur():
		return "Le porte-bonheur ne s'achète qu'une fois par pause."
	run.lancer_vague()
	run.terminer_vague()
	if run.chance != depart + run.regles.chance_porte_bonheur + run.regles.chance_par_vague_propre:
		return "Une vague sans dégât doit donner de la chance."
	run.reinitialiser()
	return ""
