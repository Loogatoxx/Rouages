extends RefCounted
## Vérifie les échanges de la réserve entre deux vagues.

const Partie = preload("res://game/core/run.gd")
const RecetteDef = preload("res://game/core/recette_def.gd")
const Lot = preload("res://game/core/lot.gd")


## Chaque recette consomme ses ingrédients et livre exactement son produit.
func test_assembler_recettes() -> String:
	var partie := Partie.new()
	partie.phase = Partie.Phase.CONSTRUCTION
	var erreur: String = ""
	for recette: RecetteDef in partie.regles.recettes:
		partie.reserve.vider()
		partie.reserve.ajouter_lots(recette.entrees)
		if not partie.peut_assembler(recette) or not partie.assembler(recette):
			erreur = "Assemblage refusé pour %s" % recette.id
			break
		if partie.reserve.ids().size() != 1 or partie.reserve.quantite(recette.sortie.objet.get("id")) != recette.sortie.quantite:
			erreur = "Stock incorrect après assemblage de %s" % recette.id
			break
	partie.free()
	return erreur


## Un ingrédient manquant ou une phase interdite laisse le stock intact.
func test_refus_assemblage() -> String:
	var partie := Partie.new()
	var recette: RecetteDef = partie.regles.recettes[0]
	var entree: Lot = recette.entrees[0]
	var id: StringName = entree.objet.get("id")
	partie.phase = Partie.Phase.CONSTRUCTION
	partie.reserve.ajouter(entree.objet, entree.quantite - 1)
	var refus: bool = not partie.peut_assembler(recette) and not partie.assembler(recette)
	refus = refus and partie.reserve.quantite(id) == entree.quantite - 1
	partie.reserve.ajouter(entree.objet)
	for phase: Partie.Phase in [Partie.Phase.DRAFT, Partie.Phase.VAGUE, Partie.Phase.FIN]:
		partie.phase = phase
		refus = refus and not partie.peut_assembler(recette) and not partie.assembler(recette)
	refus = refus and partie.reserve.quantite(id) == entree.quantite and partie.reserve.ids().size() == 1
	partie.free()
	return "" if refus else "Une recette impossible a été proposée ou a modifié la réserve"


## Le démontage enlève une pièce, crédite les gains et protège les extensions.
func test_demonter() -> String:
	var partie := Partie.new()
	var objet: Resource = partie.regles.recettes[0].entrees[0].objet
	var id: StringName = objet.get("id")
	var extension: Resource = preload("res://data/extensions/sentier.tres")
	var valeur: int = partie.regles.demontage_engrenage
	var avant: int = partie.ressorts
	partie.reserve.ajouter(objet, 2)
	partie.reserve.ajouter(extension)
	partie.phase = Partie.Phase.VAGUE
	var correct: bool = not partie.demonter(id)
	partie.phase = Partie.Phase.CONSTRUCTION
	correct = correct and partie.demonter(id) and not partie.demonter(extension.get("id"))
	correct = correct and partie.reserve.quantite(id) == 1 and partie.reserve.quantite(extension.get("id")) == 1
	correct = correct and partie.ressorts == avant + valeur and partie.ressorts_gagnes == valeur
	partie.free()
	return "" if correct else "Le démontage a modifié le mauvais stock ou crédité un gain incorrect"
