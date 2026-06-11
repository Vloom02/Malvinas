extends TileMapLayer
## Pinta el piso de la sala con el tileset de trinchera al arrancar.
## Usa set_cell directo (pone un tile concreto en cada celda): es simple y
## seguro. Más adelante podés pintar barro/charcos a mano con la herramienta
## de terreno (Rect / R) encima de esto.

## Tamaño del piso en celdas (cada celda = 32px). 20x12 cubre ~640x384.
@export var cols: int = 20
@export var rows: int = 12

## El tile "todo roca" está en la posición (0,3) del atlas. Fuente 0.
const ROCK_TILE := Vector2i(0, 3)
const SOURCE_ID := 0

func _ready() -> void:
	for x in cols:
		for y in rows:
			set_cell(Vector2i(x, y), SOURCE_ID, ROCK_TILE)
