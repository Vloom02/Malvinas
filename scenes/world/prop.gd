extends StaticBody2D
## Prop SÓLIDO con colisión: rocas, parapetos, restos que te frenan (cobertura).
## Reutilizable: le asignás una textura y el tamaño de colisión por instancia.

## Imagen del prop.
@export var texture: Texture2D
## Tamaño del rectángulo de colisión (suele cubrir solo la base del prop).
@export var collision_size: Vector2 = Vector2(48, 22)
## Desplazamiento de la colisión (ej: bajarla a la base con y positivo).
@export var collision_offset: Vector2 = Vector2(0, 10)

func _ready() -> void:
	if texture != null:
		$Sprite2D.texture = texture
	var shape := RectangleShape2D.new()
	shape.size = collision_size
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = collision_offset
