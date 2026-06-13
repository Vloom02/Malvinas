extends Control
## Pantalla de muerte. Podés volver a tu último reporte (guardado) o al título.

@onready var continue_btn: Button = $Center/VBox/Continuar

func _ready() -> void:
	continue_btn.disabled = not GameState.has_save()
	continue_btn.pressed.connect(_on_continue)
	$Center/VBox/Menu.pressed.connect(_on_menu)

func _on_continue() -> void:
	# Vuelve al último reporte. Si no hay, al título.
	if not GameState.load_game():
		_on_menu()

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/title.tscn")
