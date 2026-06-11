extends Node2D
class_name Enemy
## Lógica de un enemigo en combate. La DATA viene de un EnemyData (.tres);
## este script solo maneja el ESTADO en runtime (HP actual por parte, etc.).
##
## Patrón modular: una sola escena enemy.tscn sirve para TODOS los enemigos.
## Lo único que cambia es qué EnemyData se le asigna. Así no hay una escena
## por enemigo que mantener.

signal part_destroyed(part_name: String)
signal died

@export var data: EnemyData

## HP vivo de cada parte, copiado de data al iniciar (no tocamos el recurso).
var _parts_hp: Dictionary = {}

func _ready() -> void:
	if data == null:
		push_warning("Enemy sin EnemyData asignado.")
		return
	_parts_hp = data.body_parts.duplicate()

## Recibe daño en una parte concreta. Devuelve true si la parte quedó destruida.
func take_damage(part_name: String, amount: int) -> bool:
	if not _parts_hp.has(part_name):
		return false
	_parts_hp[part_name] = maxi(0, _parts_hp[part_name] - amount)
	if _parts_hp[part_name] == 0:
		part_destroyed.emit(part_name)
		_check_death()
		return true
	return false

## Muere si la cabeza o el torso llegan a 0 (ajustá esta regla a gusto).
func _check_death() -> void:
	if _parts_hp.get("cabeza", 1) == 0 or _parts_hp.get("torso", 1) == 0:
		died.emit()
