extends CharacterBody2D
## El jugador (conscripto argentino). Carga sus animaciones de PixelLab desde
## assets/sprites/conscripto/animations en 8 direcciones. El cuerpo refleja el
## estado (sangre/frío/infección) y usa animaciones de herido si está lastimado.

@export var speed: float = 82.0

const STEP_DISTANCE: float = 64.0
## Offset base del sprite: los pies del conscripto ~fila 59/80 → -20 los apoya en el origen.
const SPRITE_OFFSET := Vector2(0, -20)
const ANIM_ROOT := "res://assets/sprites/conscripto/animations"
## Las 8 direcciones que exporta PixelLab.
const DIRS8 := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
## Config por animación: [fps, loop]. Los frames se cargan de
## <ANIM_ROOT>/<anim>/<dir>/<n>.png (n desde 0).
const ANIMS := {
	"idle": [4.0, true],
	"walk": [10.0, true],
	"run": [13.0, true],
	"crouch": [5.0, true],
	"crouchwalk": [9.0, true],
	"aim": [12.0, true],
	"crouch_aim": [12.0, true],
	"prone": [4.0, true],
	"prone_aim": [12.0, true],
	"wounded_idle": [4.0, true],
	"wounded_walk": [7.0, true],
	"healing": [8.0, false],
	"death": [10.0, false],
	"dead": [1.0, false],
}

var _distance_walked: float = 0.0
var _facing: String = "south"
## Dirección (en mundo/pantalla, y hacia abajo) hacia la que mira el jugador.
## La lee darkness.gd para apuntar el haz de la linterna.
var facing_vector: Vector2 = Vector2.DOWN
const FACING_VEC := {
	"south": Vector2(0, 1), "north": Vector2(0, -1),
	"east": Vector2(1, 0), "west": Vector2(-1, 0),
	"south-east": Vector2(0.7071, 0.7071), "south-west": Vector2(-0.7071, 0.7071),
	"north-east": Vector2(0.7071, -0.7071), "north-west": Vector2(-0.7071, -0.7071),
}
## Posición de la mano que sostiene la linterna, por dirección (en local del
## jugador). De ahí nace el haz.
const HAND_OFFSET := {
	"south": Vector2(10, -5), "north": Vector2(-10, -7),
	"east": Vector2(12, -6), "west": Vector2(-12, -6),
	"south-east": Vector2(11, -5), "south-west": Vector2(-11, -5),
	"north-east": Vector2(8, -7), "north-west": Vector2(-8, -7),
}
var _cur_anim: String = ""
var sprite: AnimatedSprite2D
## "Rig" de la linterna: un Node2D que rota para apuntar a donde mirás. Adentro
## tiene la linterna dibujada y el cono de luz, que salen siempre hacia adelante.
var _light_rig: Node2D

## --- Disparo ---
var _shoot_cd: float = 0.0       ## cooldown entre disparos
var _aim_t: float = 0.0          ## segundos sosteniendo el apuntado (afina la puntería)
var _was_aiming: bool = false    ## para limpiar la barrita al soltar el apuntado
## Destrabar el arma: mantener R este tiempo, con círculo de progreso.
const UNJAM_TIME := 1.5
var _unjam_t: float = 0.0
var _last_tug: int = -1
## Marca post-intento: 1 = tilde (destrabada), 2 = cruz negra (soltaste antes).
var _unjam_mark: int = 0
var _mark_t: float = 0.0
var _was_jammed: bool = false
## Capa de dibujo del feedback (círculo/tilde/cruz/TRABADO): va ARRIBA del
## sprite (el _draw del propio player queda tapado por el hijo AnimatedSprite2D).
var _overlay: Node2D
## Altura (y local) de la boca del caño: el fusil va horneado al pecho, así que el
## fogonazo nace acá arriba (no a la altura de la mano). Subir/bajar para calibrar.
const MUZZLE_HEIGHT := -22.0

## --- Postura (agacharse / apuntar / correr / tirarse al suelo) ---
var _crouching: bool = false  ## agachado (tecla C mantenida): perfil bajo, más lento
var _aiming: bool = false     ## apuntando (click derecho mantenido): más lento y preciso
var _running: bool = false    ## corriendo (Shift mantenido): más rápido
var _prone: bool = false      ## tirado en el suelo (Z, solo con arma): no te movés, habilita trípode
var _last_posture: int = 0    ## 0 parado / 1 agachado / 2 tirado, para animar la transición

