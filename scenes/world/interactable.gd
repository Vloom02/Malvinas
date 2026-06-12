extends Area2D
class_name Interactable
## Un objeto del mundo con el que el jugador puede interactuar apretando E.
##
## Cómo funciona: es un Area2D (una zona que detecta cuando algo entra).
## Cuando el jugador entra en la zona, se "arma"; si está adentro y apretás
## la acción "interact", dispara su mensaje y la señal interacted.
##
## Reutilizable: cofres, carteles, puertas, NPCs... todos pueden ser un
## Interactable con un mensaje distinto, sin duplicar código.

## Texto que muestra al interactuar. Editable desde el Inspector por escena.
@export var message: String = "No hay nada interesante aquí."

## Cordura que cuesta interactuar (0 = inofensivo; >0 = objeto maldito).
@export var sanity_cost: int = 0

## Item que entrega al interactuar (ej: un cofre con vendas). Null = nada.
@export var gives_item: ItemData = null
## Cuántas unidades del item entrega.
@export var give_qty: int = 1

signal interacted

var _player_inside: bool = false
var _item_taken: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		print("[Mundo] Cerca de un objeto — apretá E para interactuar.")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		print("[Interacción] %s" % message)
		if sanity_cost > 0:
			GameState.drain_sanity(sanity_cost)
			print("[Mundo] Algo se rompe en tu mente... (-%d cordura)" % sanity_cost)
		if gives_item != null and not _item_taken:
			GameState.add_item(gives_item, give_qty)
			_item_taken = true
		interacted.emit()
