extends CanvasLayer
## Redirecciona la tecla I al menú principal (game_menu).
## Este script se mantiene por compatibilidad con autoloads que lo referencien.

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		# Abrir game_menu en vez de este inventario viejo.
		var existing := get_tree().root.find_child("GameMenu", true, false)
		if existing != null and existing.visible:
			existing._close()
		else:
			var game_menu := preload("res://scenes/ui/game_menu.tscn").instantiate()
			get_tree().root.add_child(game_menu)
			game_menu._open()
		get_viewport().set_input_as_handled()
