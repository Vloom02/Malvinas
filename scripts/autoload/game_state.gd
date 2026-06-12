extends Node
## Singleton (autoload) con el estado global de la partida.
## Vive entre escenas. SIN HUD: estos valores se reflejan en pantalla/cuerpo
## de forma diegética (ver scenes/ui/darkness.gd), no en barras.

# --- Señales (las usan los efectos diegéticos y el combate) ---
signal hunger_changed(value: int)
signal sanity_changed(value: int)
signal player_hp_changed(value: int)
signal body_changed          # sangrado/frío/infección cambió
signal player_died
signal sanity_depleted

# --- Topes ---
const HUNGER_MAX := 100
const SANITY_MAX := 100
const PLAYER_HP_MAX := 100

# --- Stats del jugador ---
var player_attack: int = 18

# --- Estado de combate (a qué enemigo pelear y a dónde volver) ---
var pending_enemy_path: String = ""
var return_scene_path: String = "res://scenes/maps/test_room.tscn"
var _madness_triggered: bool = false

# --- Cuerpo: heridas persistentes (pilar de diseño) ---
var bleeding: int = 0   # cantidad de heridas sangrando; drena vida con el tiempo
var cold: int = 0       # hipotermia (0-100), la sube el ambiente helado
var infection: int = 0  # infección (0-100) de heridas sin tratar

const BLEED_INTERVAL := 1.5   # cada cuántos segundos drena el sangrado
var _bleed_timer: float = 0.0

# --- Recursos con setter (avisan por señal y respetan límites) ---
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

# --- Tick del cuerpo: el sangrado drena vida con el tiempo ---
func _process(delta: float) -> void:
	if bleeding > 0 and player_hp > 0:
		_bleed_timer += delta
		while _bleed_timer >= BLEED_INTERVAL:
			_bleed_timer -= BLEED_INTERVAL
			player_hp -= bleeding   # cada herida sangrante = 1 de daño por tick

# --- Acciones ---

## Hambre/frío que baja al caminar.
func spend_step() -> void:
	hunger -= 1

## Baja la cordura (altar, sustos, oscuridad...).
func drain_sanity(amount: int) -> void:
	sanity -= amount

## Daño directo al jugador (combate).
func damage_player(amount: int) -> void:
	player_hp -= amount

## Agrega heridas sangrantes (lo usan los peligros tipo enredadera).
func apply_bleeding(stacks: int) -> void:
	bleeding = clampi(bleeding + stacks, 0, 10)
	body_changed.emit()

## Venda: corta TODO el sangrado (item de curación).
func bandage() -> void:
	bleeding = 0
	body_changed.emit()
	print("[Cuerpo] Te vendás. El sangrado se detiene.")

## Reinicia todo para una partida nueva.
func new_game() -> void:
	_madness_triggered = false
	bleeding = 0
	cold = 0
	infection = 0
	hunger = HUNGER_MAX
	sanity = SANITY_MAX
	player_hp = PLAYER_HP_MAX

# --- Puente de combate (combate es otra escena) ---

func start_combat(enemy_path: String, from_scene: String) -> void:
	pending_enemy_path = enemy_path
	return_scene_path = from_scene
	_change_scene("res://scenes/combat/combat.tscn")

func end_combat() -> void:
	_change_scene(return_scene_path)

func game_over() -> void:
	new_game()
	_change_scene("res://scenes/maps/test_room.tscn")

func _trigger_madness() -> void:
	pending_enemy_path = "res://data/enemies/madness.tres"
	return_scene_path = "res://scenes/maps/test_room.tscn"
	_change_scene("res://scenes/combat/combat.tscn")

func recover_from_madness() -> void:
	sanity = int(SANITY_MAX / 2.0)

func _change_scene(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)
