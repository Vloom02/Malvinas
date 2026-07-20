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
## Máscara de colisión para paredes (capas físicas que bloquean el chase).
@export var wall_mask: int = 1
## Si la cordura del jugador es MAYOR a este valor, el enemigo es invisible
## y no persigue (-1 = siempre visible).
@export var sanity_threshold: int = -1

var _triggered: bool = false
var _visible_to_sanity: bool = true
var _fading: bool = false
## Daño/sangrado acumulado por disparos en el mapa (antes del combate).
var _world_damage: int = 0
var _world_bleed: int = 0

## Lo llama el player al dispararle. Acumula daño y hace parpadear el sprite.
func hit_from_world(dmg: int, bleed: int = 0) -> void:
	_world_damage += dmg
	_world_bleed += bleed
	if is_instance_valid(get_node_or_null("Sprite2D")):
		$Sprite2D.modulate = Color(1.7, 0.5, 0.5, 1.0)
		var tw := create_tween()
		tw.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1), 0.25)
	AudioManager.play_sfx("res://assets/audio/hit.wav", -6.0)

func _ready() -> void:
	if unique_id != "" and GameState.has_flag("dead_" + unique_id):
		queue_free()
		return
	if not is_in_group("enemies"):
		add_to_group("enemies")
	if sprite_texture != null:
		$Sprite2D.texture = sprite_texture
	if label_text != "":
		$Label.text = label_text
	body_entered.connect(_on_body_entered)
	_update_sanity_visibility()

func _update_sanity_visibility() -> bool:
	if sanity_threshold < 0:
		_visible_to_sanity = true
	else:
		_visible_to_sanity = GameState.sanity <= sanity_threshold
	$CollisionShape2D.disabled = not _visible_to_sanity
	$Label.visible = _visible_to_sanity
	return _visible_to_sanity

func _process(_delta: float) -> void:
	if sanity_threshold < 0:
		return
	var was := _visible_to_sanity
	var now := _update_sanity_visibility()
	if was == now:
		return
	if not is_instance_valid($Sprite2D):
		return
	if now:
		visible = true
		var tw := create_tween()
		tw.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 1), 0.6).from(Color(1, 1, 1, 0))
	else:
		if _fading:
			return
		_fading = true
		var tw := create_tween()
		tw.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 0.4)
		await tw.finished
		_fading = false
		if is_instance_valid(self) and not _visible_to_sanity:
			visible = false

func _physics_process(delta: float) -> void:
	if _triggered or not _visible_to_sanity:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() >= chase_range:
		return

	# En la oscuridad los enemigos son más rápidos y te detectan antes.
	var dark_mult := 1.0 + (1.0 - float(GameState.effective_light()) / 100.0) * 0.8
	if to_player.length() < chase_range * dark_mult * 0.6:
		var dir := to_player.normalized()
		$RayCast2D.target_position = dir * 32.0
		$RayCast2D.force_raycast_update()
		if $RayCast2D.is_colliding():
			return
		global_position += dir * chase_speed * dark_mult * delta

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		if unique_id != "" and GameState.has_flag("dead_" + unique_id):
			queue_free()
			return
		_triggered = true
		_offer_stealth_or_combat()

func _offer_stealth_or_combat() -> void:
	# Si tiene sigilo, ofrecer la opción de esquivar.
	var stealth_mod := GameState.get_stealth_mod()
	var has_stealth := stealth_mod > 0
	if has_stealth:
		Dialogue.ask("Algo se mueve en la oscuridad...", ["Pelear", "Intentar pasar desapercibido (sigilo)"])
		var choice: int = await Dialogue.chosen
		if choice == 1:
			var all_enemies := get_tree().get_nodes_in_group("enemies")
			var nearby: Array = []
			for e in all_enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 200.0:
					nearby.append(e)
			var result := Stealth.try_stealth(nearby)
			Dialogue.say(result["text"])
			await Dialogue.finished
			if result["success"]:
				_triggered = false
				return
			# Si falla, cae al combate.
	_start_combat()

func _start_combat() -> void:
	GameState.pending_kill_id = unique_id
	# Pasar el daño de los disparos del mapa al combate.
	GameState.pending_pre_damage = _world_damage
	GameState.pending_enemy_bleed = _world_bleed
	var from_scene := get_tree().current_scene.scene_file_path
	GameState.start_combat(enemy_path, from_scene)
