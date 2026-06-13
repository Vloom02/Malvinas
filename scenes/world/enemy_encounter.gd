extends Area2D
class_name EnemyEncounter
## Enemigo en el mundo. Cuando el jugador lo toca, arranca el combate contra
## el enemigo indicado en `enemy_path`. Al ganar, GameState te trae de vuelta.
##
## Reutilizable: poné varios en el mapa, cada uno con su .tres de enemigo.

## Ruta al recurso de datos del enemigo (un EnemyData .tres).
@export var enemy_path: String = "res://data/enemies/ghoul.tres"
## Velocidad a la que flota hacia el jugador (px/seg).
@export var chase_speed: float = 42.0
## A qué distancia te empieza a perseguir.
@export var chase_range: float = 150.0
## Id único para recordar que lo mataste (si lo dejás vacío, reaparece siempre).
@export var unique_id: String = ""
## Sprite a mostrar (si lo dejás vacío, usa el de la escena).
@export var sprite_texture: Texture2D
## Texto del cartel (si lo dejás vacío, usa el de la escena).
@export var label_text: String = ""

var _triggered: bool = false

func _ready() -> void:
	# Si ya lo mataste en esta partida, no reaparece.
	if unique_id != "" and GameState.has_flag("dead_" + unique_id):
		queue_free()
		return
	if sprite_texture != null:
		$Sprite2D.texture = sprite_texture
	if label_text != "":
		$Label.text = label_text
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _triggered:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# Flota hacia el jugador si está cerca (atraviesa todo, fantasmal).
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() < chase_range:
		global_position += to_player.normalized() * chase_speed * delta

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		GameState.pending_kill_id = unique_id
		var from_scene := get_tree().current_scene.scene_file_path
		GameState.start_combat(enemy_path, from_scene)
