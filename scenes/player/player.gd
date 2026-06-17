extends CharacterBody2D
## El jugador (soldado LPC). Arma sus animaciones cortando los spritesheets LPC
## compuestos (mismo método que funcionó con el conscripto, SIN depender del addon).
## Camina en 4 direcciones; el cuerpo refleja el estado (sangre/frío/infección).

@export var speed: float = 110.0

const STEP_DISTANCE: float = 64.0
const SHEETS := "res://assets/sprites/lpc_soldado/standard"
const FRAME := 64
## Fila de cada dirección en los sheets LPC.
const DIR_ROW := {"north": 0, "west": 1, "south": 2, "east": 3}

var _distance_walked: float = 0.0
var _facing: String = "south"
## Dirección (en mundo/pantalla, y hacia abajo) hacia la que mira el jugador.
## La lee darkness.gd para apuntar el haz de la linterna.
var facing_vector: Vector2 = Vector2.DOWN
const FACING_VEC := {
	"south": Vector2(0, 1), "north": Vector2(0, -1),
	"east": Vector2(1, 0), "west": Vector2(-1, 0),
}
## Posición de la mano que sostiene la linterna, por dirección (en local del
## jugador). De ahí nace el haz.
const HAND_OFFSET := {
	"south": Vector2(10, -5), "north": Vector2(-10, -7),
	"east": Vector2(12, -6), "west": Vector2(-12, -6),
}
var _cur_anim: String = ""
var sprite: AnimatedSprite2D
## "Rig" de la linterna: un Node2D que rota para apuntar a donde mirás. Adentro
## tiene la linterna dibujada y el cono de luz, que salen siempre hacia adelante.
var _light_rig: Node2D

func _ready() -> void:
	$Camera2D.zoom = Vector2(GameState.camera_zoom, GameState.camera_zoom)
	sprite = AnimatedSprite2D.new()
	sprite.offset = Vector2(0, -20)
	sprite.sprite_frames = _build_frames()
	add_child(sprite)
	_set_anim("idle", "south")
	_build_flashlight()

## Construye la linterna y su haz como dibujo vectorial (sin depender de un PNG).
## Todo apunta a +x local; el rig se rota según la dirección en _update_flashlight.
func _build_flashlight() -> void:
	_light_rig = Node2D.new()
	_light_rig.position = HAND_OFFSET["south"]
	_light_rig.z_index = 1
	_light_rig.visible = false
	add_child(_light_rig)

	# Cono de luz (haz): triángulo que se desvanece hacia afuera.
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([
		Vector2(12, -2), Vector2(74, -26), Vector2(82, 0), Vector2(74, 26), Vector2(12, 2)])
	beam.vertex_colors = PackedColorArray([
		Color(1.0, 0.95, 0.6, 0.55), Color(1.0, 0.95, 0.6, 0.0),
		Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.95, 0.6, 0.0),
		Color(1.0, 0.95, 0.6, 0.55)])
	_light_rig.add_child(beam)

	# Cuerpo de la linterna (mango gris).
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(8, -3), Vector2(11, -2), Vector2(11, 2), Vector2(8, 3), Vector2(0, 2)])
	body.color = Color(0.16, 0.16, 0.19)
	_light_rig.add_child(body)

	# Lente brillante en la punta.
	var lens := Polygon2D.new()
	lens.polygon = PackedVector2Array([
		Vector2(11, -3), Vector2(13, -2), Vector2(13, 2), Vector2(11, 3)])
	lens.color = Color(1.0, 0.95, 0.7)
	_light_rig.add_child(lens)

## Construye un SpriteFrames con walk_/idle_ por dirección desde los PNG LPC.
func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var walk_tex: Texture2D = load(SHEETS + "/walk.png")
	var idle_tex: Texture2D = load(SHEETS + "/idle.png")
	for dir: String in DIR_ROW.keys():
		var row: int = DIR_ROW[dir]
		# Caminar: cuadros 1..8 (el 0 es la pose parada).
		var wname := "walk_" + dir
		sf.add_animation(wname)
		sf.set_animation_loop(wname, true)
		sf.set_animation_speed(wname, 9.0)
		if walk_tex:
			for i in range(1, 9):
				sf.add_frame(wname, _slice(walk_tex, i, row))
		# Quieto: cuadro 0.
		var iname := "idle_" + dir
		sf.add_animation(iname)
		sf.set_animation_loop(iname, true)
		sf.set_animation_speed(iname, 2.0)
		if idle_tex:
			sf.add_frame(iname, _slice(idle_tex, 0, row))
	return sf

