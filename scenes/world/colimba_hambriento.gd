extends Area2D
## Colimba hambriento (This War of Mine): te pide una ración. Dársela cuesta
## comida pero paga en cordura y reputación; negarte es gratis... para el bolsillo.

var _inside: bool = false
var _fed: bool = false

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
	if _fed:
		Dialogue.say("—Gracias, hermano. No me olvido.")
		return
	_pedir()

func _pedir() -> void:
	Dialogue.ask("—¿No te sobra algo? —dice el colimba, con la vista ida.\nTiene la cara chupada de hambre.", ["Darle una ración", "Negarte"])
	var choice: int = await Dialogue.chosen
	var racion: ItemData = GameState.items_by_id["racion"]
	if choice == 0:
		if int(GameState.inventory.get(racion, 0)) <= 0:
			Dialogue.say("Te palpás los bolsillos: no tenés nada para darle.\nBaja la vista.")
			return
		GameState.inventory[racion] -= 1
		if GameState.inventory[racion] <= 0:
			GameState.inventory.erase(racion)
		GameState.inventory_changed.emit()
		GameState.sanity = mini(GameState.SANITY_MAX, GameState.sanity + 10)
		GameState.reputation = mini(100, GameState.reputation + 5)
		GameState.make_decision("compartiste_racion")
		GameState.add_journal("Compartiste tu ración con un colimba que se moría de hambre.")
		_fed = true
		Dialogue.say("Come con las dos manos, casi sin masticar.\nTe mira distinto. Vos también te sentís distinto.\n(+10 cordura, +reputación)")
	else:
		GameState.sanity = maxi(0, GameState.sanity - 8)
		GameState.make_decision("negaste_racion")
		Dialogue.say("—Está bien... —dice, y no dice más nada.\nSu cara te sigue hasta la noche. (-8 cordura)")
