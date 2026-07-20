extends Node2D
## Oveja: pasta y deambula; si te acercás huye... pero con E la podés CARNEAR
## (da carne cruda). Ojo: como en Malvinas de verdad, si te ven carneando
## ganado te ESTAQUEAN — horas atado al frío por orden del cabo.

@export var wander_radius: float = 90.0
@export var flee_range: float = 70.0
## Probabilidad de que te vean carneando (→ estaqueo).
@export var caught_chance: float = 0.35

var _origin: Vector2
var _target: Vector2
var _pausa: float = 0.0

func _ready() -> void:
	_origin = global_position
	_target = _origin
	_pausa = randf_range(0.5, 2.5)

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var to_me: Vector2 = global_position - (player as Node2D).global_position
		if to_me.length() < flee_range:
			global_position += to_me.normalized() * 70.0 * delta
			$Cuerpo.scale.x = -1.0 if to_me.x < 0 else 1.0
			return
	if _pausa > 0.0:
		_pausa -= delta
		return
	var to_t := _target - global_position
	if to_t.length() < 3.0:
		_target = _origin + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * wander_radius
		_pausa = randf_range(1.0, 4.0)
		return
	global_position += to_t.normalized() * 22.0 * delta
	$Cuerpo.scale.x = -1.0 if to_t.x < 0 else 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or global_position.distance_to((player as Node2D).global_position) > 34.0:
		return
	get_viewport().set_input_as_handled()
	_carnear()

func _carnear() -> void:
	Dialogue.ask("La oveja te mira. Tenés hambre.", ["Carnearla", "Dejarla"])
	var choice: int = await Dialogue.chosen
	if choice != 0:
		return
	GameState.add_item(GameState.items_by_id["carne_cruda"], 2)
	GameState.make_decision("carneo_oveja")
	if Dice.chance(caught_chance):
		# Te vieron: estaqueo (documentado en los testimonios reales de Malvinas).
		GameState.estaquear()
		GameState.add_journal("Te estaquearon por carnear una oveja. Horas atado al frío.")
		Dialogue.say("Una patrulla propia te ve con el cuchillo en la mano.\n\nEl cabo no pregunta: te ESTAQUEAN sobre la turba helada.\nPasás horas atado mirando el cielo.\n(+frío, -15 cordura, -reputación, pasan 6 horas)")
	else:
		Dialogue.say("Trabajás rápido, mirando por encima del hombro.\nObtenés: Carne de oveja cruda x2.")
	queue_free()