func _ready() -> void:
	$Camera2D.zoom = Vector2(GameState.camera_zoom, GameState.camera_zoom)
	sprite = AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.0, 1.0)
	sprite.offset = SPRITE_OFFSET
	sprite.sprite_frames = _frames_for(_equipped_weapon_id())
	add_child(sprite)
	_set_anim("idle", "south")
	_build_flashlight()
	_overlay = Node2D.new()
	_overlay.z_index = 10
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	GameState.weapon_changed.connect(_on_weapon_changed)
	# Precalentar el cache de animaciones: construir los SpriteFrames de las
	# armas que ya tenés cuesta cargar cientos de PNGs; mejor pagarlo al entrar
	# al mapa (una vez, cache estático) y no como tirón al equipar en pleno juego.
	GameState.inventory_changed.connect(_warm_frames_cache, CONNECT_DEFERRED)
	call_deferred("_warm_frames_cache")

## Construye (si faltan) los SpriteFrames de todas las armas del inventario.
## _frames_for cachea por arte, así que las repetidas salen gratis.
func _warm_frames_cache() -> void:
	for item in GameState.inventory.keys():
		if item is WeaponData and item.is_firearm():
			_frames_for(item.id)

## Al equipar/desequipar un arma, cambia el set de animaciones del conscripto
## por el del arma correspondiente (que la sostiene). Fallback: sin arma.
func _on_weapon_changed() -> void:
	if sprite == null:
		return
	# Si te quedás sin arma, no podés seguir tirado apuntando: te "levantás".
	if GameState.equipped_weapon == null:
		_prone = false
	sprite.sprite_frames = _frames_for(_equipped_weapon_id())
	_cur_anim = ""  # forzar re-play con el nuevo set
	_set_anim("idle" if velocity == Vector2.ZERO else "walk", _facing)

## Construye la linterna y su haz como dibujo vectorial (sin depender de un PNG).
## Todo apunta a +x local; el rig se rota según la dirección en _update_flashlight.
func _build_flashlight() -> void:
	_light_rig = Node2D.new()
	_light_rig.position = HAND_OFFSET["south"]
	_light_rig.z_index = 1
	_light_rig.visible = false
	add_child(_light_rig)

	# Cono de luz (haz): triángulo que se desvanece hacia afuera.
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([
		Vector2(12, -2), Vector2(74, -26), Vector2(82, 0), Vector2(74, 26), Vector2(12, 2)])
	beam.vertex_colors = PackedColorArray([
		Color(1.0, 0.95, 0.6, 0.55), Color(1.0, 0.95, 0.6, 0.0),
		Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.95, 0.6, 0.0),
		Color(1.0, 0.95, 0.6, 0.55)])
	_light_rig.add_child(beam)

	# Cuerpo de la linterna (mango gris).
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(8, -3), Vector2(11, -2), Vector2(11, 2), Vector2(8, 3), Vector2(0, 2)])
	body.color = Color(0.16, 0.16, 0.19)
	_light_rig.add_child(body)

	# Lente brillante en la punta.
	var lens := Polygon2D.new()
	lens.polygon = PackedVector2Array([
		Vector2(11, -3), Vector2(13, -2), Vector2(13, 2), Vector2(11, 3)])
	lens.color = Color(1.0, 0.95, 0.7)
	_light_rig.add_child(lens)

## Raíz de las animaciones del conscripto SOSTENIENDO un arma (por arma).
## Estructura: <WEAPON_ANIM_ROOT>/<weapon_id>/<anim>/<dir>/<n>.png
const WEAPON_ANIM_ROOT := "res://assets/sprites/conscripto/weapons"
## Animaciones que tienen variante "con arma" (el resto usa las sin arma: herido,
## curándose, muerte, tirado — ahí el conscripto baja/suelta el arma).
const ARMED_ANIMS := ["idle", "walk", "run", "crouch", "crouchwalk", "aim", "crouch_aim", "prone", "prone_aim"]
## Poses estáticas: se muestran con UN solo cuadro (frame 0), sin animar. Apuntar
## (parado/agachado/tirado), agachado, tirado y muerto son poses fijas (nada de
## piernas moviéndose). Se ignoran los cuadros extra aunque el arte los tenga.
const STATIC_ANIMS := ["aim", "crouch_aim", "crouch", "prone", "prone_aim", "dead"]

## Armas que comparten el arte de otra (misma familia visual): FAP ≈ FAL.
const WEAPON_ART_ALIAS := {"fap": "fal"}

