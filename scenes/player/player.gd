extends CharacterBody2D
## El jugador (conscripto). Se mueve en 8 direcciones con WASD o las flechas,
## pero el sprite mira en 4 (arriba/abajo/izquierda/derecha), estilo RPG clásico.
## Caminar le baja el hambre.

## Velocidad en píxeles por segundo. Editable desde el Inspector.
@export var speed: float = 110.0

## Cada cuántos píxeles caminados se gasta un "paso" de hambre.
const STEP_DISTANCE: float = 64.0

var _distance_walked: float = 0.0
## Última dirección hacia la que miró (para quedarse quieto mirando ahí).
var _facing: String = "south"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * speed
	move_and_slide()

	_update_animation(direction)

	# Hambre al caminar.
	if direction != Vector2.ZERO:
		_distance_walked += velocity.length() * delta
		while _distance_walked >= STEP_DISTANCE:
			_distance_walked -= STEP_DISTANCE
			GameState.spend_step()

## Elige qué animación mostrar según el movimiento.
func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		# Quieto: pose de descanso mirando a la última dirección.
		sprite.play("idle_" + _facing)
		return

	# En movimiento: el eje más fuerte decide hacia dónde mira el sprite.
	if absf(direction.x) > absf(direction.y):
		_facing = "east" if direction.x > 0 else "west"
	else:
		_facing = "south" if direction.y > 0 else "north"

	sprite.play("walk_" + _facing)
