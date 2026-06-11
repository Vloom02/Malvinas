extends CharacterBody2D
## El jugador. Se mueve en 8 direcciones con WASD o las flechas.
## Caminar le baja el hambre (cada cierta distancia recorrida = 1 "paso").
##
## CharacterBody2D es el nodo de Godot pensado para personajes que se mueven
## y chocan con paredes. move_and_slide() hace que se deslice contra los muros
## en vez de trabarse.

## Velocidad en píxeles por segundo. Editable desde el Inspector.
@export var speed: float = 110.0

## Cada cuántos píxeles caminados se gasta un "paso" de hambre.
const STEP_DISTANCE: float = 64.0

var _distance_walked: float = 0.0

func _physics_process(delta: float) -> void:
	# Input.get_vector arma un vector de dirección a partir de las 4 acciones.
	# Ya queda normalizado, así que en diagonal no va más rápido.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * speed
	move_and_slide()

	# Hambre al caminar: acumulamos distancia y cada STEP_DISTANCE gastamos un paso.
	if direction != Vector2.ZERO:
		_distance_walked += velocity.length() * delta
		while _distance_walked >= STEP_DISTANCE:
			_distance_walked -= STEP_DISTANCE
			GameState.spend_step()