## Mejoras VISIBLES en el arma → sufijo de carpeta de arte de la variante
## (weapons/<arma>_<sufijo>/). Prioridad si hay varias montadas: mira > correa > trípode.
const ACC_ART_SUFFIX := {"optic": "mira", "sling": "correa", "tripod": "tripode"}

## Cache de SpriteFrames por arte ("" = sin arma; incluye variante por mejora).
static var _frames_cache: Dictionary = {}

## Carpeta de arte variante según la mejora visible montada ("" si ninguna).
func _art_variant(weapon_id: String) -> String:
	if weapon_id == "" or GameState.equipped_weapon == null:
		return ""
	var st: Dictionary = GameState.equipped_weapon_state()
	if st.is_empty():
		return ""
	var accs: Dictionary = st["accessories"]
	for slot in ["optic", "sling", "tripod"]:
		if accs.has(slot):
			return weapon_id + "_" + ACC_ART_SUFFIX[slot]
	return ""

## SpriteFrames para el arma dada (o "" sin arma). Para las animaciones de
## movimiento usa el arte con arma si existe; si no (o para heridas/muerte),
## cae a las animaciones base del conscripto. Con una mejora visible montada
## prueba primero la variante (fal_mira, escopeta_correa, ...) y cae al arte
## del arma pelada donde a la variante le falte una anim/dir. Cachea por arte.
func _frames_for(weapon_id: String) -> SpriteFrames:
	weapon_id = WEAPON_ART_ALIAS.get(weapon_id, weapon_id)
	var variant_id := _art_variant(weapon_id)
	var cache_key := variant_id if variant_id != "" else weapon_id
	if _frames_cache.has(cache_key):
		return _frames_cache[cache_key]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in ANIMS.keys():
		var fps: float = ANIMS[anim][0]
		var loop: bool = ANIMS[anim][1]
		for dir: String in DIRS8:
			var key := anim + "_" + dir
			sf.add_animation(key)
			sf.set_animation_loop(key, loop)
			sf.set_animation_speed(key, fps)
			# Raíz: variante con mejora > arma pelada > conscripto base.
			var root := ANIM_ROOT
			if weapon_id != "" and anim in ARMED_ANIMS:
				if variant_id != "" and ResourceLoader.exists("%s/%s/%s/%s/0.png" % [WEAPON_ANIM_ROOT, variant_id, anim, dir]):
					root = "%s/%s" % [WEAPON_ANIM_ROOT, variant_id]
				elif ResourceLoader.exists("%s/%s/%s/%s/0.png" % [WEAPON_ANIM_ROOT, weapon_id, anim, dir]):
					root = "%s/%s" % [WEAPON_ANIM_ROOT, weapon_id]
			var i := 0
			while true:
				var p := "%s/%s/%s/%d.png" % [root, anim, dir, i]
				if not ResourceLoader.exists(p):
					break
				sf.add_frame(key, load(p))
				# Poses estáticas: un solo cuadro (fijo, sin animar).
				if anim in STATIC_ANIMS:
					break
				i += 1
	_frames_cache[cache_key] = sf
	return sf

## Id del arma equipada ("" si ninguna).
func _equipped_weapon_id() -> String:
	return GameState.equipped_weapon.id if GameState.equipped_weapon else ""

## True si vas con perfil bajo (agachado o cuerpo a tierra): las líneas de
## fuego estáticas (nido de MAG, francotirador) no te enganchan.
func is_low_profile() -> bool:
	return _crouching or _prone

