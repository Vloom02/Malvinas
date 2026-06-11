extends Node
## Singleton (autoload) con el estado global de la partida.
## Acá vive lo que tiene que persistir entre escenas: stats del jugador,
## hambre, cordura, inventario, flags de progreso, etc.
##
## Registrado como autoload "GameState" en project.godot, así cualquier
## script lo accede con GameState.algo sin tener que pasarlo por referencia.

# --- Señales: otros sistemas (UI, audio) se "suscriben" a estos cambios ---
signal hunger_changed(value: int)
signal sanity_changed(value: int)
signal player_died

# --- Recursos de supervivencia (estilo Fear & Hunger) ---
const HUNGER_MAX := 100
const SANITY_MAX := 100

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

## Hambre que baja al caminar/explorar. Llamalo desde el sistema de movimiento.
func spend_step() -> void:
	hunger -= 1

## Reinicia el estado para una nueva partida.
func new_game() -> void:
	hunger = HUNGER_MAX
	sanity = SANITY_MAX
