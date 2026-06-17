extends Area2D
class_name NpcRecruit
## NPC reclutable en el mundo. Cuando el jugador interactúa, puede reclutarlo
## como companion (si cumple las condiciones).
##
## Reutilizable: poné varios en el mapa, cada uno con su CompanionData .tres.

## Datos del compañero (un CompanionData .tres).
@export var companion_path: String = ""
## Texto del cartel flotante.
@export var label_text: String = ""
## Sprite del NPC.
@export var sprite_texture: Texture2D
## Flag que se necesita para reclutar (vacío = siempre disponible).
@export var require_flag: String = ""
## Si se setea, usa Dialogue.play_data() con este DataDialogue en vez de Dialogue.ask().
@export var dialogue_path: String = ""

var _player_inside: bool = false
var _recruited: bool = false

func _ready() -> void:
	if companion_path == "":
		return
	# Si ya está reclutado, desaparecer.
	if GameState.has_flag(_get_recruited_flag()):
		queue_free()
		return
	if sprite_texture != null:
		$Sprite2D.texture = sprite_texture
	if label_text != "":
		$Label.text = label_text
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _get_recruited_flag() -> String:
	var data := load(companion_path) as CompanionData
	if data != null and data.recruited_flag != "":
		return data.recruited_flag
	return "recruited_" + companion_path.get_file().get_basename()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or not event.is_action_pressed("interact"):
		return
	if companion_path == "":
		return
	get_viewport().set_input_as_handled()

	var data := load(companion_path) as CompanionData
	if data == null:
		return

	# Chequear flag requerido.
	if require_flag != "" and not GameState.has_flag(require_flag):
		Dialogue.say("El %s no parece querer ir con vos todavía." % data.display_name)
		return

	# Si tiene dialogue_path, usar Dialogue.play_data() y reclutar después.
	if dialogue_path != "":
		var dialogue_res = load(dialogue_path) as DataDialogue
		if dialogue_res != null:
			Dialogue.play_data(dialogue_res)
			await Dialogue.finished
			# Reclutar si se ganó la confianza (recruit_flag está seteado).
			if data.recruit_flag != "" and GameState.has_flag(data.recruit_flag):
				_try_recruit(data)
			return

	# Reclutar directo (sin diálogo ramificado).
	Dialogue.ask(
		"%s\n\n%s" % [data.description, data.recruit_text],
		["Reclutar", "Dejarlo"]
	)
	var choice: int = await Dialogue.chosen
	if choice == 0:
		_try_recruit(data)

func _try_recruit(data: CompanionData) -> void:
	if GameState.add_companion(data):
		_recruited = true
		GameState.set_flag(_get_recruited_flag())
		AudioManager.play_sfx("res://assets/audio/bandage.wav", -2.0)
		queue_free()
	else:
		Dialogue.say("Ya tenés un compañero. No podés llevar más de uno.")
