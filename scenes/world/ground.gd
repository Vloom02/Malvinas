extends TileMapLayer
## Pinta el piso de la sala con el tileset de trinchera al arrancar.
## Usa el sistema de "terrain" de Godot: rellena un rectángulo de celdas con
## el terreno rocoso. Más adelante podés pintar barro/charcos a mano con la
## herramienta Rect (R) en el editor, encima de esto.

## Tamaño del piso en celdas (cada celda = 32px). 20x12 cubre ~640x384.
@export var cols: int = 20
@export var rows: int = 12

func _ready() -> void:
	var cells: Array[Vector2i] = []
	for x in cols:
		for y in rows:
			cells.append(Vector2i(x, y))
	# terrain_set 0, terrain 1 = "Roca" (suelo rocoso de Malvinas).
	set_cells_terrain_connect(cells, 0, 1)