func _physics_process(delta: float) -> void:
	if _shoot_cd > 0.0:
		_shoot_cd -= delta
	# Disparo SOSTENIDO: mantener apretado (click izquierdo o F) dispara a la
	# cadencia del arma. Polling (no evento): así ningún Control de la UI se
	# come el click. _fire() ya corta por cooldown/movimiento/apoyo/traba.
	if Input.is_action_pressed("shoot"):
		_fire()
	# Destrabar el arma: MANTENER R llena el círculo de progreso; el conscripto
	# manotea el cerrojo (tirón) mientras tanto. Soltar R reinicia.
	if GameState.weapon_jammed() and Input.is_action_pressed("reload"):
		_unjam_t += delta
		var tug := int(_unjam_t / 0.35)
		if tug != _last_tug:
			_last_tug = tug
			_unjam_tug()
		if _unjam_t >= UNJAM_TIME:
			GameState.set_weapon_jammed(false)
			_unjam_t = 0.0
			_last_tug = -1
			_unjam_mark = 1  # tilde: salió
			_mark_t = 0.6
			AudioManager.play_sfx("res://assets/audio/disparo.wav", -14.0)  # cerrojo: destrabada
			GameState.hacer_ruido(global_position, 90.0)  # el metal se escucha
		_overlay.queue_redraw()
	elif _unjam_t != 0.0:
		# Soltaste R antes de terminar: cruz negra, el cartucho sigue trabado.
		_unjam_t = 0.0
		_last_tug = -1
		_unjam_mark = 2
		_mark_t = 0.6
		_overlay.queue_redraw()
	# Marca post-intento (tilde/cruz): se desvanece sola.
	if _mark_t > 0.0:
		_mark_t -= delta
		_overlay.queue_redraw()
	# El cartelito TRABADO aparece/desaparece con el estado del arma.
	var jam_now := GameState.weapon_jammed()
	if jam_now != _was_jammed:
		_was_jammed = jam_now
		_overlay.queue_redraw()
	# Postura: agacharse/apuntar/correr se mantienen apretadas; tirarse es toggle.
	_crouching = Input.is_action_pressed("crouch")
	_aiming = Input.is_action_pressed("aim")
	# La puntería se afina sosteniendo el apuntado (bonus de daño en _shoot_hit).
	_aim_t = _aim_t + delta if _aiming else 0.0
	if _aiming or _was_aiming:
		_was_aiming = _aiming
		_overlay.queue_redraw()
	_running = Input.is_action_pressed("run")
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Tirado o apuntando: te quedás quieto (solo mirás/disparás). Apuntar exige estar
	# parado, así la pose de tiro es fija y no se ven las piernas caminando.
	if _prone or _aiming:
		direction = Vector2.ZERO

	var spd := speed
	if _crouching:
		spd *= 0.67  # ~55 px/s: agachado queda igual que antes
	elif _running:
		spd *= 1.45  # correr más lento que antes
	match GameState.broken_legs():
		1: spd *= 0.65
		2: spd *= 0.35
	# Pie de trinchera: hasta -30% de velocidad con los pies destruidos.
	spd *= 1.0 - 0.3 * (GameState.trench_foot / 100.0)
	velocity = direction * spd
	move_and_slide()

	_update_animation(direction)
	_reflect_body()
	_update_atmosphere(delta)

	if direction != Vector2.ZERO:
		_distance_walked += velocity.length() * delta
		while _distance_walked >= STEP_DISTANCE:
			_distance_walked -= STEP_DISTANCE
			GameState.spend_step()
			_spawn_blood_trail()

func _update_animation(direction: Vector2) -> void:
	var moving := direction != Vector2.ZERO
	if _aiming:
		# Apuntando: quieto, con la mira siguiendo al mouse (pose fija por dirección).
		var aim_vec := get_global_mouse_position() - global_position
		if aim_vec.length() > 2.0:
			_facing = _dir8(aim_vec)
			facing_vector = FACING_VEC[_facing]
	elif moving:
		_facing = _dir8(direction)
		facing_vector = FACING_VEC[_facing]
	# El cuerpo refleja el estado: si estás herido, usás las animaciones de herido.
	var wounded := GameState.bleeding > 0 or GameState.broken_legs() > 0
	# Prioridad de postura: tirado > apuntando (quieto) > herido > agachado > normal.
	var anim: String
	if _prone:
		anim = "prone_aim" if _aiming else "prone"
	elif _aiming:
		anim = "crouch_aim" if _crouching else "aim"  # apuntado fijo (parado o agachado)
	elif wounded:
		anim = "wounded_walk" if moving else "wounded_idle"
	elif _crouching:
		anim = "crouchwalk" if moving else "crouch"
	elif moving and _running:
		anim = "run"
	else:
		anim = "walk" if moving else "idle"
	# Transición de postura (parado/agachado/tirado): un "pique" corto del cuerpo,
	# sin arte nuevo, para que el cambio no sea un salto seco entre poses fijas.
	var posture := 2 if _prone else (1 if _crouching else 0)
	if posture != _last_posture:
		_last_posture = posture
		_animate_posture_change()
	_set_anim(anim, _facing)
	_update_flashlight()

## Simula agacharse/tumbarse (y viceversa): el sprite baja un toque y vuelve.
func _animate_posture_change() -> void:
	if sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(sprite, "offset", SPRITE_OFFSET + Vector2(0, 3), 0.07)
	tw.tween_property(sprite, "offset", SPRITE_OFFSET, 0.10)

