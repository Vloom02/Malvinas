extends Node2D
## Celda de prisioneros: acá te despierta room.gd cuando un enemigo que
## captura te derrota (grupo "celda"). Para escapar hay que forzar la reja
## con una tirada de Fuerza. Fallar hace ruido y te lastima las manos.

## Dificultad de forzar la reja.
@export var dc: int = 11

var _inside: bool = false
var _open: bool = false

func _ready() -> void:
	add_to_group("celda")
	$Zona.body_entered.connect(_on_enter)
	$Zona.body_exited.connect(_on_exit)

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = true

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if not _inside or _open or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	_forzar()

func _forzar() -> void:
	Dialogue.ask("La reja está fría y oxidada. Nadie mira.", ["Forzarla (d20 Fuerza)", "Esperar"])
	var choice: int = await Dialogue.chosen
	if choice != 0:
		return
	var mod := GameState.get_force_mod()
	var r := Dice.check(mod, dc)
	if r["success"]:
		_open = true
		$Reja.visible = false
		$Reja/CollisionShape2D.set_deferred("disabled", true)
		AudioManager.play_sfx("res://assets/audio/hit.wav", -12.0)
		Dialogue.say("El barrote cede con un quejido. Estás afuera.\n[d20 %d+%d=%d vs %d]" % [r["die"], mod, r["total"], dc])
	else:
		GameState.damage_player(2)
		Dialogue.say("La reja no cede y te dejás la piel en el intento.\n[d20 %d+%d=%d vs %d] (-2 de vida)" % [r["die"], mod, r["total"], dc])
