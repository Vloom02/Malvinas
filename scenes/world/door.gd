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
## Permite forzar la puerta con un dado (tirada de Fuerza). 0 = no forzable.
@export var force_dc: int = 0
## Mensaje si la forzás exitosamente.
@export var force_success_msg: String = "Forzás la puerta. Los goznes chillan pero cede."

var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used:
		return
	if not body.is_in_group("player") or target_scene == "":
		return
	if _is_blocked():
		_try_open()
		return
	_used = true
	Transition.change(target_scene, target_spawn)

func _is_blocked() -> bool:
	if not locked:
		return false
	if unlock_flag != "" and GameState.has_flag(unlock_flag):
		return false
	return true

func _try_open() -> void:
	if force_dc > 0 and GameState.broken_arms() < 2:
		Dialogue.ask(locked_message, ["Forzar la puerta (d20)", "Dejarla"])
		var choice: int = await Dialogue.chosen
		if choice == 0:
			var mod := 2 - GameState.broken_arms() * 2
			var r := Dice.check(mod, force_dc)
			var text := "Forcejeás con la puerta...\n[d20 %d+%d=%d vs %d]" % [r["die"], mod, r["total"], force_dc]
			if r["success"]:
				GameState.body_changed.emit()
				_used = true
				Transition.change(target_scene, target_spawn)
				return
			else:
				text += "\nNo cedió. Te lastimaste las manos."
				if Dice.chance(0.3):
					GameState.apply_bleeding(1)
				Dialogue.say(text)
			return
	else:
		Dialogue.say(locked_message)
