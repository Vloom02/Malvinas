extends Area2D
## Depósito de intendencia custodiado: la comida está ahí nomás... y robarla
## es jugarse el estaqueo. De NOCHE hay menos ojos (mucho menos riesgo).
## Una vez por día: después del intento, el guardia queda avivado.

## Probabilidad de que te vean robando de día / de noche.
@export var caught_day: float = 0.5
@export var caught_night: float = 0.1

var _inside: bool = false
var _last_day: int = -1

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
	if _last_day == GameState.day:
		Dialogue.say("El guardia te clava la mirada. Hoy ya arriesgaste demasiado.")
		return
	_robar()

func _robar() -> void:
	var pista := "\n(Es de noche: casi no hay ojos.)" if GameState.is_night() else "\n(A plena luz te ve medio batallón.)"
	Dialogue.ask("Las cajas de raciones están ahí nomás, apiladas." + pista, ["Robar comida", "Irte"])
	var choice: int = await Dialogue.chosen
	if choice != 0:
		return
	_last_day = GameState.day
	GameState.add_item(GameState.items_by_id["racion"], 2)
	GameState.make_decision("robo_deposito")
	if Dice.chance(caught_night if GameState.is_night() else caught_day):
		GameState.estaquear()
		GameState.add_journal("Te estaquearon por robar comida del depósito.")
		Dialogue.say("—¡ALTO AHÍ!\n\nTe agarran con las latas encima. El cabo sonríe.\nTe ESTAQUEAN sobre la turba helada.\n(+frío, -15 cordura, -reputación, pasan 6 horas)")
	else:
		GameState.sanity = maxi(0, GameState.sanity - 3)
		Dialogue.say("Metés dos raciones bajo la campera y salís silbando.\nNadie te vio. Igual, algo adentro tuyo lo sabe. (-3 cordura)")
