extends Area2D
## Línea de fuego estática (nido de MAG / francotirador): una franja batida
## por fuego enemigo. Si la cruzás PARADO te tiran: primero un aviso que pega
## cerca, después balazos de verdad. Agachado (C) o cuerpo a tierra (Z) pasás.
## El peligro se dibuja como franja punteada roja tenue.

## Daño por impacto.
@export var damage: int = 8
## Segundos entre ráfagas mientras estés expuesto.
@export var fire_interval: float = 0.9
## De dónde salen los tiros (offset local): dibuja el trazador desde ahí.
@export var source_offset: Vector2 = Vector2(0, -180)
## Aviso la primera vez que te ven.
@export var warning: String = "¡Te tiran! ¡Cuerpo a tierra (Z) o agachate (C)!"

var _player: Node2D = null
var _cd: float = 0.0
var _warned: bool = false

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	queue_redraw()

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body
		_cd = 0.25  # margen chico para reaccionar al entrar

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player = null

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	# Perfil bajo = no te enganchan (usa la postura real del player).
	if _player.has_method("is_low_profile") and _player.is_low_profile():
		return
	_cd -= delta
	if _cd > 0.0:
		return
	_cd = fire_interval
	_shoot_at_player()

func _shoot_at_player() -> void:
	_tracer(_player.global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6)))
	AudioManager.play_sfx("res://assets/audio/disparo.wav", -8.0)
	if not _warned:
		# El primer tiro avisa: pega al lado tuyo.
		_warned = true
		Dialogue.say(warning)
		return
	GameState.damage_player(damage)
	if Dice.chance(0.25):
		GameState.apply_bleeding(1)
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var tw := create_tween()
		tw.tween_property(cam, "offset", Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.05)
		tw.tween_property(cam, "offset", Vector2.ZERO, 0.1)

## Trazador: línea amarilla fugaz desde el origen del fuego hasta el impacto.
func _tracer(impact_global: Vector2) -> void:
	var l := Line2D.new()
	l.width = 1.5
	l.default_color = Color(1.0, 0.9, 0.4, 0.9)
	l.add_point(source_offset)
	l.add_point(to_local(impact_global))
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.18)
	tw.tween_callback(l.queue_free)

## Franja de peligro punteada (sutil, para que se lea la zona batida).
func _draw() -> void:
	var shape_node := get_node_or_null("CollisionShape2D")
	if shape_node == null or shape_node.shape == null or not (shape_node.shape is RectangleShape2D):
		return
	var ext: Vector2 = (shape_node.shape as RectangleShape2D).size * 0.5
	var p: Vector2 = shape_node.position
	var col := Color(0.85, 0.25, 0.15, 0.28)
	var x := p.x - ext.x
	while x < p.x + ext.x:
		draw_line(Vector2(x, p.y - ext.y), Vector2(minf(x + 6, p.x + ext.x), p.y - ext.y), col, 1.0)
		draw_line(Vector2(x, p.y + ext.y), Vector2(minf(x + 6, p.x + ext.x), p.y + ext.y), col, 1.0)
		x += 12.0
