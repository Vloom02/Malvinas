@tool
extends Resource
class_name ItemData
## Datos de un item (data pura, como EnemyData). Cada item es un .tres en
## data/items/. El "effect" decide qué hace al usarlo (lo resuelve GameState).

@export var id: String = "item"
@export var display_name: String = "Item"
@export var description: String = ""
## Qué hace al usarse: "bandage" (frena sangrado), "ration" (sube hambre), etc.
@export var effect: String = ""
## Cantidad asociada al efecto (ej: cuánto restaura una ración).
@export var amount: int = 0
