extends CanvasLayer
## HUD: el cartelito fijo en pantalla que muestra hambre y cordura.
##
## CanvasLayer hace que esto se dibuje SIEMPRE encima del juego y quieto en
## pantalla (no se mueve con la cámara). Se "suscribe" a las señales de
## GameState, así se actualiza solo cada vez que esos valores cambian.

@onready var label: Label = $Label

func _ready() -> void:
	GameState.hunger_changed.connect(_refresh)
	GameState.sanity_changed.connect(_refresh)
	_refresh()

func _refresh(_value: int = 0) -> void:
	label.text = "Hambre: %d/%d    Cordura: %d/%d" % [
		GameState.hunger, GameState.HUNGER_MAX,
		GameState.sanity, GameState.SANITY_MAX,
	]