## Convierte un vector de movimiento a una de las 8 direcciones nombradas.
func _dir8(v: Vector2) -> String:
	var idx := int(round(rad_to_deg(v.angle()) / 45.0)) % 8
	if idx < 0:
		idx += 8
	return DIRS8[idx]

func _update_flashlight() -> void:
	var on := GameState.linterna_on and GameState.light_battery > 0
	_light_rig.visible = on
	if on:
		# Nace en la mano y apunta hacia donde mirás (+x local = mirada).
		_light_rig.position = HAND_OFFSET.get(_facing, Vector2(0, -10))
		_light_rig.rotation = facing_vector.angle()
		# Mirando hacia arriba, la linterna va detrás del personaje.
		_light_rig.z_index = -1 if facing_vector.y < -0.5 else 1

## Fallback si una animación no tiene frames (arte faltante): aim→idle,
## prono→crouch, crouch→idle, etc. Evita mostrar el sprite en blanco.
const ANIM_FALLBACK := {
	"crouch_aim": "aim", "aim": "idle", "prone_aim": "prone", "prone": "crouch",
	"crouch": "idle", "crouchwalk": "walk", "run": "walk",
	"wounded_idle": "idle", "wounded_walk": "walk",
}

func _set_anim(anim: String, dir: String) -> void:
	# Si la animación pedida no tiene cuadros, caer a una que sí (encadena).
	if sprite != null and sprite.sprite_frames != null:
		var guard := 0
		while sprite.sprite_frames.get_frame_count(anim + "_" + dir) == 0 and ANIM_FALLBACK.has(anim) and guard < 5:
			anim = ANIM_FALLBACK[anim]
			guard += 1
	var key := anim + "_" + dir
	if key == _cur_anim:
		return
	_cur_anim = key
	if sprite:
		sprite.play(key)

func _reflect_body() -> void:
	if not sprite:
		return
	var redness := clampf(GameState.bleeding * 0.12, 0.0, 0.5)
	var blueness := clampf(GameState.cold * 0.004, 0.0, 0.35)
	var sickly := clampf(GameState.infection * 0.004, 0.0, 0.3)
	sprite.modulate = Color(
		1.0 - blueness - sickly * 0.3,
		1.0 - redness - blueness * 0.3,
		1.0 - redness - sickly)

func _update_atmosphere(delta: float) -> void:
	# Buscar enemigos cercanos para la tensión.
	var enemies := get_tree().get_nodes_in_group("enemies")
	GameState.update_atmosphere(global_position, enemies, delta)

func _spawn_blood_trail() -> void:
	if GameState.bleeding <= 0:
		return
	var drop := ColorRect.new()
	drop.size = Vector2(randf_range(2.0, 5.0), randf_range(2.0, 5.0))
	drop.color = Color(0.35, 0.02, 0.02, randf_range(0.4, 0.7))
	drop.position = global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)) - drop.size * 0.5
	drop.z_index = -1
	var parent := get_parent()
	if parent != null:
		parent.add_child(drop)
		var tw: Tween = create_tween()
		tw.tween_interval(randf_range(8.0, 16.0))
		tw.tween_method(func(a: float): drop.modulate.a = a, drop.modulate.a, 0.0, 2.0)
		await tw.finished
		if is_instance_valid(drop):
			drop.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("roll_dice"):
		var n := Dice.roll(20)
		var comment := "Un tiro normal."
		if n == 20:
			comment = "¡Crítico! La suerte está de tu lado."
		elif n == 1:
			comment = "Pifia. Mal presagio..."
		Dialogue.say("Tirás el dado...\n\n[ d20 ]   =   %d\n%s" % [n, comment])
	elif event.is_action_pressed("prone"):
		_toggle_prone()
	elif event.is_action_pressed("reload"):
		_reload()
	elif event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F10:
		_cheat_arsenal()

## Cheat de pruebas (F10): todas las armas de fuego + munición al inventario.
func _cheat_arsenal() -> void:
	for wid in ["fal", "fap", "fmk3", "browning_hp", "escopeta", "fn_mag"]:
		GameState.inventory[GameState.items_by_id[wid]] = 1
	GameState.add_item(GameState.items_by_id["cargador_762"], 2)
	GameState.add_item(GameState.items_by_id["cargador_9mm"], 2)
	GameState.add_item(GameState.items_by_id["cinta_762"], 1)
	GameState.add_item(GameState.items_by_id["cartuchos_12"], 12)
	GameState.add_item(GameState.items_by_id["balas_762"], 40)
	GameState.add_item(GameState.items_by_id["balas_9mm"], 26)
	GameState.inventory_changed.emit()
	Dialogue.say("[CHEAT] Arsenal completo y munición en el inventario.\nEquipá desde el menú (I).")

