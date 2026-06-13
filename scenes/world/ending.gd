extends Area2D
## La radio = final de la demo. Te da una ELECCIÓN y el desenlace depende de
## tu decisión y de lo que hiciste (flags). Después vuelve al título.

var _inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if b.is_in_group("player"):
		_inside = true

func _on_exit(b: Node) -> void:
	if b.is_in_group("player"):
		_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if _inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_run_ending()

func _run_ending() -> void:
	Dialogue.ask("La radio cruje entre el viento. ¿Qué informás?",
		["La verdad: estamos rodeados", "Mentís: posición asegurada"])
	var choice: int = await Dialogue.chosen

	var text := ""
	if choice == 0:
		text = "Decís la verdad. Te ordenan resistir hasta el último hombre.\n"
		GameState.add_journal("Informaste la verdad por radio. Te mandaron a resistir.")
	else:
		text = "Mentís: «Todo en orden.» Nadie va a venir a buscarte.\n"
		GameState.add_journal("Mentiste por radio. Nadie vendrá.")

	if GameState.has_flag("dead_campo_espectro"):
		text += "Lo que te perseguía quedó tendido en el barro. Por ahora.\n"
	else:
		text += "Algo sigue acechando en la niebla, esperando.\n"

	text += "\n[ Fin de la demo del Sector Infantería — gracias por jugar ]"
	Dialogue.say(text)
	await Dialogue.finished
	get_tree().change_scene_to_file("res://scenes/ui/title.tscn")
