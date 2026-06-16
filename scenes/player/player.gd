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
var _cur_anim: String = ""
var sprite: AnimatedSprite2D

func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.offset = Vector2(0, -20)   # pies sobre el piso
	sprite.sprite_frames = _build_frames()
	add_child(sprite)
	_set_anim("idle", "south")

## Construye un SpriteFrames con walk_/idle_ por dirección desde los PNG LPC.
func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var walk_tex: Texture2D = load(SHEETS + "/walk.png")
	var idle_tex: Texture2D = load(SHEETS + "/idle.png")
	for dir in DIR_ROW.keys():
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

	if direction != Vector2.ZERO:
		_distance_walked += velocity.length() * delta
		while _distance_walked >= STEP_DISTANCE:
			_distance_walked -= STEP_DISTANCE
			GameState.spend_step()

func _update_animation(direction: Vector2) -> void:
	var anim := "idle"
	if direction != Vector2.ZERO:
		anim = "walk"
		if absf(direction.x) > absf(direction.y):
			_facing = "east" if direction.x > 0 else "west"
		else:
			_facing = "south" if direction.y > 0 else "north"
	_set_anim(anim, _facing)

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("roll_dice"):
		var n := Dice.roll(20)
		var comment := "Un tiro normal."
		if n == 20:
			comment = "¡Crítico! La suerte está de tu lado."
		elif n == 1:
			comment = "Pifia. Mal presagio..."
		Dialogue.say("Tirás el dado...\n\n[ d20 ]   =   %d\n%s" % [n, comment])