## Recarga (R): mete un cargador/cinta lleno o cartuchos al arma.
## Si el arma está TRABADA, R no recarga: mantenerla apretada la destraba
## (eso lo maneja _physics_process con el círculo de progreso).
func _reload() -> void:
	var w: WeaponData = GameState.equipped_weapon
	if w == null or not w.is_firearm():
		return
	if GameState.weapon_jammed():
		return
	var msg := GameState.reload_weapon()
	if msg != "":
		Dialogue.say(msg)
	else:
		AudioManager.play_sfx("res://assets/audio/disparo.wav", -24.0)  # "clac" de recarga

## Tirarse al suelo / levantarse. Solo con un arma equipada. Tirado no te movés,
## pero podés disparar las armas que necesitan apoyo (MAG con trípode).
func _toggle_prone() -> void:
	if GameState.equipped_weapon == null:
		Dialogue.say("Necesitás un arma para tirarte al suelo.")
		return
	_prone = not _prone
	# Tirarte al suelo revuelca el arma en el terreno: barro/humedad de golpe
	# (mucho más que un paso caminando). En terreno seco no pasa nada.
	if _prone and (GameState.env_mud_rate > 0 or GameState.env_wet_rate > 0):
		GameState.add_weapon_grime(GameState.env_mud_rate * 8, GameState.env_wet_rate * 8)
		var grime := GameState.weapon_grime_state()
		if grime != "":
			Dialogue.say("El arma se revuelca en el %s." % ("barro" if grime == "barro" else "suelo mojado"))

## Dispara el arma de fuego equipada (tecla F). Fogonazo + retroceso + impacto.
func _fire() -> void:
	if get_tree().paused:
		return
	var w: WeaponData = GameState.equipped_weapon
	if w == null or not w.is_firearm():
		return
	if _shoot_cd > 0.0:
		return
	# Solo se dispara QUIETO (parado, apuntando o tumbado), nunca caminando.
	if velocity != Vector2.ZERO:
		return
	# Las armas con trípode (MAG) no se disparan de pie: hay que estar tirado.
	if GameState.weapon_needs_mount() and not _prone:
		_shoot_cd = 0.3
		# Solo avisar en el apriete inicial (con fuego sostenido se repetiría en loop).
		if Input.is_action_just_pressed("shoot"):
			Dialogue.say("La %s necesita que te tires al suelo (Z) para dispararla." % w.display_name)
		return
	# Trabada: no dispara hasta destrabarla (mantener R).
	if GameState.weapon_jammed():
		if Input.is_action_just_pressed("shoot"):
			AudioManager.play_sfx("res://assets/audio/disparo.wav", -20.0)
			Dialogue.say("Está trabada. Mantené R para destrabarla.")
		return
	# Sin balas: click seco, no dispara. R para recargar.
	if GameState.weapon_ammo() <= 0:
		if Input.is_action_just_pressed("shoot"):
			AudioManager.play_sfx("res://assets/audio/disparo.wav", -20.0)
			Dialogue.say("CLICK. La %s está vacía. (R para recargar)" % w.display_name)
		return
	_shoot_cd = w.fire_cooldown  # cadencia propia de cada arma
	GameState.spend_bullet()

	# El barro/humedad/frío pueden trabar el arma (encasquillamiento). Queda
	# TRABADA hasta destrabarla manteniendo R (o limpiarla).
	if GameState.roll_weapon_jam():
		GameState.set_weapon_jammed(true)
		AudioManager.play_sfx("res://assets/audio/disparo.wav", -18.0)  # "click" seco, bajo
		GameState.hacer_ruido(global_position, 70.0)  # hasta la traba te delata
		var reason := "barro" if GameState.weapon_grime_state() == "barro" else "el frío"
		Dialogue.say("¡Se trabó! (%s). Mantené R para destrabarla." % reason)
		return

	# Punta del caño: a la altura del PECHO (donde está horneado el fusil), no de la
	# mano de la linterna. MUZZLE_HEIGHT sube el fogonazo hasta el caño; ajustable.
	var muzzle: Vector2 = Vector2(0, MUZZLE_HEIGHT) + facing_vector * 20.0
	_spawn_muzzle_flash(muzzle)
	_weapon_recoil()
	_camera_shake(2.0)
	AudioManager.play_sfx("res://assets/audio/disparo.wav", -4.0)
	# El estampido se escucha lejos: las patrullas vienen a investigar.
	GameState.hacer_ruido(global_position, 220.0)
	_shoot_hit()

