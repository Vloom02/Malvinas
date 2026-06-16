extends Node
## Gestor de audio central. Reproduce efectos y música.
## Tolerante a archivos faltantes: no rompe si un .ogg no existe.

var _music_player: AudioStreamPlayer
var _master_bus: int

func _ready() -> void:
	_master_bus = AudioServer.get_bus_index("Master")
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -6.0
	add_child(_music_player)

func play_sfx(path: String, volume: float = 0.0) -> void:
	var stream := _safe_load(path)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()

func play_music(path: String, volume: float = -6.0) -> void:
	var stream := _safe_load(path)
	if stream == null:
		return
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = volume
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func set_music_volume(db: float) -> void:
	_music_player.volume_db = db

func set_master_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(_master_bus, db)

func _safe_load(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream
