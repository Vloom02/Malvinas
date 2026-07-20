extends CanvasLayer
## Monitor de signos vitales estilo Resident Evil clásico: carcasa militar
## generada en PixelLab (elipse + alas laterales, croquis de Alan) y adentro un
## electro (ECG) cuyo ritmo real sale de GameState.get_bpm() y su color de
## GameState.vitals_state(). Verde = ESTABLE, amarillo = ALERTA, rojo = CRÍTICO.
## Si la textura no está importada todavía, cae al dibujo vectorial de antes.

const W := 132.0
const H := 56.0
const MARGIN := Vector2(8, 6)  # esquina inferior izquierda
const COLORS := {
	"fine": Color(0.35, 1.0, 0.5),
	"caution": Color(1.0, 0.85, 0.3),
	"danger": Color(1.0, 0.32, 0.22),
}
const LABELS := {"fine": "ESTABLE", "caution": "ALERTA", "danger": "CRITICO"}

## Carcasa del monitor (PixelLab) y rectángulo de su pantalla CRT dentro de la
## textura (medido con PIL sobre el PNG: flood-fill desde el centro).
const TEX_PATH := "res://assets/sprites/ui/monitor_vitales.png"
const TEX_SCREEN := Rect2(164, 40, 111, 85)

## Renders laterales de armas para el HUD (estilo The Punisher).
const WEAPON_RENDER_DIR := "res://assets/sprites/ui/armas/"
const RENDER_ALIAS := {"fap": "fal"}
var _weapon_tex_cache: Dictionary = {}

var _tex: Texture2D = null
var _trace_w: int = 66          ## muestras del trazo (ancho útil del electro)
var _samples: PackedFloat32Array
var _beat_phase := 0.0          ## fase del latido (0..1, un latido por ciclo)
var _mon: Control

func _ready() -> void:
	layer = 40  # abajo de diálogos/menús (que usan capas más altas)
	# Los diálogos PAUSAN el árbol: sin esto, _process no corre durante la
	# pausa y el monitor nunca llega a esconderse (quedaba dibujado encima).
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(TEX_PATH):
		_tex = load(TEX_PATH)
		# El trazo vive dentro de la pantalla CRT de la textura (escalada a W).
		var s := W / _tex.get_width()
		_trace_w = int(TEX_SCREEN.size.x * s) - 4
	_samples = PackedFloat32Array()
	_samples.resize(_trace_w)
	_mon = Control.new()
	_mon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mon.position = Vector2(MARGIN.x, get_viewport().get_visible_rect().size.y - H - MARGIN.y)
	_mon.size = Vector2(W, H)
	_mon.draw.connect(_draw_monitor)
	add_child(_mon)

func _process(delta: float) -> void:
	# El HUD se esconde en menús/finales Y ante cualquier pausa: diálogos,
	# menú del juego (I), menú de pausa — todos pausan el árbol.
	var playing := _in_gameplay() and not get_tree().paused and not Dialogue.visible
	_mon.visible = playing
	if not playing:
		return
	# Avanzar el electro: la velocidad del latido ES el pulso real del cuerpo.
	var bpm := GameState.get_bpm()
	_beat_phase += delta * (float(bpm) / 60.0)
	if _beat_phase >= 1.0:
		_beat_phase = fmod(_beat_phase, 1.0)
	# Desplazar el trazo 1 muestra por frame y meter la nueva al final.
	for i in _trace_w - 1:
		_samples[i] = _samples[i + 1]
	_samples[_trace_w - 1] = _ecg_wave(_beat_phase)
	_mon.queue_redraw()

## Forma del complejo PQRST de un ECG, simplificada a pixel art.
## p es la fase del latido (0..1). Devuelve el desvío vertical en px (+ = arriba).
func _ecg_wave(p: float) -> float:
	if p < 0.08:
		return 2.0 * sin(p / 0.08 * PI)          # onda P chica
	elif p < 0.14:
		return 0.0
	elif p < 0.17:
		return -3.0                               # Q
	elif p < 0.22:
		return 13.0                               # R (el pico grande)
	elif p < 0.26:
		return -5.0                               # S
	elif p < 0.45:
		return 0.0
	elif p < 0.58:
		return 3.5 * sin((p - 0.45) / 0.13 * PI)  # onda T
	return 0.0

