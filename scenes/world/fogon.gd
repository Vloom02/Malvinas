extends Node2D
## Fogón/estufa: EL punto de guardado del juego (estilo Fear & Hunger).
## Acercate y apretá E: guardar partida, calentarte (baja el frío) o cocinar
## carne podrida (la vuelve comible). El fuego es vectorial animado por código.

## Si está apagado, primero hay que prenderlo (pide fósforos).
@export var lit: bool = true
## Cuánto frío saca calentarse.
@export var warm_amount: int = 60

var _inside: bool = false
var _t: float = 0.0
@onready var _flame: Polygon2D = $Flama
@onready var _flame2: Polygon2D = $FlamaInterna
@onready var _light: PointLight2D = $Luz

func _ready() -> void:
	$Area2D.body_entered.connect(_on_enter)
	$Area2D.body_exited.connect(_on_exit)
	$InteractHint.visible = false
	_update_fire()

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = true
		$InteractHint.visible = true

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = false
		$InteractHint.visible = false

## Llama viva: oscila escala y luz con seno + ruido barato. Solo si está prendido.
func _process(delta: float) -> void:
	if not lit:
		return
	_t += delta
	var s := 1.0 + sin(_t * 9.0) * 0.08 + sin(_t * 23.0) * 0.05
	_flame.scale = Vector2(s, 2.0 - s)
	_flame2.scale = Vector2(2.0 - s, s)
	_light.energy = 0.8 + sin(_t * 7.0) * 0.15

func _update_fire() -> void:
	_flame.visible = lit
	_flame2.visible = lit
	_light.visible = lit
	set_process(lit)

func _unhandled_input(event: InputEvent) -> void:
	if not _inside or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	_menu()

func _menu() -> void:
	if not lit:
		_encender()
		return
	Dialogue.ask("El fuego cruje. Un momento de paz.",
		["Guardar partida", "Calentarte", "Cocinar carne", "Dormir hasta el amanecer", "Nada"])
	var choice: int = await Dialogue.chosen
	match choice:
		0:
			GameState.allow_save()
			GameState.save_game()
			Dialogue.say("Anotás dónde estás y lo que pasó.\n(Partida guardada.)")
		1:
			if GameState.cold <= 0 and GameState.trench_foot <= 0:
				Dialogue.say("Ya estás entrado en calor.")
				return
			GameState.cold = maxi(0, GameState.cold - warm_amount)
			GameState.trench_foot = maxi(0, GameState.trench_foot - 30)
			GameState.body_changed.emit()
			Dialogue.say("Te sacás las botas frente al fuego. El frío afloja\ny los pies respiran un poco.")
		2:
			_cocinar()
		3:
			_dormir()

## Asa carne cruda (primero) o podrida: las dos se vuelven ración comible.
func _cocinar() -> void:
	for id in ["carne_cruda", "carne_podrida"]:
		var carne: ItemData = GameState.items_by_id.get(id)
		if carne != null and int(GameState.inventory.get(carne, 0)) > 0:
			GameState.inventory[carne] -= 1
			if GameState.inventory[carne] <= 0:
				GameState.inventory.erase(carne)
			GameState.add_item(GameState.items_by_id["racion"], 1)
			Dialogue.say("Asás la carne hasta que gotea.\nObtenés: Ración.")
			return
	Dialogue.say("No tenés carne para asar.")

## Dormir pasa la noche de un tirón: amanece, el cuerpo descansa...
## pero a veces las pesadillas cobran peaje.
func _dormir() -> void:
	if not GameState.is_night() and GameState.time_hours < 18.0:
		Dialogue.say("Todavía hay luz. Dormir ahora sería desperdiciarla.")
		return
	# Hasta las 6: si es de tarde/noche cruza la medianoche (avanza el día).
	if GameState.time_hours >= 6.0:
		GameState.advance_hours(30.0 - GameState.time_hours)
	else:
		GameState.advance_hours(6.0 - GameState.time_hours)
	GameState.cold = maxi(0, GameState.cold - 40)
	GameState.trench_foot = maxi(0, GameState.trench_foot - 20)
	GameState.body_changed.emit()
	if Dice.chance(0.25):
		GameState.sanity = maxi(0, GameState.sanity - 10)
		Dialogue.say("Dormís, pero el sueño te lleva de vuelta al bombardeo.\nAmanecés temblando. (-10 cordura)")
	else:
		Dialogue.say("Dormís apretado contra el fuego.\nAmanece sobre la turba.")

func _encender() -> void:
	var fosforos: ItemData = GameState.items_by_id.get("fosforos")
	if fosforos == null or int(GameState.inventory.get(fosforos, 0)) <= 0:
		Dialogue.say("El fogón está apagado y no tenés fósforos.")
		return
	# Consumo directo (use_item de fósforos tiene su propio efecto "warm").
	var have := int(GameState.inventory.get(fosforos, 0))
	if have > 0:
		GameState.inventory[fosforos] = have - 1
		if GameState.inventory[fosforos] <= 0:
			GameState.inventory.erase(fosforos)
	GameState.inventory_changed.emit()
	lit = true
	_update_fire()
	Dialogue.say("Prendés el fogón. La luz espanta un poco la noche.")
