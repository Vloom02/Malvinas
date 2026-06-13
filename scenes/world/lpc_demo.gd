extends Node2D
## Demo del personaje LPC. Crea un LPCAnimatedSprite2D (del addon), le apunta a
## la carpeta de spritesheets compuestos y lo hace caminar. Sirve para ver que
## todo el pipeline LPC (generar → componer → animar) funciona en el juego.

const SPRITES := "res://assets/sprites/lpc_soldado"

var _sprite: LPCAnimatedSprite2D
var _dirs := ["south", "west", "north", "east"]
var _i := 0

func _ready() -> void:
	_sprite = LPCAnimatedSprite2D.new()
	_sprite.position = Vector2(320, 180)
	_sprite.scale = Vector2(2, 2)
	add_child(_sprite)
	_sprite.spritesheets_path = SPRITES
	_sprite.play_animation("walk", _dirs[_i])

	# Cada 1.5s gira a la siguiente dirección (para mostrar las 4).
	var t := Timer.new()
	t.wait_time = 1.5
	t.autostart = true
	t.timeout.connect(_next_dir)
	add_child(t)

func _next_dir() -> void:
	_i = (_i + 1) % _dirs.size()
	_sprite.play_animation("walk", _dirs[_i])
