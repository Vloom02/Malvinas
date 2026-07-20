extends StaticBody2D
## Blanco de práctica del tutorial de tiro: recibe los disparos del player
## (vía el grupo "blancos" + hit_from_world, igual que un enemigo) pero no da
## combate: cuenta impactos, tambalea y muestra el total.

## Impactos para darlo por completado (0 = infinito, solo cuenta).
@export var goal: int = 5
## Flag que setea al completarse (para gatear el fin del tutorial).
@export var done_flag: String = ""

var _hits: int = 0

func _ready() -> void:
	add_to_group("blancos")
	_update_label()

## Mismo contrato que EnemyEncounter.hit_from_world: lo llama el disparo del player.
func hit_from_world(_dmg: int, _bleed: int = 0) -> void:
	_hits += 1
	_update_label()
	AudioManager.play_sfx("res://assets/audio/hit.wav", -10.0)
	var tw := create_tween()
	tw.tween_property($Tabla, "rotation", 0.18, 0.06)
	tw.tween_property($Tabla, "rotation", -0.1, 0.08)
	tw.tween_property($Tabla, "rotation", 0.0, 0.1)
	if goal > 0 and _hits == goal:
		if done_flag != "":
			GameState.set_flag(done_flag)
		Dialogue.say("¡Blanco completado! (%d impactos)" % _hits)

func _update_label() -> void:
	$Cuenta.text = "impactos: %d" % _hits if goal <= 0 else "impactos: %d/%d" % [_hits, goal]