func _slice(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(col * FRAME, row * FRAME, FRAME, FRAME)
	return a

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var spd := speed
	match GameState.broken_legs():
		1: spd *= 0.65
		2: spd *= 0.35
	velocity = direction * spd
	move_and_slide()

	_update_animation(direction)
	_reflect_body()
	_update_atmosphere(delta)

	if direction != Vector2.ZERO:
		_distance_walked += velocity.length() * delta
		while _distance_walked >= STEP_DISTANCE:
			_distance_walked -= STEP_DISTANCE
			GameState.spend_step()
			_spawn_blood_trail()

func _update_animation(direction: Vector2) -> void:
	var anim := "idle"
	if direction != Vector2.ZERO:
		anim = "walk"
		if absf(direction.x) > absf(direction.y):
			_facing = "east" if direction.x > 0 else "west"
		else:
			_facing = "south" if direction.y > 0 else "north"
		facing_vector = FACING_VEC[_facing]
	_set_anim(anim, _facing)
	_update_flashlight()

func _update_flashlight() -> void:
	var on := GameState.linterna_on and GameState.light_battery > 0
	_light_rig.visible = on
	if on:
		# Nace en la mano y apunta hacia donde mirás (+x local = mirada).
		_light_rig.position = HAND_OFFSET.get(_facing, Vector2(0, -10))
		_light_rig.rotation = facing_vector.angle()
		# Mirando hacia arriba, la linterna va detrás del personaje.
		_light_rig.z_index = -1 if facing_vector.y < -0.5 else 1

func _set_anim(anim: String, dir: String) -> void:
	var key := anim + "_" + dir
	if key == _cur_anim:
		return
	_cur_anim = key
	if sprite:
		sprite.play(key)

func _reflect_body() -> void:
	if not sprite:
		return
	var redness := clampf(GameState.bleeding * 0.12, 0.0, 0.5)
	var blueness := clampf(GameState.cold * 0.004, 0.0, 0.35)
	var sickly := clampf(GameState.infection * 0.004, 0.0, 0.3)
	sprite.modulate = Color(
		1.0 - blueness - sickly * 0.3,
		1.0 - redness - blueness * 0.3,
		1.0 - redness - sickly)

func _update_atmosphere(delta: float) -> void:
	# Buscar enemigos cercanos para la tensión.
	var enemies := get_tree().get_nodes_in_group("enemies")
	GameState.update_atmosphere(global_position, enemies, delta)

func _spawn_blood_trail() -> void:
	if GameState.bleeding <= 0:
		return
	var drop := ColorRect.new()
	drop.size = Vector2(randf_range(2.0, 5.0), randf_range(2.0, 5.0))
	drop.color = Color(0.35, 0.02, 0.02, randf_range(0.4, 0.7))
	drop.position = global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)) - drop.size * 0.5
	drop.z_index = -1
	var parent := get_parent()
	if parent != null:
		parent.add_child(drop)
		var tw: Tween = create_tween()
		tw.tween_interval(randf_range(8.0, 16.0))
		tw.tween_method(func(a: float): drop.modulate.a = a, drop.modulate.a, 0.0, 2.0)
		await tw.finished
		if is_instance_valid(drop):
			drop.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("roll_dice"):
		var n := Dice.roll(20)
		var comment := "Un tiro normal."
		if n == 20:
			comment = "¡Crítico! La suerte está de tu lado."
		elif n == 1:
			comment = "Pifia. Mal presagio..."
		Dialogue.say("Tirás el dado...\n\n[ d20 ]   =   %d\n%s" % [n, comment])
