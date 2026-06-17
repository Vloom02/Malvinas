extends CanvasLayer
## HUD sutil del companion en el mundo. Muestra el nombre y barra de vida
## del companion cuando está activo. Se actualiza cada frame.

@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/NameLabel
@onready var hp_bar: ProgressBar = $Panel/HPBar

func _ready() -> void:
	panel.visible = false
	GameState.companion_changed.connect(_on_companion_changed)

func _on_companion_changed() -> void:
	panel.visible = GameState.companion != null
	if GameState.companion != null:
		name_label.text = GameState.companion.display_name
		hp_bar.max_value = GameState.companion_hp_max
		hp_bar.value = GameState.companion_hp

func _process(_delta: float) -> void:
	if GameState.companion == null:
		return
	hp_bar.value = GameState.companion_hp
	# Cambiar color según HP.
	if GameState.companion_hp_max <= 0:
		hp_bar.modulate = Color(0.9, 0.2, 0.2)
		return
	var ratio := float(GameState.companion_hp) / float(GameState.companion_hp_max)
	if ratio > 0.6:
		hp_bar.modulate = Color(0.3, 0.8, 0.3)
	elif ratio > 0.3:
		hp_bar.modulate = Color(0.9, 0.8, 0.2)
	else:
		hp_bar.modulate = Color(0.9, 0.2, 0.2)
