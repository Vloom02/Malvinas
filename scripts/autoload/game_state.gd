extends Node
## Singleton (autoload) con el estado global de la partida.
## Vive entre escenas: stats del jugador, hambre, cordura, vida, y el
## "puente" para entrar/salir de combate (que es otra escena).

# --- Señales: otros sistemas (UI, combate) se suscriben a estos cambios ---
signal hunger_changed(value: int)
signal sanity_changed(value: int)
signal player_hp_changed(value: int)
signal player_died
signal sanity_depleted

# --- Topes de los recursos ---
const HUNGER_MAX := 100
const SANITY_MAX := 100
const PLAYER_HP_MAX := 100

# --- Stats simples del jugador ---
var player_attack: int = 18

# --- Estado de combate (qué enemigo pelear y a dónde volver después) ---
var pending_enemy_path: String = ""
var return_scene_path: String = "res://scenes/maps/test_room.tscn"

# Evita que la locura se dispare en bucle mientras la cordura está en 0.
var _madness_triggered: bool = false

# --- Recursos con setter: al cambiar, avisan por señal y chequean límites ---
var hunger: int = HUNGER_MAX:
	set(value):
		hunger = clampi(value, 0, HUNGER_MAX)
		hunger_changed.emit(hunger)
		if hunger <= 0:
			player_died.emit()

var sanity: int = SANITY_MAX:
	set(value):
		sanity = clampi(value, 0, SANITY_MAX)
		sanity_changed.emit(sanity)
		if sanity <= 0 and not _madness_triggered:
			_madness_triggered = true
			sanity_depleted.emit()
			_trigger_madness()
		elif sanity > 0:
			_madness_triggered = false

var player_hp: int = PLAYER_HP_MAX:
	set(value):
		player_hp = clampi(value, 0, PLAYER_HP_MAX)
		player_hp_changed.emit(player_hp)
		if player_hp <= 0:
			player_died.emit()

# --- Acciones que llaman otros scripts ---

## Hambre que baja al caminar.
func spend_step() -> void:
	hunger -= 1

## Baja la cordura (la usa el altar maldito, sustos, oscuridad, etc.).
func drain_sanity(amount: int) -> void:
	sanity -= amount

## Daño al jugador (lo usa el combate).
func damage_player(amount: int) -> void:
	player_hp -= amount

## Reinicia todo para una partida nueva.
func new_game() -> void:
	_madness_triggered = false
	hunger = HUNGER_MAX
	sanity = SANITY_MAX
	player_hp = PLAYER_HP_MAX

# --- Puente de combate (combate es otra escena: scenes/combat/combat.tscn) ---

## Inicia un combate contra el enemigo de `enemy_path`, guardando a dónde volver.
func start_combat(enemy_path: String, from_scene: String) -> void:
	pending_enemy_path = enemy_path
	return_scene_path = from_scene
	_change_scene("res://scenes/combat/combat.tscn")

## Vuelve al mundo después de ganar un combate.
func end_combat() -> void:
	_change_scene(return_scene_path)

## Game over: reinicia la partida y vuelve a la sala.
func game_over() -> void:
	new_game()
	_change_scene("res://scenes/maps/test_room.tscn")

## Cuando la cordura toca 0: pesadilla forzada.
func _trigger_madness() -> void:
	pending_enemy_path = "res://data/enemies/madness.tres"
	return_scene_path = "res://scenes/maps/test_room.tscn"
	_change_scene("res://scenes/combat/combat.tscn")

## Tras sobrevivir a la pesadilla, recuperás algo de cordura.
func recover_from_madness() -> void:
	sanity = int(SANITY_MAX / 2.0)

## Cambia de escena de forma diferida (seguro de llamar desde señales/input).
func _change_scene(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)
