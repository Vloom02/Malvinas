extends Area2D
## Evento aleatorio de mapa (World of Horror): al pisar la zona salta una
## viñeta corta al azar — hallazgo, decisión, consecuencia — y no se repite.
## Poné varias de estas áreas por mapa y cada partida cuenta otra historia.

## Id único (flag evento_<id>) para que no se repita entre partidas guardadas.
## Vacío = una vez por visita al mapa.
@export var event_id: String = ""

var _done := false

func _ready() -> void:
	body_entered.connect(_on_enter)
	if event_id != "" and GameState.has_flag("evento_" + event_id):
		queue_free()

func _on_enter(body: Node) -> void:
	if _done or not body.is_in_group("player"):
		return
	_done = true
	if event_id != "":
		GameState.set_flag("evento_" + event_id)
	# El "..." ya cumplió su función de anzuelo.
	if has_node("Label"):
		$Label.queue_free()
	_evento()

func _evento() -> void:
	match randi() % 5:
		0: _mochila()
		1: _cadaver()
		2: _artilleria()
		3: _panfleto()
		4: _municion()

func _dar(path: String, qty: int = 1) -> String:
	var item := load(path) as ItemData
	if item == null:
		return ""
	if GameState.add_item(item, qty):
		return "Obtenés: %s x%d." % [item.display_name, qty]
	return "No te entra en el inventario."

func _mas_cordura(n: int) -> void:
	GameState.sanity = mini(GameState.SANITY_MAX, GameState.sanity + n)
	GameState.sanity_changed.emit(GameState.sanity)

func _mochila() -> void:
	Dialogue.ask("Una mochila argentina abandonada, medio enterrada en la turba.\nNadie volvió a buscarla.", ["Revisarla", "Seguir de largo"])
	var i: int = await Dialogue.chosen
	if i != 0:
		return
	var botin: Array[String] = [
		"res://data/items/venda.tres",
		"res://data/items/racion.tres",
		"res://data/items/fosforos.tres",
	]
	Dialogue.say("Adentro, entre ropa congelada:\n" + _dar(botin[randi() % botin.size()]))

func _cadaver() -> void:
	Dialogue.ask("Un camarada caído. La escarcha ya lo cubrió.\nTiene los bolsillos abultados.", ["Revisar los bolsillos", "Rezar por él", "Seguir de largo"])
	match await Dialogue.chosen:
		0:
			var r := GameState.sanity_save(12, 8)
			var botin: Array[String] = [
				"res://data/items/morfina.tres",
				"res://data/items/venda_esterilizada.tres",
				"res://data/items/balas_9mm.tres",
			]
			var txt := _dar(botin[randi() % botin.size()])
			if r["success"]:
				Dialogue.say("Le pedís perdón en voz baja.\n" + txt)
			else:
				Dialogue.say("Sus ojos abiertos te siguen mientras lo revisás.\n(-8 de cordura.)\n" + txt)
		1:
			_mas_cordura(5)
			Dialogue.say("Rezás lo poco que te acordás. Algo adentro tuyo se acomoda.\n(+5 de cordura.)")
		_:
			pass

func _artilleria() -> void:
	GameState.drain_sanity(4)
	Dialogue.say("Un trueno de artillería retumba a lo lejos.\nContás los segundos, como con los rayos. Cada vez menos.\n(-4 de cordura.)")

func _panfleto() -> void:
	Dialogue.ask("Un panfleto británico clavado en el alambre:\n\"SOLDADO ARGENTINO: tu posición está rodeada...\"", ["Leerlo entero", "Hacerlo bollo"])
	if await Dialogue.chosen == 0:
		GameState.drain_sanity(6)
		GameState.add_journal("Leí el panfleto enemigo. Sabían el nombre de mi regimiento.")
		Dialogue.say("Sabían el nombre de tu regimiento. Sabían cuánta comida les queda.\n(-6 de cordura.)")
	else:
		Dialogue.say("Lo hacés un bollo y lo pisás en el barro. Mejor no saber.")

func _municion() -> void:
	Dialogue.ask("Una caja de munición volcada en el barro helado.", ["Buscar entre el barro", "Seguir de largo"])
	if await Dialogue.chosen != 0:
		return
	if randf() < 0.5:
		Dialogue.say("Los dedos se te entumecen, pero hay cargas útiles.\n" + _dar("res://data/items/balas_762.tres", 4))
	else:
		GameState.cold = clampi(GameState.cold + 6, 0, 100)
		GameState.body_changed.emit()
		Dialogue.say("Nada servible. El barro helado te comió las manos al pedo.\n(+frío.)")
