extends CanvasLayer
## Transición entre salas. Autoload global "Transition".
## Salida: fundido a negro. Entrada: "melt" inverso estilo Doom — el mapa
## nuevo cae en columnas verticales hasta armarse (ver melt.gdshader).
## Cualquier puerta llama  Transition.change("res://...sala.tscn", "NombreSpawn").

@onready var rect: ColorRect = $Rect
@onready var melt: ColorRect = $Melt

func _ready() -> void:
	rect.color.a = 0.0
	melt.visible = false

func change(scene_path: String, spawn_name: String) -> void:
	GameState.next_spawn = spawn_name
	var mat := melt.material as ShaderMaterial
	# Salida: melt clásico Doom — la pantalla vieja se derrite hacia abajo.
	mat.set_shader_parameter("salida", true)
	mat.set_shader_parameter("progress", 0.0)
	melt.visible = true
	var t := create_tween()
	t.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.65)
	await t.finished
	rect.color.a = 1.0
	melt.visible = false
	# ...cambia de sala...
	print("[Transition] Cambiando a: ", scene_path, " spawn=", spawn_name)
	var err := get_tree().change_scene_to_file(scene_path)
	print("[Transition] change_scene_to_file resultado: ", err)
	# Dos frames para que el mapa nuevo ya esté dibujado detrás del shader.
	await get_tree().process_frame
	await get_tree().process_frame
	# ...y el mapa nuevo CAE en columnas hasta encajar (melt inverso).
	rect.color.a = 0.0
	mat.set_shader_parameter("salida", false)
	mat.set_shader_parameter("progress", 0.0)
	melt.visible = true
	var t2 := create_tween()
	t2.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.9)
	await t2.finished
	melt.visible = false