const MUZZLE_FLASH_TEX := "res://assets/sprites/vfx/muzzle_flash.png"
## Las ametralladoras y la escopeta escupen un estallido radial más violento.
const MUZZLE_SPARKS_TEX := "res://assets/sprites/vfx/muzzle_flash_sparks.png"

## Fogonazo: sprite pixel-art rotado hacia donde mirás (si el arte se importó),
## si no cae al destello vectorial. Siempre suelta un puf de humo.
func _spawn_muzzle_flash(at: Vector2) -> void:
	var tex := MUZZLE_FLASH_TEX
	var w: WeaponData = GameState.equipped_weapon
	if w != null and w.weapon_type in ["ametralladora", "escopeta"] and ResourceLoader.exists(MUZZLE_SPARKS_TEX):
		tex = MUZZLE_SPARKS_TEX
	if ResourceLoader.exists(tex):
		var fx := Sprite2D.new()
		fx.texture = load(tex)
		fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fx.position = at
		fx.rotation = facing_vector.angle()
		fx.offset = Vector2(fx.texture.get_width() * 0.5, 0)  # nace en la boca, sale hacia afuera
		fx.z_index = 3
		fx.scale = Vector2(0.7, 0.7)
		add_child(fx)
		var tw2 := create_tween()
		tw2.tween_property(fx, "scale", Vector2(1.15, 1.05), 0.04)
		tw2.parallel().tween_property(fx, "modulate:a", 0.0, 0.11)
		tw2.tween_callback(fx.queue_free)
	else:
		_spawn_muzzle_flash_poly(at)
	_spawn_smoke_puff(at)

## Destello vectorial (fallback si el sprite no está importado todavía).
func _spawn_muzzle_flash_poly(at: Vector2) -> void:
	var flash := Polygon2D.new()
	flash.position = at
	flash.z_index = 2
	flash.polygon = PackedVector2Array([
		Vector2(0, -9), Vector2(3, -3), Vector2(11, 0), Vector2(3, 3),
		Vector2(0, 9), Vector2(-3, 3), Vector2(-11, 0), Vector2(-3, -3)])
	flash.color = Color(1.0, 0.92, 0.5)
	add_child(flash)
	# Núcleo blanco brillante en el centro.
	var core := Polygon2D.new()
	core.position = at
	core.z_index = 3
	core.polygon = PackedVector2Array([Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)])
	core.color = Color(1, 1, 0.95)
	add_child(core)
	var tw := create_tween()
	tw.tween_property(flash, "scale", Vector2(1.9, 1.9), 0.05)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.14)
	tw.parallel().tween_property(core, "modulate:a", 0.0, 0.08)
	tw.tween_callback(flash.queue_free)
	tw.tween_callback(core.queue_free)

## Puf de humo gris que sale de la boca del caño y se disipa al frente.
func _spawn_smoke_puff(at: Vector2) -> void:
	var puff := Polygon2D.new()
	puff.position = at + facing_vector * 4.0
	puff.z_index = 1
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 4.0)
	puff.polygon = pts
	puff.color = Color(0.6, 0.6, 0.62, 0.5)
	add_child(puff)
	var tw := create_tween()
	tw.tween_property(puff, "scale", Vector2(2.4, 2.4), 0.35)
	tw.parallel().tween_property(puff, "position", puff.position + facing_vector * 8.0, 0.35)
	tw.parallel().tween_property(puff, "modulate:a", 0.0, 0.35)
	tw.tween_callback(puff.queue_free)

## Temblón corto de cámara (retroceso del disparo).
func _camera_shake(amount: float) -> void:
	var cam: Camera2D = $Camera2D
	if cam == null:
		return
	# Siempre volvemos a cero (reposo), NO al offset actual: si dos temblones se
	# solapan no se acumula desvío de cámara.
	var tw := create_tween()
	for i in 3:
		tw.tween_property(cam, "offset",
			Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)

## Tirón de cerrojo al destrabar: sacudida corta del sprite (el arma va horneada,
## así que se mueve todo el personaje — se lee como manipular el arma).
func _unjam_tug() -> void:
	if sprite == null:
		return
	var tw := create_tween()
	tw.tween_property(sprite, "offset", SPRITE_OFFSET + Vector2(2, -1), 0.06)
	tw.tween_property(sprite, "offset", SPRITE_OFFSET, 0.14)