func _draw_monitor() -> void:
	var state: String = GameState.vitals_state()
	var col: Color = COLORS[state]
	if _tex != null:
		_draw_textured(state, col)
	else:
		_draw_vector(state, col)

## Carcasa PixelLab + electro adentro de su pantalla CRT.
func _draw_textured(state: String, col: Color) -> void:
	var s := W / _tex.get_width()
	var dst := Rect2(Vector2.ZERO, Vector2(_tex.get_width(), _tex.get_height()) * s)
	_mon.draw_texture_rect(_tex, dst, false)
	var scr := Rect2(TEX_SCREEN.position * s, TEX_SCREEN.size * s)
	var cy := scr.position.y + scr.size.y * 0.55
	var x0 := scr.position.x + 2.0
	var amp := 0.75  # achicar el PQRST para que el pico R no se salga de la pantalla
	var pts := PackedVector2Array()
	for i in _trace_w:
		pts.append(Vector2(x0 + i, cy - _samples[i] * amp))
	_mon.draw_polyline(pts, col, 1.0)
	_mon.draw_circle(pts[_trace_w - 1], 1.2, Color(1, 1, 1, 0.9))
	# Estado en texto, chiquito ARRIBA del monitor (pedido de Alan).
	var font := ThemeDB.fallback_font
	_mon.draw_string(font, Vector2(W * 0.5 - 14, -2), LABELS[state],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, col)
	# Fecha y reloj del mundo, arriba a la izquierda ("n" = noche).
	var hh := int(GameState.time_hours)
	var mm := int((GameState.time_hours - hh) * 60.0)
	_mon.draw_string(font, Vector2(2, -2), "%d jun %02d:%02d%s" % [
		mini(GameState.day, GameState.CAMPAIGN_DAYS), hh, mm, "n" if GameState.is_night() else ""],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 0.72, 0.66))
	# Íconos de condición en las 4 esquinas del monitor.
	_draw_condition_icons(dst)
	# Render del arma equipada a la derecha del monitor (estilo The Punisher).
	_draw_weapon_render(dst, font)

## Íconos chicos que se prenden solo con la condición activa:
## gota (sangrado) ↖ · copo (frío) ↗ · huella (pie de trinchera) ↙ · cruz (infección) ↘
func _draw_condition_icons(dst: Rect2) -> void:
	if GameState.bleeding > 0:
		var c := Vector2(9, 10)
		var rc := Color(0.85, 0.15, 0.1)
		_mon.draw_circle(c + Vector2(0, 1.5), 2.6, rc)
		_mon.draw_polygon(PackedVector2Array([c + Vector2(-2.4, 1), c + Vector2(0, -4.5), c + Vector2(2.4, 1)]),
			PackedColorArray([rc]))
	if GameState.cold >= 40:
		var c2 := Vector2(dst.size.x - 10, 10)
		var cc := Color(0.5, 0.8, 1.0)
		_mon.draw_line(c2 + Vector2(-4, 0), c2 + Vector2(4, 0), cc, 1.2)
		_mon.draw_line(c2 + Vector2(-2, -3.5), c2 + Vector2(2, 3.5), cc, 1.2)
		_mon.draw_line(c2 + Vector2(2, -3.5), c2 + Vector2(-2, 3.5), cc, 1.2)
	if GameState.trench_foot >= 40:
		var c3 := Vector2(9, dst.size.y - 9)
		var fc := Color(1.0, 0.72, 0.25) if GameState.trench_foot < 80 else Color(1.0, 0.32, 0.22)
		_mon.draw_set_transform(c3, 0.0, Vector2(1.0, 1.5))
		_mon.draw_circle(Vector2.ZERO, 2.2, fc)
		_mon.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in 3:
			_mon.draw_circle(c3 + Vector2(-2.2 + i * 2.2, -6.0), 0.9, fc)
	if GameState.infection >= 30:
		var c4 := Vector2(dst.size.x - 10, dst.size.y - 9)
		var ic := Color(0.55, 0.85, 0.3)
		_mon.draw_rect(Rect2(c4 + Vector2(-1.2, -4), Vector2(2.4, 8)), ic)
		_mon.draw_rect(Rect2(c4 + Vector2(-4, -1.2), Vector2(8, 2.4)), ic)

