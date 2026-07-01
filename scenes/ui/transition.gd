extends CanvasLayer
## Transición entre salas con fundido a negro. Autoload global "Transition".
## Cualquier puerta llama  Transition.change("res://...sala.tscn", "NombreSpawn").

@onready var rect: ColorRect = $Rect

func _ready() -> void:
	rect.color.a = 0.0

func change(scene_path: String, spawn_name: String) -> void:
	GameState.next_spawn = spawn_name
	# Funde a negro...
	var t := create_tween()
	t.tween_property(rect, "color:a", 1.0, 0.3)
	await t.finished
	# ...cambia de sala...
	print("[Transition] Cambiando a: ", scene_path, " spawn=", spawn_name)
	var err := get_tree().change_scene_to_file(scene_path)
	print("[Transition] change_scene_to_file resultado: ", err)
	await get_tree().process_frame
	# ...y vuelve de negro.
	var t2 := create_tween()
	t2.tween_property(rect, "color:a", 0.0, 0.3)
