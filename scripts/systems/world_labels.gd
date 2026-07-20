extends Node
## Carteles flotantes del mundo ("Fogón", "[E]", nombres de cosas).
## Autoload: engancha automáticamente cualquier Label que cuelgue de un
## Node2D (los de UI cuelgan de Controls/CanvasLayers y se ignoran).
## Efecto: invisible de lejos, aparece con fade al acercarse y flota
## suavemente arriba/abajo. Fuente Creepster para diferenciarlo de la UI.

## Distancia (px) a la que el cartel está 100% visible. Corta: los nombres
## aparecen recién cuando te acercás en serio, igual que el [E].
const RADIO := 34.0
## Banda de fundido: entre RADIO y RADIO+FADE pasa de visible a invisible.
const FADE := 20.0
## Amplitud y velocidad de la flotación.
const BOB_AMP := 3.0
const BOB_SPEED := 3.2

const FONT := preload("res://assets/fonts/Creepster-Regular.ttf")

## Label -> { base_y, phase } (posición local original + desfase del vaivén
## para que no floten todos sincronizados como un coro).
var _labels := {}
var _t := 0.0

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(n: Node) -> void:
	# Los carteles de enemigos ("¡!" / "¿?") son feedback de alerta: tienen
	# que verse de lejos, no entran en el fade por cercanía.
	if n is Label and _es_del_mundo(n) and not n.get_parent().is_in_group("enemies"):
		_registrar(n as Label)

## Un Label es "del mundo" si algún ancestro es Node2D. La UI vive en
## Controls/CanvasLayers puros, así que nunca matchea.
func _es_del_mundo(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is Node2D:
			return true
		p = p.get_parent()
	return false

func _registrar(l: Label) -> void:
	if _labels.has(l):
		return
	_labels[l] = { "base_y": l.position.y, "phase": randf() * TAU }
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03))
	l.add_theme_constant_override("outline_size", 3)
	# Arranca invisible: nada de flashazo el primer frame.
	l.modulate.a = 0.0
	l.tree_exiting.connect(func() -> void: _labels.erase(l))

func _process(delta: float) -> void:
	if _labels.is_empty():
		return
	_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	for l: Label in _labels:
		if not is_instance_valid(l) or not l.visible:
			continue
		var objetivo := 0.0
		if player != null:
			# Distancia medida desde el objeto dueño, no desde la esquina del texto.
			var origen: Vector2 = (l.get_parent() as Node2D).global_position \
				if l.get_parent() is Node2D else l.global_position
			var d := origen.distance_to(player.global_position)
			objetivo = clampf(1.0 - (d - RADIO) / FADE, 0.0, 1.0)
		l.modulate.a = move_toward(l.modulate.a, objetivo, delta * 5.0)
		var datos: Dictionary = _labels[l]
		l.position.y = datos.base_y + sin(_t * BOB_SPEED + datos.phase) * BOB_AMP