## Feedback del arma trabada: círculo de progreso chiquito arriba del arma,
## cartelito TRABADO abajo del arma, y tilde/cruz al terminar el intento.
## Dibuja en _overlay (z arriba del sprite) para que no lo tape el cuerpo.
func _draw_overlay() -> void:
	var font := ThemeDB.fallback_font
	if GameState.weapon_jammed():
		_overlay.draw_string(font, Vector2(-24, 12), "TRABADO",
			HORIZONTAL_ALIGNMENT_CENTER, 48, 8, Color(0.9, 0.25, 0.15))
	# Barrita de puntería: se llena en 2 s sosteniendo el apuntado (click der.);
	# llena = verde = +50% de daño en el próximo disparo.
	if _aim_t > 0.0 and GameState.equipped_weapon != null and GameState.equipped_weapon.is_firearm():
		var q := minf(_aim_t / 2.0, 1.0)
		_overlay.draw_rect(Rect2(Vector2(-8, -33), Vector2(16, 3)), Color(0, 0, 0, 0.5))
		_overlay.draw_rect(Rect2(Vector2(-8, -33), Vector2(16.0 * q, 3)),
			Color(0.3, 0.9, 0.35) if q >= 1.0 else Color(0.9, 0.9, 0.85))
	var c := Vector2(0, -27)  # justo arriba del arma (va al pecho, y=-22)
	if _mark_t > 0.0:
		if _unjam_mark == 1:
			# Tilde verde: destrabada.
			_overlay.draw_line(c + Vector2(-4, 0), c + Vector2(-1, 3), Color(0.3, 0.9, 0.35), 2.0)
			_overlay.draw_line(c + Vector2(-1, 3), c + Vector2(4, -4), Color(0.3, 0.9, 0.35), 2.0)
		else:
			# Cruz negra chiquita: el intento quedó a medias.
			_overlay.draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), Color(0.05, 0.05, 0.05), 2.0)
			_overlay.draw_line(c + Vector2(3, -3), c + Vector2(-3, 3), Color(0.05, 0.05, 0.05), 2.0)
		return
	if _unjam_t <= 0.0:
		return
	var p := clampf(_unjam_t / UNJAM_TIME, 0.0, 1.0)
	_overlay.draw_arc(c, 5.0, -PI / 2, -PI / 2 + TAU, 20, Color(0, 0, 0, 0.55), 2.5)
	_overlay.draw_arc(c, 5.0, -PI / 2, -PI / 2 + TAU * p, 20, Color(1.0, 0.85, 0.3), 1.5)

## Retroceso: el conscripto "patea" hacia atrás un instante (el arma está horneada
## en el sprite, así que se mueve todo el personaje).
func _weapon_recoil() -> void:
	if sprite == null:
		return
	var base_off := SPRITE_OFFSET
	var kicked := base_off - facing_vector * 2.0
	var tw := create_tween()
	tw.tween_property(sprite, "offset", kicked, 0.04)
	tw.tween_property(sprite, "offset", base_off, 0.10)

## Busca el enemigo más cercano AL FRENTE dentro del alcance y lo hiere.
func _shoot_hit() -> void:
	var range_px := 200.0
	var best: Node2D = null
	var best_d := range_px
	# "blancos" son los de práctica del tutorial: reciben tiros sin dar combate.
	for e in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("blancos"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var to_e: Vector2 = (e as Node2D).global_position - global_position
		var d := to_e.length()
		if d > range_px or d < 0.01:
			continue
		if to_e.normalized().dot(facing_vector) < 0.5:  # debe estar hacia adelante
			continue
		if d < best_d:
			best_d = d
			best = e
	if best != null and best.has_method("hit_from_world"):
		# Daño según distancia: completo dentro del alcance efectivo del arma,
		# decae lineal hasta el 40% en el alcance máximo (la escopeta pega de
		# cerca; el FAL/MAG mantienen el daño lejos).
		var w: WeaponData = GameState.equipped_weapon
		var eff: float = w.effective_range if w != null else 120.0
		var mult := 1.0
		if best_d > eff and range_px > eff:
			mult = clampf(1.0 - (best_d - eff) / (range_px - eff) * 0.6, 0.4, 1.0)
		# Puntería afinada: sostener el apuntado (click der.) hasta 2 s da +50%.
		mult *= 1.0 + minf(_aim_t, 2.0) * 0.25
		var dmg := maxi(1, int(GameState.get_player_damage(true) * mult))
		best.hit_from_world(dmg, 2)
