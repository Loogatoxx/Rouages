extends RefCounted
## Vérifie la reprise des pièces et le remontage des ateliers déplacés.

const EtatPartie = preload("res://game/core/run.gd")
const Plateau = preload("res://game/board/plateau.gd")
const Production = preload("res://game/workshops/production.gd")
const Engrenage = preload("res://data/tuiles/engrenage_droit.tres")
const Atelier = preload("res://data/tuiles/atelier_soldats.tres")
const ReglesJeu = preload("res://data/regles.tres")


## Vérifie la gratuité initiale, la progression des prix et les remises à zéro.
func test_prix_deplacement() -> String:
	var partie := EtatPartie.new()
	var resultat: String = _verifier_prix(partie)
	partie.free()
	return resultat


func _verifier_prix(partie: EtatPartie) -> String:
	partie.reinitialiser()
	partie.phase = EtatPartie.Phase.CONSTRUCTION
	partie.ressorts = 0
	var plateau := Plateau.new()
	var case := Vector2i.ZERO
	plateau.ajouter_sol(case, Plateau.Sol.HERBE)
	plateau.poser(case, Engrenage, 2)
	var stock: int = partie.reserve.quantite(Engrenage.id)
	if not partie.reprendre_piece(plateau, case) or partie.ressorts != 0:
		return "La reprise doit être gratuite avant la vague 1."
	if plateau.piece_de(case) != null or plateau.rotation_de(case) != 0 or partie.reserve.quantite(Engrenage.id) != stock + 1:
		return "La pièce doit quitter le plateau et rejoindre la réserve."
	partie.lancer_vague()
	partie.ressorts = 8
	for prix: int in [3, 5]:
		var solde: int = partie.ressorts
		plateau.poser(case, Engrenage)
		if partie.prix_deplacement != prix or not partie.reprendre_piece(plateau, case) or partie.ressorts != solde - prix:
			return "Prix de reprise incorrect en vague 1."
	partie.phase = EtatPartie.Phase.CONSTRUCTION
	partie.lancer_vague()
	if partie.deplacements_pause != 0 or partie.prix_deplacement != 3:
		return "Le lancement doit rétablir le tarif initial."
	partie.deplacements_pause = 2
	partie.reinitialiser()
	if partie.deplacements_pause != 0:
		return "Une nouvelle partie doit remettre le compteur à zéro."
	return ""


## Vérifie que les refus laissent les pièces, les ressorts et le tarif intacts.
func test_refus_reprise() -> String:
	var partie := EtatPartie.new()
	var plateau := Plateau.new()
	var case := Vector2i.ZERO
	var horloge := Plateau.PieceDef.new()
	horloge.type = Plateau.PieceDef.Type.HORLOGE
	plateau.ajouter_sol(case, Plateau.Sol.HERBE)
	plateau.poser(case, Engrenage, 1)
	partie.phase = EtatPartie.Phase.CONSTRUCTION
	partie.vague_actuelle = 1
	partie.ressorts = 2
	var refus: bool = not partie.reprendre_piece(plateau, case)
	refus = refus and plateau.piece_de(case) == Engrenage and plateau.rotation_de(case) == 1 and partie.ressorts == 2
	partie.ressorts = 8
	for phase: int in [EtatPartie.Phase.DRAFT, EtatPartie.Phase.FIN]:
		partie.phase = phase
		refus = refus and not partie.reprendre_piece(plateau, case)
	partie.phase = EtatPartie.Phase.CONSTRUCTION
	plateau.retirer(case)
	refus = refus and not partie.reprendre_piece(plateau, case)
	plateau.poser(case, horloge)
	refus = refus and not partie.reprendre_piece(plateau, case) and plateau.retirer(case) == null
	refus = refus and plateau.piece_de(case) == horloge and partie.ressorts == 8 and partie.deplacements_pause == 0
	partie.free()
	return "" if refus else "Une reprise interdite a modifié la partie."


## Un atelier remonté garde son remontage après déplacement, jusqu’à la pause suivante.
func test_remontage_apres_deplacement() -> String:
	var plateau := Plateau.new()
	var production := Production.new()
	var sim := Production.SwarmSim.new()
	var depart := Vector2i.ZERO
	var arrivee := Vector2i.RIGHT
	plateau.ajouter_sol(depart, Plateau.Sol.HERBE)
	plateau.ajouter_sol(arrivee, Plateau.Sol.HERBE)
	plateau.poser(depart, Atelier)
	# Un seul jouet par remontage laisse de la place pour détecter une double production.
	var secondes: float = 1.5 / Atelier.cadence_production
	production.remonter(secondes, plateau, {depart: true}, sim, ReglesJeu)
	if sim.nombre(Production.SwarmSim.ALLIE) != 1:
		return "Le premier remontage doit produire un jouet."
	plateau.retirer(depart)
	production.atelier_repris(depart)
	plateau.poser(arrivee, Atelier)
	production.remonter(secondes, plateau, {arrivee: true}, sim, ReglesJeu)
	production.remonter(secondes, plateau, {arrivee: true}, sim, ReglesJeu)
	if sim.nombre(Production.SwarmSim.ALLIE) != 1:
		return "Déplacer un atelier remonté a produit un jouet supplémentaire."
	production.atelier_repris(arrivee)
	production.nouvelle_pause()
	production.remonter(secondes, plateau, {arrivee: true}, sim, ReglesJeu)
	return "" if sim.nombre(Production.SwarmSim.ALLIE) == 2 else "La nouvelle pause doit autoriser le remontage."
