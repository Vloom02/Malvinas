extends Area2D
## Desafío físico con tirada de dado: tablón flojo, bote volcado, grieta,
## mochila hundida... Apretás E, elegís intentarlo, y un d20 + Fuerza decide.
## Éxito: ítem y/o flag. Fallo: golpe/sangrado. El éxito se recuerda por flag.
## ponytail: una sola stat (Fuerza); si un plano pide Percepción, se agrega export.

## Pregunta al acercarse (describe el desafío).
@export_multiline var prompt: String = "El bote volcado parece esconder algo."
## Texto del botón de intentar.
@export var attempt_label: String = "Levantarlo (d20 Fuerza)"
## Dificultad de la tirada.
@export var dc: int = 12
@export_multiline var success_msg: String = "Con un envión lo das vuelta."
@export_multiline var fail_msg: String = "No cede. Te agarrás la espalda."
## Ítem que da al lograrlo (id de items_by_id, vacío = nada).
@export var gives_item_id: String = ""
@export var give_qty: int = 1
## Flag que setea al lograrlo (para abrir puertas/atajos).
@export var set_flag: String = ""
## Daño al fallar (0 = solo mensaje).
@export var fail_damage: int = 4
## Id único: recordar que ya se logró (flag hecho_<id>).
@export var challenge_id: String = ""

var _inside: bool = false
var _done: bool = false

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	if challenge_id != "" and GameState.has_flag("hecho_" + challenge_id):
		_done = true

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
	if _done:
		Dialogue.say("Acá ya no queda nada por hacer.")
		return
	_intentar()

func _intentar() -> void:
	Dialogue.ask(prompt, [attempt_label, "Dejarlo"])
	var choice: int = await Dialogue.chosen
	if choice != 0:
		return
	var mod := GameState.get_force_mod()
	var r := Dice.check(mod, dc)
	var tirada := "[d20 %d+%d=%d vs %d]" % [r["die"], mod, r["total"], dc]
	if r["success"]:
		_done = true
		if challenge_id != "":
			GameState.set_flag("hecho_" + challenge_id)
		if set_flag != "":
			GameState.set_flag(set_flag)
		var text := success_msg + "\n" + tirada
		if gives_item_id != "":
			var item: ItemData = GameState.items_by_id.get(gives_item_id)
			if item != null and GameState.add_item(item, give_qty):
				text += "\nObtenés: %s x%d." % [item.display_name, give_qty]
		Dialogue.say(text)
	else:
		var text := fail_msg + "\n" + tirada
		if fail_damage > 0:
			GameState.damage_player(fail_damage)
			text += "\n(-%d de vida.)" % fail_damage
		if r["fumble"]:
			GameState.apply_bleeding(1)
			text += "\nPifia: te abrís la mano."
		Dialogue.say(text)
