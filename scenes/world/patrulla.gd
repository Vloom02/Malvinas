extends "res://scenes/world/enemy_encounter.gd"
## Patrulla enemiga: camina entre waypoints y te VE con cono frontal + línea
## de vista. Perfil bajo (agachado/cuerpo a tierra) reduce mucho su alcance de
## detección. Al verte grita y persigue; si te toca, combate (heredado).

## Puntos de la ronda, como offsets desde la posición inicial.
@export var waypoints: Array[Vector2] = [Vector2.ZERO, Vector2(160, 0)]
@export var patrol_speed: float = 28.0
@export var vision_range: float = 170.0

var _origin: Vector2
var _wp: int = 0
var _dir: Vector2 = Vector2.RIGHT
var _alerted: bool = false
## Investigación de ruidos (Amnesia: The Bunker): posición y tiempo restante.
var _ruido_pos := Vector2.ZERO
var _investiga_t := 0.0

func _ready() -> void:
	super()
	_origin = global_position
	GameState.ruido_mundo.connect(_on_ruido)

## Escuchó un disparo/ruido metálico. Muy cerca: alerta directa. En rango:
## deja la ronda y va a investigar la posición unos segundos.
func _on_ruido(pos: Vector2, radio: float) -> void:
	if _triggered or _alerted or not _visible_to_sanity:
		return
	var d := global_position.distance_to(pos)
	if d > radio:
		return
	if d < radio * 0.4:
		_alerted = true
		$Label.text = "¡!"
		AudioManager.play_sfx("res://assets/audio/hit.wav", -16.0)
		return
	_ruido_pos = pos
	_investiga_t = 6.0
	$Label.text = "¿?"

## Reemplaza el "flotar hacia el jugador" del EnemyEncounter por ronda + visión.
func _physics_process(delta: float) -> void:
	if _triggered or not _visible_to_sanity:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var to_p: Vector2 = player.global_position - global_position
	if not _alerted:
		_mirar(to_p, player)
		if _investiga_t > 0.0:
			_investigar(delta)
		else:
			_patrullar(delta)
		return
	# Alertada: persigue derecho (frena contra paredes con el raycast).
	var dir := to_p.normalized()
	$RayCast2D.target_position = dir * 24.0
	$RayCast2D.force_raycast_update()
	if not $RayCast2D.is_colliding():
		global_position += dir * chase_speed * delta

func _mirar(to_p: Vector2, player: Node) -> void:
	var see := vision_range
	if player.has_method("is_low_profile") and player.is_low_profile():
		see *= 0.5
	if to_p.length() > see or to_p.normalized().dot(_dir) < 0.4:
		return
	$RayCast2D.target_position = to_p
	$RayCast2D.force_raycast_update()
	if $RayCast2D.is_colliding():
		return
	_alerted = true
	$Label.text = "¡!"
	AudioManager.play_sfx("res://assets/audio/hit.wav", -16.0)

## Camina hacia el ruido (más rápido que la ronda). Si llega o se le pasa el
## interés sin encontrar nada, vuelve a patrullar.
func _investigar(delta: float) -> void:
	_investiga_t -= delta
	var to_r := _ruido_pos - global_position
	if _investiga_t <= 0.0 or to_r.length() < 8.0:
		_investiga_t = 0.0
		$Label.text = label_text
		return
	_dir = to_r.normalized()
	global_position += _dir * patrol_speed * 1.4 * delta
	if absf(_dir.x) > 0.1:
		$Sprite2D.flip_h = _dir.x < 0

func _patrullar(delta: float) -> void:
	if waypoints.is_empty():
		return
	var target := _origin + waypoints[_wp]
	var to_t := target - global_position
	if to_t.length() < 4.0:
		_wp = (_wp + 1) % waypoints.size()
		return
	_dir = to_t.normalized()
	global_position += _dir * patrol_speed * delta
	if absf(_dir.x) > 0.1:
		$Sprite2D.flip_h = _dir.x < 0
