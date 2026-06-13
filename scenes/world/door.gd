extends Area2D
class_name Door
## Puerta entre salas. Al pisarla, te lleva a `target_scene` y te deja en el
## punto de aparición `target_spawn` (un Marker2D de esa sala).

## Ruta de la escena destino (ej: "res://scenes/maps/room2.tscn").
@export_file("*.tscn") var target_scene: String = ""
## Nombre del Marker2D donde aparecés en la sala destino.
@export var target_spawn: String = ""
## Si está trabada, necesitás tener seteado `unlock_flag` para pasar.
@export var locked: bool = false
## Flag que la destraba (lo setea una palanca o una llave).
@export var unlock_flag: String = ""
## Mensaje si está trabada.
@export var locked_message: String = "Está trabada. Hay que abrirla de algún lado."

var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used:
		return
	if not body.is_in_group("player") or target_scene == "":
		return
	if locked and unlock_flag != "" and not GameState.has_flag(unlock_flag):
		Dialogue.say(locked_message)
		return
	_used = true
	Transition.change(target_scene, target_spawn)
