extends TileMapLayer
## Pinta el piso de la sala con el tileset de trinchera al arrancar.
## Usa set_cell directo (pone un tile concreto en cada celda): es simple y
## seguro. Más adelante podés pintar barro/charcos a mano con la herramienta
## de terreno (Rect / R) encima de esto.

## Tamaño del piso en celdas (cada celda = 32px). 20x12 cubre ~640x384.
@export var cols: int = 20
@export var rows: int = 12

## Tile de relleno (barro LPC), fuente 0 = dirt.png dentro de campo_batalla_tileset.
const DIRT_TILE := Vector2i(1, 2)
const SOURCE_ID := 0

func _ready() -> void:
	for x in cols:
		for y in rows:
			set_cell(Vector2i(x, y), SOURCE_ID, DIRT_TILE)