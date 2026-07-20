extends Area2D
## Radio del comando: escuchar noticias es una timba para la moral.
## A veces llega una voz de casa (cordura sube), a veces propaganda que
## nadie cree (cordura baja), a veces solo estática.

var _inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

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
	var r := randf()
	if r < 0.4:
		GameState.sanity = mini(GameState.SANITY_MAX, GameState.sanity + 8)
		Dialogue.say("Entre la estática, un tango. Alguien manda saludos\na los soldados del sur. (+8 cordura)")
	elif r < 0.8:
		GameState.sanity = maxi(0, GameState.sanity - 8)
		Dialogue.say("«Estamos ganando», repite la voz oficial.\nAfuera silban las bombas. Nadie le cree. (-8 cordura)")
	else:
		Dialogue.say("Solo estática. Girás el dial un rato largo.\nNada.")
