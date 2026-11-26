class_name Reserve extends RefCounted
## Conserve les quantités disponibles et la définition de chaque objet en stock.

const Lot = preload("res://game/core/lot.gd")

signal modifiee

var _objets: Dictionary[StringName, Resource] = {}
var _quantites: Dictionary[StringName, int] = {}


## Ajoute des exemplaires d'un objet identifié par son identifiant métier.
func ajouter(objet: Resource, n: int = 1) -> void:
	if objet == null or n <= 0:
		return
	var id: StringName = objet.get("id")
	_objets[id] = objet
	_quantites[id] = quantite(id) + n
	modifiee.emit()


## Verse chaque lot dans la réserve.
func ajouter_lots(lots: Array[Lot]) -> void:
	for lot: Lot in lots:
		ajouter(lot.objet, lot.quantite)


## Consomme un exemplaire disponible et oublie l'objet quand le stock est épuisé.
func retirer(id: StringName) -> bool:
	var stock: int = quantite(id)
	if stock == 0:
		return false
	if stock == 1:
		_quantites.erase(id)
		_objets.erase(id)
	else:
		_quantites[id] = stock - 1
	modifiee.emit()
	return true


## Indique combien d'exemplaires de cet objet peuvent encore être utilisés.
func quantite(id: StringName) -> int:
	return _quantites.get(id, 0)


## Retrouve la définition d'un objet disponible dans la réserve.
func trouver(id: StringName) -> Resource:
	return _objets.get(id)


## Liste les identifiants en stock dans un ordre stable pour l'affichage.
func ids() -> Array[StringName]:
	var resultat: Array[StringName] = _quantites.keys()
	# Tri par texte : `sort()` sur des StringName compare leurs identifiants internes (ordre instable
	# quand de nouveaux noms apparaissent), pas l'ordre alphabétique.
	resultat.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return resultat


## Vide la réserve au début d'une nouvelle partie.
func vider() -> void:
	if _quantites.is_empty():
		return
	_quantites.clear()
	_objets.clear()
	modifiee.emit()
