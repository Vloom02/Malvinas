extends Node2D
## Evento de bombardeo: al pisar el Trigger suena la alarma y tenés unos
## segundos para meterte en la zona Refugio. Si te agarra afuera: daño +
## shock de batalla. Una vez por partida si tiene event_id.

## Segundos entre la alarma y el impacto.
@export var warn_seconds: float = 8.0
## Daño si te agarra fuera del refugio.
@export var damage: int = 30
## Id único (flag bombardeo_<id>) para que ocurra una sola vez. Vacío = siempre.
@export var event_id: String = ""

var _running: bool = false

func _ready() -> void:
	$Trigger.body_entered.connect(_on_trigger)
	if event_id != "" and GameState.has_flag("bombardeo_" + event_id):
		queue_free()

func _on_trigger(body: Node) -> void:
	if _running or not body.is_in_group("player"):
		return
	_running = true
	if event_id != "":
		GameState.set_flag("bombardeo_" + event_id)
	_evento()

func _evento() -> void:
	Dialogue.say("¡SIRENA ANTIAÉREA!\n¡Bombardeo inminente: corré al REFUGIO!")
	# Pitidos crecientes mientras corre el reloj.
	var t := warn_seconds
	while t > 0.0:
		AudioManager.play_sfx("res://assets/audio/disparo.wav", -20.0 + (warn_seconds - t))
		# create_timer con process_always=false: la cuenta regresiva RESPETA la
		# pausa (antes seguía corriendo con el menú o un diálogo abiertos).
		await get_tree().create_timer(minf(1.0, t), false).timeout
		t -= 1.0
	_impacto()

func _impacto() -> void:
	AudioManager.play_sfx("res://assets/audio/explosion.wav", -2.0)
	_sacudida(14.0)
	for i in 3:
		await get_tree().create_timer(randf_range(0.3, 0.7), false).timeout
		AudioManager.play_sfx("res://assets/audio/explosion.wav", randf_range(-10.0, -4.0))
		_sacudida(8.0)
	var player := get_tree().get_first_node_in_group("player")
	var safe := false
	for b in $Refugio.get_overlapping_bodies():
		if b == player:
			safe = true
			break
	if safe:
		Dialogue.say("Las bombas caen afuera. El refugio tiembla, pero aguanta.")
	else:
		GameState.damage_player(damage)
		GameState.shell_shock = maxi(GameState.shell_shock, 3)
		GameState.body_changed.emit()
		Dialogue.say("La onda expansiva te revuelca. Los oídos te chillan.\n(-%d de vida, shock de batalla.)" % damage)

func _sacudida(fuerza: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := create_tween()
	for i in 4:
		tw.tween_property(cam, "offset",
			Vector2(randf_range(-fuerza, fuerza), randf_range(-fuerza, fuerza)), 0.05)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.1)