## Render lateral del arma equipada (assets/sprites/ui/armas/<id>.png) con su
## munición chiquita abajo — como el HUD de The Punisher de PS2.
func _weapon_render_tex(id: String) -> Texture2D:
	id = RENDER_ALIAS.get(id, id)
	if _weapon_tex_cache.has(id):
		return _weapon_tex_cache[id]
	var p := WEAPON_RENDER_DIR + id + ".png"
	var tex: Texture2D = load(p) if ResourceLoader.exists(p) else null
	_weapon_tex_cache[id] = tex
	return tex

func _draw_weapon_render(dst: Rect2, font: Font) -> void:
	var w := GameState.equipped_weapon
	if w == null:
		return
	# Anclado a la esquina inferior DERECHA de la pantalla (estilo Punisher).
	var vw := _mon.get_viewport_rect().size.x
	var right := vw - _mon.position.x - 8.0
	var tex := _weapon_render_tex(w.id)
	if tex != null:
		var th := 20.0
		var tw := tex.get_width() * th / tex.get_height()
		_mon.draw_texture_rect(tex, Rect2(Vector2(right - tw, dst.size.y - th - 14.0), Vector2(tw, th)), false)
	var info: String
	var icol := Color(0.85, 0.88, 0.78)
	if w.is_firearm():
		info = "%d/%d  x%d" % [GameState.weapon_ammo(), w.mag_size, GameState.ammo_reserve_count()]
	else:
		var cond := int(GameState.equipped_weapon_state().get("condition", 100))
		info = "filo %d%%" % cond
		if cond <= 30:
			icol = Color(1.0, 0.85, 0.3)
	_mon.draw_string(font, Vector2(right - 90.0, dst.size.y - 2.0), info,
		HORIZONTAL_ALIGNMENT_RIGHT, 90, 7, icol)

## Dibujo vectorial original (fallback sin textura): elipse + líneas laterales.
func _draw_vector(state: String, col: Color) -> void:
	var dim := col.darkened(0.45)
	var cy := H * 0.5 - 4.0
	var cx := W * 0.5
	_mon.draw_set_transform(Vector2(cx, cy), 0.0, Vector2(1.0, 0.55))
	_mon.draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 48, col, 1.5)
	_mon.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_mon.draw_line(Vector2(14, cy - 5), Vector2(cx - 32, cy - 5), dim, 1.5)
	_mon.draw_line(Vector2(2, cy + 5), Vector2(cx - 33, cy + 5), dim, 1.5)
	_mon.draw_line(Vector2(cx + 32, cy - 5), Vector2(W - 6, cy - 5), dim, 1.5)
	_mon.draw_line(Vector2(cx + 33, cy + 5), Vector2(W - 2, cy + 5), dim, 1.5)
	var pts := PackedVector2Array()
	var x0 := cx - _trace_w * 0.5
	for i in _trace_w:
		pts.append(Vector2(x0 + i, cy - _samples[i]))
	_mon.draw_polyline(pts, col, 1.0)
	_mon.draw_circle(pts[_trace_w - 1], 1.5, Color(1, 1, 1, 0.9))
	var font := ThemeDB.fallback_font
	_mon.draw_string(font, Vector2(cx - 26, H + 2), LABELS[state],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)

## Mismo criterio que GameState._in_gameplay (privado): ni título ni game over.
func _in_gameplay() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var path := scene.scene_file_path
	return not (path.ends_with("title.tscn") or path.ends_with("game_over.tscn"))
