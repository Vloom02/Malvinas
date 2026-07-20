extends Node
## La radio del conscripto (Silent Hill 2): crepita estática cuando hay
## enemigos cerca, más fuerte cuanto más cerca están. No distingue dirección
## ni si los ves — incluso "detecta" lo que la cordura te oculta. Autoload.

## Distancia a la que la radio empieza a crepitar.
const RANGO := 160.0
## Cada cuánto se escanea el grupo "enemies" (no hace falta por frame).
const CHECK_S := 0.25
## Volumen encima del enemigo / en el borde del rango.
const VOL_CERCA := -6.0
const VOL_LEJOS := -28.0

var _spk: AudioStreamPlayer
var _acc := 0.0

func _ready() -> void:
	_spk = AudioStreamPlayer.new()
	var s := load("res://assets/audio/estatica.wav") as AudioStreamWAV
	if s != null:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 2  # frames (16-bit mono)
		_spk.stream = s
	add_child(_spk)

func _process(delta: float) -> void:
	_acc += delta
	if _acc < CHECK_S:
		return
	_acc = 0.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or _spk.stream == null:
		if _spk.playing:
			_spk.stop()
		return
	var best := RANGO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and is_instance_valid(e):
			var d: float = (e as Node2D).global_position.distance_to(player.global_position)
			if d < best:
				best = d
	if best >= RANGO:
		if _spk.playing:
			_spk.stop()
		return
	_spk.volume_db = lerpf(VOL_CERCA, VOL_LEJOS, best / RANGO)
	if not _spk.playing:
		_spk.play()
