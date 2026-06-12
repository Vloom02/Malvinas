extends CanvasLayer
## Oscuridad DIEGÉTICA (reemplaza al HUD). La pantalla refleja el estado del
## jugador sin barras ni números:
##  - Cordura baja  → la oscuridad se cierra (círculo más chico, claustrofóbico).
##  - Sangrado / vida baja → una viñeta ROJA que late en los bordes.
## Lee el estado de GameState en cada frame y ajusta los shaders.

@onready var dark: ColorRect = $Vignette
@onready var blood: ColorRect = $Blood

func _process(_delta: float) -> void:
	# --- Cordura → tamaño del círculo visible ---
	var sanity_t := float(GameState.sanity) / float(GameState.SANITY_MAX)
	# 100% cordura = 0.30 (abierto); 0% = 0.13 (casi a ciegas).
	var radius := lerpf(0.13, 0.30, sanity_t)
	dark.material.set_shader_parameter("radius", radius)

	# --- Sangre/vida → viñeta roja con latido ---
	var hp_t := float(GameState.player_hp) / float(GameState.PLAYER_HP_MAX)
	# Intensidad por sangrado activo + por vida baja.
	var amount := clampf(float(GameState.bleeding) * 0.22 + (1.0 - hp_t) * 0.55, 0.0, 0.8)
	var pulse := 0.0
	if amount > 0.01:
		# Latido tipo pulso cardíaco mientras estás herido.
		pulse = (sin(Time.get_ticks_msec() / 320.0) * 0.5 + 0.5) * 0.18
	blood.material.set_shader_parameter("darkness", clampf(amount + pulse, 0.0, 0.92))
