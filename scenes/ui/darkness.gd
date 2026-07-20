extends CanvasLayer
## Oscuridad DIEGÉTICA (reemplaza al HUD). La pantalla refleja el estado del
## jugador sin barras ni números:
##  - Cordura baja  → la oscuridad se cierra (círculo más chico, claustrofóbico).
##  - Sangrado / vida baja → una viñeta ROJA que late en los bordes.
##  - Cordura crítica → alucinaciones visuales/auditivas.
## Lee el estado de GameState en cada frame y ajusta los shaders.

@onready var dark: ColorRect = $Vignette
@onready var blood: ColorRect = $Blood
@onready var hallu_flash: ColorRect = $HalluFlash

var _audio: AudioStreamPlayer

func _ready() -> void:
	GameState.hallucination.connect(_on_hallucination)
	_audio = AudioStreamPlayer.new()
	add_child(_audio)

func _process(_delta: float) -> void:
	# --- Cordura + luz → tamaño del círculo visible ---
	var sanity_t := float(GameState.sanity) / float(GameState.SANITY_MAX)
	var light_t := float(GameState.effective_light()) / 100.0
	# Sin luz: el círculo se cierra aunque tengas cordura.
	var min_r := lerpf(0.15, 0.55, light_t)
	var max_r := lerpf(0.20, 0.70, sanity_t)
	var radius := minf(min_r, max_r)
	dark.material.set_shader_parameter("radius", radius)

	# --- Haz de linterna: proyecta un cono de luz hacia donde mirás ---
	if GameState.linterna_on and GameState.light_battery > 0:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and "facing_vector" in player:
			dark.material.set_shader_parameter("beam_dir", player.facing_vector)
		dark.material.set_shader_parameter("beam_len", 0.40)
	else:
		dark.material.set_shader_parameter("beam_len", 0.0)

	# --- Sangre/vida → viñeta roja con latido ---
	var hp_t := float(GameState.player_hp) / float(GameState.PLAYER_HP_MAX)
	var amount := clampf(float(GameState.bleeding) * 0.22 + (1.0 - hp_t) * 0.55, 0.0, 0.8)
	var pulse := 0.0
	if amount > 0.01:
		pulse = (sin(Time.get_ticks_msec() / 320.0) * 0.5 + 0.5) * 0.18
	blood.material.set_shader_parameter("darkness", clampf(amount + pulse, 0.0, 0.92))

func _on_hallucination(type: String) -> void:
	match type:
		"whisper":
			_hallu_whisper()
		"shadow":
			_hallu_shadow()
		"screen":
			_hallu_flash()

func _hallu_whisper() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	hallu_flash.color = Color(0.0, 0.0, 0.0, 0.08)
	tw.tween_property(hallu_flash, "color:a", 0.0, 0.6)
	_play_audio("res://assets/audio/whisper.wav", -20.0, randf_range(0.8, 1.2))

func _hallu_shadow() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	var c := Color(randf_range(0.0, 0.1), 0.0, 0.0, 0.0)
	hallu_flash.color = Color(c.r, c.g, c.b, 0.3)
	tw.tween_property(hallu_flash, "color:a", 0.0, randf_range(1.0, 2.0))

func _play_audio(path: String, vol: float, pitch: float) -> void:
	var s := load(path) as AudioStream
	if s == null:
		return
	_audio.stream = s
	_audio.volume_db = vol
	_audio.pitch_scale = pitch
	_audio.play()

func _hallu_flash() -> void:
	var tw := create_tween()
	var r := randf_range(0.6, 0.9)
	hallu_flash.color = Color(r, r * 0.5, r * 0.3, 0.6)
	tw.tween_property(hallu_flash, "color:a", 0.0, 0.4)
	_play_audio("res://assets/audio/flash_noise.wav", -10.0, randf_range(0.3, 0.8))
