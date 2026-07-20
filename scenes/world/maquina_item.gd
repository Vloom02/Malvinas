extends Area2D
## Máquina que pide un ítem para funcionar: generador (pide gasoil), radio
## (pide el flag del generador), reja con candado (pide llave)... Consumir el
## ítem setea un flag que otras cosas (puertas, radios) pueden chequear.

## Nombre para los mensajes.
@export var display_name: String = "Generador"
## Ítem que necesita (id de items_by_id). Vacío = no pide ítem.
@export var requires_item_id: String = "bidon_gasoil"
## Flag que debe estar seteado ANTES (cadena: la radio pide generador_on). Vacío = ninguno.
@export var requires_flag: String = ""
@export_multiline var msg_requires_flag: String = "Sin energía no responde."
## Flag que setea al activarse.
@export var done_flag: String = "generador_on"
@export_multiline var msg_missing: String = "El tanque está seco. Necesita combustible."
@export_multiline var msg_done: String = "El motor tose, escupe humo y arranca. ¡Hay energía!"
@export_multiline var msg_already: String = "Ya está andando."
## Sonido al activarse (vacío = ninguno).
@export var sfx_on: String = "res://assets/audio/explosion.wav"

var _inside: bool = false
@onready var _luz: Polygon2D = $Luz

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	$Nombre.text = display_name
	_refresh_luz()

func _activada() -> bool:
	return done_flag != "" and GameState.has_flag(done_flag)

func _refresh_luz() -> void:
	_luz.color = Color(0.35, 0.9, 0.35, 1) if _activada() else Color(0.5, 0.2, 0.15, 1)

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = true

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if not _inside or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if _activada():
		Dialogue.say(msg_already)
		return
	if requires_flag != "" and not GameState.has_flag(requires_flag):
		Dialogue.say(msg_requires_flag)
		return
	if requires_item_id != "":
		var item: ItemData = GameState.items_by_id.get(requires_item_id)
		if item == null or int(GameState.inventory.get(item, 0)) <= 0:
			Dialogue.say(msg_missing)
			return
		GameState.inventory[item] -= 1
		if GameState.inventory[item] <= 0:
			GameState.inventory.erase(item)
		GameState.inventory_changed.emit()
	GameState.set_flag(done_flag)
	_refresh_luz()
	if sfx_on != "":
		AudioManager.play_sfx(sfx_on, -18.0)
	Dialogue.say(msg_done)
