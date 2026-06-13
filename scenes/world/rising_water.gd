extends Node2D
## Agua que sube en el barco que se hunde (teatro Naval). El nivel del agua
## sube con el tiempo; cuando te tapa, te congela y te ahogás (frío + daño).
## Hay que llegar a la salida (arriba) antes de que el agua te alcance.

## Píxeles por segundo que sube el agua.
@export var rise_speed: float = 5.0
## Nivel inicial del agua (Y en el mundo; 360 = piso, abajo).
@export var start_level: float = 360.0
## Hasta dónde sube como máximo (Y más chico = más arriba).
@export var top_level: float = 70.0

@onready var water: ColorRect = $Water

var _level: float
var _tick: float = 0.0

func _ready() -> void:
	_level = start_level
	water.offset_top = _level

func _process(delta: float) -> void:
	_level = maxf(top_level, _level - rise_speed * delta)
	water.offset_top = _level

	var p := get_tree().get_first_node_in_group("player")
	if p != null and p.global_position.y > _level + 6.0:
		# Estás bajo el agua: te congela y te ahogás.
		_tick += delta
		while _tick >= 1.0:
			_tick -= 1.0
			GameState.cold = clampi(GameState.cold + 6, 0, 100)
			GameState.damage_player(2)
			GameState.body_changed.emit()
